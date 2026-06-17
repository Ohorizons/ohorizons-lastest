# ${{values.name}}

${{values.description}}

## Overview

This is a documentation site built with MkDocs Material theme.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |

## Features

- MkDocs with Material theme
- Search functionality
- Dark/light mode
- Mermaid diagrams
- Code highlighting
- TechDocs integration

## Getting Started

### Prerequisites

- Python 3.9+
- pip

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Serve locally
mkdocs serve

# Build static site
mkdocs build
```

## Structure

```
docs/
├── index.md           # Home page
├── getting-started.md # Getting started guide
├── architecture/      # Architecture docs
├── guides/           # How-to guides
└── reference/        # API reference
```

## Configuration

Edit `mkdocs.yml` to customize:

- Site name and description
- Navigation structure
- Theme settings
- Plugins

## Deployment

Documentation is automatically published to GitHub Pages on push to main.

## Links

- [MkDocs Documentation](https://www.mkdocs.org/)
- [Material Theme](https://squidfunk.github.io/mkdocs-material/)
