#!/usr/bin/env python3
"""Add ui:options.catalogFilter to all OwnerPicker fields in templates."""

import os
import re

GOLDEN_PATHS_DIR = "/tmp/golden-paths-push"

def fix_ownerpicker(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Skip if already has catalogFilter after OwnerPicker
    if 'catalogFilter' in content:
        print(f"  SKIP (already has catalogFilter): {filepath}")
        return False

    # Pattern: find "ui:field: OwnerPicker" and add ui:options block after it
    # We need to match the indentation level
    pattern = r'((\s+)ui:field: OwnerPicker)\n'

    def replacement(match):
        full_match = match.group(1)
        indent = match.group(2)
        return (
            f"{full_match}\n"
            f"{indent}ui:options:\n"
            f"{indent}  catalogFilter:\n"
            f"{indent}    kind: Group\n"
        )

    new_content = re.sub(pattern, replacement, content)

    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"  FIXED: {filepath}")
        return True
    else:
        print(f"  NO CHANGE: {filepath}")
        return False

def main():
    fixed = 0
    for root, dirs, files in os.walk(GOLDEN_PATHS_DIR):
        if '.git' in root:
            continue
        for fname in files:
            if fname == 'template.yaml':
                path = os.path.join(root, fname)
                if fix_ownerpicker(path):
                    fixed += 1
    print(f"\nFixed {fixed} templates")

if __name__ == '__main__':
    main()
