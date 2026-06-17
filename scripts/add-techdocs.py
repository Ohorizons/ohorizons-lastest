#!/usr/bin/env python3
"""Ensure every Golden Path skeleton has minimal TechDocs sources."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOLDEN_PATHS = ROOT / "golden-paths"

MKDOCS = """site_name: ${{ values.name }}
site_description: ${{ values.description }}

theme:
  name: material

plugins:
  - search
  - techdocs-core

nav:
  - Home: index.md
"""

INDEX = """# ${{ values.name }}

${{ values.description }}

## Overview

This Golden Path provides a preconfigured starting point for Open Horizons.

## Getting Started

1. Create the component from the Backstage software catalog.
2. Fill in the required ownership, repository, and runtime settings.
3. Review the generated repository and CI/CD workflow.
4. Register the generated component in the catalog.

## Generated Assets

- Backstage catalog metadata
- Source or infrastructure skeleton
- CI/CD and local development scaffolding where applicable
- TechDocs documentation source
"""

DOC_SITE_PAGES = {
    "docs/getting-started.md": """# Getting Started

Use this site as the documentation home for your generated component.

## Local Preview

Install TechDocs dependencies and run MkDocs from the repository root.

```bash
pip install mkdocs-techdocs-core
mkdocs serve
```
""",
    "docs/architecture/overview.md": """# Architecture Overview

Document the component boundaries, dependencies, and deployment topology here.
""",
    "docs/guides/user-guide.md": """# User Guide

Add task-oriented guidance for developers and operators who use this component.
""",
    "docs/reference/api.md": """# API Reference

Add API, configuration, and operational reference material here.
""",
}


def write_if_missing(path: Path, content: str) -> bool:
    if path.exists():
        return False

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return True


def ensure_techdocs_annotation(catalog_path: Path) -> bool:
    text = catalog_path.read_text(encoding="utf-8")
    if "backstage.io/techdocs-ref" in text:
        return False

    if "  annotations:\n" in text:
        text = text.replace(
            "  annotations:\n",
            "  annotations:\n    backstage.io/techdocs-ref: dir:.\n",
            1,
        )
    elif "  tags:\n" in text:
        text = text.replace(
            "  tags:\n",
            "  annotations:\n    backstage.io/techdocs-ref: dir:.\n  tags:\n",
            1,
        )
    elif "spec:\n" in text:
        text = text.replace(
            "spec:\n",
            "  annotations:\n    backstage.io/techdocs-ref: dir:.\nspec:\n",
            1,
        )
    else:
        return False

    catalog_path.write_text(text, encoding="utf-8")
    return True


def main() -> None:
    changed = 0
    for template_path in sorted(GOLDEN_PATHS.glob("*/*/template.yaml")):
        skeleton = template_path.parent / "skeleton"
        if not skeleton.is_dir():
            continue

        catalog_path = skeleton / "catalog-info.yaml"
        if catalog_path.exists() and ensure_techdocs_annotation(catalog_path):
            changed += 1

        if write_if_missing(skeleton / "mkdocs.yml", MKDOCS):
            changed += 1
        if write_if_missing(skeleton / "docs" / "index.md", INDEX):
            changed += 1

        if template_path.parent.name == "documentation-site":
            for relative_path, content in DOC_SITE_PAGES.items():
                if write_if_missing(skeleton / relative_path, content):
                    changed += 1

        print(f"  {template_path.parent.relative_to(GOLDEN_PATHS)}: OK")

    print(f"Done. Files or annotations changed: {changed}")


if __name__ == "__main__":
    main()
