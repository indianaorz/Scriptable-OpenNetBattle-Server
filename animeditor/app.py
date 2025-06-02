import os
import shlex
import json # For handling JSON payload from frontend
from flask import Flask, render_template, jsonify, send_from_directory, url_for, request

app = Flask(__name__)

# Configure the animations folder
ANIMATIONS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'animations_root')
app.config['ANIMATIONS_FOLDER'] = ANIMATIONS_DIR

def parse_animation_file(filepath):
    """
    Parses an .animation file and returns a dictionary with its data.
    """
    data = {"imagePath": None, "animations": {}, "errors": []}
    current_animation_state = None
    base_dir_for_image_path = os.path.dirname(os.path.relpath(filepath, app.config['ANIMATIONS_FOLDER']))

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            for line_number, line in enumerate(f, 1):
                line = line.strip()
                if not line or line.startswith('#'):
                    continue

                try:
                    if line.startswith('imagePath='):
                        image_path_raw = line.split('=', 1)[1].strip().strip('"')
                        if base_dir_for_image_path and base_dir_for_image_path != '.':
                             data['imagePath'] = os.path.join(base_dir_for_image_path, image_path_raw).replace('\\', '/')
                        else:
                             data['imagePath'] = image_path_raw.replace('\\', '/')
                    
                    elif line.startswith('animation state='):
                        parts_str = line[len('animation '):]
                        parsed_attrs = shlex.split(parts_str)
                        if parsed_attrs:
                            key_value_pair = parsed_attrs[0]
                            if key_value_pair.startswith("state="):
                                current_animation_state = key_value_pair.split("=", 1)[1]
                                data["animations"][current_animation_state] = []
                            else:
                                data["errors"].append(f"L{line_number}: Malformed animation state attribute: {line}")
                                current_animation_state = None
                        else:
                            data["errors"].append(f"L{line_number}: Malformed animation state line: {line}")
                            current_animation_state = None

                    elif line.startswith('frame ') and current_animation_state:
                        frame_attrs = {}
                        attr_line = line[len('frame '):]
                        attrs = shlex.split(attr_line)
                        
                        expected_keys = {"duration", "x", "y", "w", "h", "originx", "originy", "flipx"}
                        parsed_keys = set()

                        for attr in attrs:
                            if '=' not in attr:
                                data["errors"].append(f"L{line_number}: Malformed frame attribute '{attr}' in line: {line}")
                                continue
                            key, value = attr.split('=', 1)
                            frame_attrs[key] = value 
                            parsed_keys.add(key)
                        
                        if not all(k in parsed_keys for k in ["x", "y", "w", "h", "duration"]):
                             data["errors"].append(f"L{line_number}: Frame missing essential attributes (x,y,w,h,duration): {line}")
                             continue
                        
                        frame_attrs.setdefault('originx', '0')
                        frame_attrs.setdefault('originy', '0')
                        frame_attrs.setdefault('flipx', '0') # Default to 0, not "1"
                        
                        data["animations"][current_animation_state].append(frame_attrs)
                    elif line.startswith('frame ') and not current_animation_state:
                        data["errors"].append(f"L{line_number}: Frame defined before any animation state: {line}")
                except Exception as e:
                    data["errors"].append(f"L{line_number}: Error parsing line '{line}': {str(e)}")

    except FileNotFoundError:
        data["errors"].append(f"Animation file not found: {filepath}")
        return None
    except Exception as e:
        data["errors"].append(f"General error reading file {filepath}: {str(e)}")
        return None
        
    return data

def format_animation_data_to_string(data):
    """
    Formats the animation data dictionary back into the .animation file string format.
    """
    output_lines = []
    if data.get("imagePath"):
        output_lines.append(f'imagePath="{data["imagePath"]}"')
    
    if data.get("animations"):
        for state_name, frames in data["animations"].items():
            output_lines.append("") # Add a blank line before each animation state for readability
            output_lines.append(f'animation state="{state_name}"')
            for frame in frames:
                # Ensure all expected attributes are present, providing defaults if necessary
                # This is important if new frames are added with partial data from the frontend
                duration = frame.get("duration", "0.1")
                x = frame.get("x", "0")
                y = frame.get("y", "0")
                w = frame.get("w", "10")
                h = frame.get("h", "10")
                originx = frame.get("originx", "0")
                originy = frame.get("originy", "0")
                flipx = frame.get("flipx", "0") # Ensure flipx is a string '0' or '1'

                # Make sure flipx is '0' or '1'
                if isinstance(flipx, bool):
                    flipx_val = "1" if flipx else "0"
                elif str(flipx).lower() in ["true", "1"]:
                    flipx_val = "1"
                else:
                    flipx_val = "0"

                output_lines.append(
                    f'frame duration="{duration}" x="{x}" y="{y}" w="{w}" h="{h}" originx="{originx}" originy="{originy}" flipx="{flipx_val}"'
                )
    return "\n".join(output_lines)


@app.route('/')
def index():
    animation_files = []
    if not os.path.exists(app.config['ANIMATIONS_FOLDER']):
        try:
            os.makedirs(app.config['ANIMATIONS_FOLDER'])
        except OSError as e:
            print(f"Error creating animations directory {app.config['ANIMATIONS_FOLDER']}: {e}")
            return f"Error: Could not create or access animations directory: {app.config['ANIMATIONS_FOLDER']}. Please create it manually.", 500

    for root, _, files in os.walk(app.config['ANIMATIONS_FOLDER']):
        for file in files:
            if file.endswith(".animation"):
                relative_path = os.path.relpath(os.path.join(root, file), app.config['ANIMATIONS_FOLDER'])
                animation_files.append(relative_path.replace('\\', '/'))
    return render_template('index.html', animation_files=animation_files)

@app.route('/edit/<path:animation_filename>')
def editor(animation_filename):
    full_path = os.path.join(app.config['ANIMATIONS_FOLDER'], animation_filename)
    if not os.path.exists(full_path) or not os.path.isfile(full_path):
        return "Animation file not found", 404
    return render_template('editor.html', animation_filename=animation_filename)

@app.route('/api/animation/<path:animation_filename>')
def get_animation_data(animation_filename):
    full_path = os.path.join(app.config['ANIMATIONS_FOLDER'], animation_filename)
    if not os.path.exists(full_path):
        return jsonify({"error": "Animation file not found"}), 404
    
    data = parse_animation_file(full_path)
    if data is None or (data.get("imagePath") is None and not data.get("animations")):
        return jsonify({"error": "Failed to parse animation file", "details": data.get("errors", []) if data else ["Unknown parsing error"]}), 500
    
    return jsonify(data)

@app.route('/api/save_animation/<path:animation_filename>', methods=['POST'])
def save_animation_data(animation_filename):
    """
    API endpoint to save modified animation data.
    Expects JSON payload with the animation data.
    """
    full_path = os.path.join(app.config['ANIMATIONS_FOLDER'], animation_filename)
    
    # Basic security: ensure the path doesn't try to escape the ANIMATIONS_FOLDER
    # by resolving the absolute path and checking if it starts with ANIMATIONS_DIR
    abs_full_path = os.path.abspath(full_path)
    abs_animations_dir = os.path.abspath(app.config['ANIMATIONS_FOLDER'])
    if not abs_full_path.startswith(abs_animations_dir):
        return jsonify({"error": "Invalid file path."}), 400

    try:
        data_to_save = request.json
        if not data_to_save:
            return jsonify({"error": "No data provided"}), 400

        # Format the data back to the .animation string format
        file_content_string = format_animation_data_to_string(data_to_save)

        # Write the content to the file, overwriting it
        with open(full_path, 'w', encoding='utf-8') as f:
            f.write(file_content_string)
        
        return jsonify({"message": "Animation saved successfully!"}), 200

    except Exception as e:
        print(f"Error saving animation file {animation_filename}: {str(e)}")
        return jsonify({"error": f"Failed to save animation: {str(e)}"}), 500


@app.route('/animations_root/<path:filename>')
def serve_animation_asset(filename):
    return send_from_directory(os.path.abspath(app.config['ANIMATIONS_FOLDER']), filename)

if __name__ == '__main__':
    app.run(debug=True)
