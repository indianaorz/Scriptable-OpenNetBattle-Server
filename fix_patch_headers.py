import sys
import re

def fix_patch_headers(patch_lines):
    fixed_lines = []
    i = 0
    while i < len(patch_lines):
        line = patch_lines[i]
        fixed_lines.append(line)

        if line.startswith("diff --git"):
            parts = line.strip().split()
            if len(parts) == 4:
                _, _, a_path, b_path = parts
                current_a = a_path[2:]
                current_b = b_path[2:]

            # Track metadata
            new_file = False
            has_old = False
            has_new = False

            j = i + 1
            insert_at = len(fixed_lines)
            while j < len(patch_lines):
                subline = patch_lines[j]
                if subline.startswith("diff --git"):
                    break
                if subline.startswith("new file mode"):
                    new_file = True
                if subline.startswith("---"):
                    has_old = True
                if subline.startswith("+++"):
                    has_new = True
                if subline.startswith("@@"):
                    break
                j += 1

            # Fix missing headers
            if not has_old:
                fixed_lines.insert(insert_at, "--- /dev/null\n" if new_file else f"--- a/{current_a}\n")
            if not has_new:
                fixed_lines.insert(insert_at + 1, f"+++ b/{current_b}\n")

        i += 1
    return fixed_lines

def main():
    if len(sys.argv) != 3:
        print("Usage: python fix_patch_headers.py <input.patch> <output.patch>")
        return

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    with open(input_path, "r", encoding="utf-8") as f:
        patch_lines = f.readlines()

    fixed_lines = fix_patch_headers(patch_lines)

    with open(output_path, "w", encoding="utf-8") as f:
        f.writelines(fixed_lines)

    print(f"✔ Fixed patch saved to: {output_path}")

if __name__ == "__main__":
    main()
