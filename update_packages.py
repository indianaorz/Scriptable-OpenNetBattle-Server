import os
import shutil
import zipfile

def update_packages(parent_folder_path):
    """
    Turns all child folders of a given parent folder into .zip files.

    The .zip files will be stored in the parent folder and named after
    the original child folder. If a .zip file with the same name already
    exists, it will be deleted and a new one will be created.

    Args:
        parent_folder_path (str): The absolute or relative path to the
                                  parent folder.
    """
    parent_folder_path = os.path.abspath(parent_folder_path)

    if not os.path.isdir(parent_folder_path):
        print(f"Error: Parent folder '{parent_folder_path}' not found.")
        return

    print(f"Processing folders in: {parent_folder_path}")

    for item_name in os.listdir(parent_folder_path):
        item_path = os.path.join(parent_folder_path, item_name)

        if os.path.isdir(item_path):
            folder_name = item_name
            zip_file_name = f"{folder_name}.zip"
            zip_file_path = os.path.join(parent_folder_path, zip_file_name)

            # Delete existing zip file if it exists
            if os.path.exists(zip_file_path):
                try:
                    os.remove(zip_file_path)
                    print(f"Deleted existing zip: {zip_file_path}")
                except OSError as e:
                    print(f"Error deleting {zip_file_path}: {e}")
                    continue # Skip to the next folder if deletion fails

            print(f"Creating zip for: {folder_name} -> {zip_file_name}")

            try:
                with zipfile.ZipFile(zip_file_path, 'w', zipfile.ZIP_DEFLATED) as zf:
                    for root, _, files in os.walk(item_path):
                        for file in files:
                            file_path_in_folder = os.path.join(root, file)
                            # Arcname is the path inside the zip file
                            arcname = os.path.relpath(file_path_in_folder, item_path)
                            zf.write(file_path_in_folder, arcname)
                    print(f"Successfully created: {zip_file_path}")
            except Exception as e:
                print(f"Error creating zip {zip_file_path} for folder {folder_name}: {e}")

    print("\nPackage update process complete. 🎉")

if __name__ == '__main__':
    # --- How to use ---
    # 1. Replace 'your_parent_folder_path_here' with the actual path
    #    to your parent directory.
    #
    # Example paths:
    #   Windows: r"C:\Users\YourUser\Desktop\MyPackages"
    #   macOS/Linux: "/Users/YourUser/Documents/MyPackages"
    #   Relative path (if script is in the parent of 'MyPackages'): "MyPackages"

    target_parent_folder = 'assets' # <--- !!! CHANGE THIS !!!

    # --- Create dummy folders and files for testing (optional) ---
    # You can uncomment this section to create a test environment.
    # Make sure 'target_parent_folder' is set to a safe test location first.
    '''
    if target_parent_folder == 'your_parent_folder_path_here':
        print("Please set 'target_parent_folder' to a specific path before running test setup.")
    else:
        print(f"Setting up dummy folders in: {target_parent_folder}")
        os.makedirs(target_parent_folder, exist_ok=True)
        # Create some child folders with files
        for i in range(1, 4):
            child_folder_name = f"package_{i}"
            child_folder_path = os.path.join(target_parent_folder, child_folder_name)
            os.makedirs(child_folder_path, exist_ok=True)
            with open(os.path.join(child_folder_path, f"file_a_in_{child_folder_name}.txt"), "w") as f:
                f.write(f"Content for file A in {child_folder_name}")
            with open(os.path.join(child_folder_path, f"file_b_in_{child_folder_name}.txt"), "w") as f:
                f.write(f"Content for file B in {child_folder_name}")

            # Create a sub-sub-folder for testing nested structure
            sub_child_path = os.path.join(child_folder_path, "subfolder")
            os.makedirs(sub_child_path, exist_ok=True)
            with open(os.path.join(sub_child_path, "nested_file.txt"), "w") as f:
                f.write(f"Content for nested file in {child_folder_name}")

        # Create an empty child folder
        os.makedirs(os.path.join(target_parent_folder, "empty_package"), exist_ok=True)

        # Create a dummy zip to test deletion
        existing_zip_path = os.path.join(target_parent_folder, "package_1.zip")
        with open(existing_zip_path, "w") as f:
            f.write("This is a dummy zip to be deleted.")
        print("Dummy folders and files created.")
    '''
    # --- End of dummy folder creation ---

    if target_parent_folder == 'your_parent_folder_path_here':
        print("\n⚠️  Please edit the script and set the 'target_parent_folder' variable"
              " to the path of your parent directory before running.")
    else:
        update_packages(target_parent_folder)