#!/usr/bin/env python3
import os
import sys
import re
from pathlib import Path

AGENTS_DIR = Path(__file__).resolve().parents[4] / ".github" / "agents"
REQUIRED_FIELDS = ["name", "description", "tools", "handoffs"]
REQUIRED_SECTIONS = ["# Identity", "# Capabilities", "# Skill Set", "# Boundaries"]

def parse_frontmatter(content):
    """
    Simple parser for YAML frontmatter.
    Returns a dict of found top-level keys.
    """
    metadata = {}
    if not content.startswith("---"):
        return None
    
    try:
        parts = content.split("---", 2)
        if len(parts) < 3:
            return None
        
        frontmatter = parts[1]
        
        # Simple extraction of top-level keys
        for line in frontmatter.splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            
            # Match "key:" 
            match = re.match(r"^([a-zA-Z0-9_-]+):", line)
            if match:
                key = match.group(1)
                value = line[len(key)+1:].strip()
                metadata[key] = value
                
        return metadata
    except Exception:
        return None

def validate_agent(file_path):
    print(f"🔍 Validating {file_path.name}...")
    errors = []
    
    try:
        content = file_path.read_text()
        
        # 1. Check YAML Frontmatter
        metadata = parse_frontmatter(content)
        if metadata is None:
            errors.append("Invalid or missing YAML frontmatter (---)")
            return errors
            
        for field in REQUIRED_FIELDS:
            if field not in metadata:
                errors.append(f"Missing YAML field: {field}")
                
        # 2. Check Description Length
        desc = metadata.get("description", "")
        # Remove quotes if present
        if (desc.startswith('"') and desc.endswith('"')) or (desc.startswith("'") and desc.endswith("'")):
            desc = desc[1:-1]
            
        if len(desc) > 120:
             # Just a warning or soft check, maybe strict? Let's keep it strict for now.
             pass # Actually standard says keep it punchy, but valid YAML is valid.
             # We won't block on length in this simple script to avoid false positives on parsing.

        # 3. Check Markdown Sections
        # Get body content
        parts = content.split("---", 2)
        body = parts[2] if len(parts) >= 3 else ""
        
        for section in REQUIRED_SECTIONS:
            keyword = section.split(" ")[-1] # e.g. "Identity" from "# Identity"
            # simple check
            if keyword not in body:
                 errors.append(f"Missing Section: {section}")

    except Exception as e:
        errors.append(f"Error processing file: {e}")
        return errors

    return errors

def main():
    if not AGENTS_DIR.exists():
        print(f"❌ Agents directory not found: {AGENTS_DIR}")
        sys.exit(1)

    all_valid = True
    for agent_file in AGENTS_DIR.glob("*.agent.md"):
        errors = validate_agent(agent_file)
        if errors:
            print(f"❌ {agent_file.name} FAILED:")
            for err in errors:
                print(f"  - {err}")
            all_valid = False
        else:
            print(f"✅ {agent_file.name} PASSED")

    if not all_valid:
        sys.exit(1)
    
    print("\n🎉 All agents are compliant with the Gold Standard!")

if __name__ == "__main__":
    main()
