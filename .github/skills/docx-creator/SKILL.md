---
name: docx-creator
description: >
  Create vibrant, colorful Microsoft Word documents (.docx) using the Microsoft 4-color palette
  (Red, Green, Blue, Yellow). Each section gets a different logo color for headings and tables, with
  decorative 4-color bars between sections. USE FOR: create Word document, generate docx, write report,
  Microsoft-branded document, workshop guide, training material, whitepaper, proposal, executive document,
  colorful document, visual handout. DO NOT USE FOR: presentations (use pptx-creator),
  diagrams (use figjam-diagrams), Excel (use xlsx-creator), PDF (use pdf-creator).
---

# Microsoft DOCX Colorful Creator

Create **enterprise-grade, professional** Word documents using the **Microsoft 4-color palette** as a visually rich alternative to the standard single-blue `docx-creator` workflow.

## Core Principles — ALWAYS Follow These

Every document created with this skill MUST include:

| # | Requirement | Details |
|---|-------------|---------|
| 1 | **Cover Page** | Modern, themed, with Microsoft+GitHub logo, 4-color bars, title, metadata, confidentiality |
| 2 | **Table of Contents** | Always generated after cover page — no exceptions |
| 3 | **Document Properties** | Auto-filled: author=`admin@example.com`, title, subject, keywords matching the theme |
| 4 | **Header** | `{Title} \| Microsoft Azure & GitHub Accelerator Team` (NEVER "Latam") |
| 5 | **Footer** | `Microsoft Internal \| Page X of Y` |
| 6 | **Rich Visual Elements** | Tables, icons, highlights, callouts, diagrams, flows, charts as needed |
| 7 | **Standard Closing Page** | "Thank You" + Contact info + Next Steps (when applicable) |
| 8 | **English Only** | All content must be written in English |
| 9 | **Best Practices** | Use enterprise documentation best practices throughout |

## When to Use This vs docx-creator

| This skill (microsoft-docx-colorful) | docx-creator |
|-------------------------------|-----------------|
| Client-facing workshop guides | Internal technical specs |
| Training materials & participant guides | Architecture documents |
| Assessment reports & playbooks | Formal proposals |
| Visually rich enterprise handouts | Executive summaries |
| Educational/didactic content | Single-color branded docs |
| When user asks for "colorful" | When user asks for "standard" |

## Color System

The Microsoft colors rotate across sections:

| Color | Hex | RGB | Text Color |
|-------|-----|-----|------------|
| Blue | #00A4EF | rgb(0, 164, 239) | White |
| Green | #7FBA00 | rgb(127, 186, 0) | White |
| Yellow | #FFB900 | rgb(255, 185, 0) | **Black** (readability) |
| Red | #F25022 | rgb(242, 80, 34) | White |

## Quick Start

```python
import sys, os
sys.path.insert(0, '<skill-path>/scripts')
from create_colorful_document import MSColorfulDocCreator, Icons

# Logo auto-resolves from assets/ folder, or specify explicitly
doc = MSColorfulDocCreator(
    title="Document Title",
    subtitle="Description of the document",
    version="1.0",
    client="Client Name",                    # Optional
    author="admin@example.com",       # Always this
    subject="Topic keywords for properties", # Auto-fills doc properties
    keywords="keyword1, keyword2, keyword3", # Auto-fills doc properties
    category="Workshop Guide",               # Auto-fills doc properties
    logo_path="<skill-path>/assets/logo-msft-github-color-black.png",  # Auto-resolved if omitted
)

# 1. ALWAYS: Cover + TOC + Header/Footer
doc.create_full_document()

# 2. Content with rotating colors
doc.add_executive_summary("Overview text...", color="blue")

doc.add_color_bar()
doc.add_section_heading("Section Title", level=1, color="green")
doc.add_body("Paragraph text...")
doc.add_bullets(["Item 1", "Item 2"])
doc.add_table(
    headers=["Col1", "Col2", "Col3"],
    rows=[["A", "B", "C"], ["D", "E", "F"]],
    color="green"
)

doc.add_color_bar()
doc.add_section_heading("Another Section", level=1, color="yellow")
doc.add_highlight_box("Key Point", "Important content here", color="yellow", icon=Icons.TARGET)
doc.add_key_takeaway("Critical insight...", color="yellow")
doc.add_best_practice("Recommended approach...", color="green")
doc.add_note("Tip: ", "Helpful information", color="blue")
doc.add_diagram_placeholder("Architecture diagram description", color="blue")
doc.add_code_block("print('hello')", language="python")
doc.add_source("Source Name", "https://url.com")
doc.add_icon_list([(Icons.CHECK, "Done"), (Icons.ROCKET, "In Progress")])

# 3. ALWAYS: Closing page with contact and next steps
doc.add_closing_page(
    next_steps=["Step 1", "Step 2", "Step 3"],
    contact_name="Open Horizons",
    contact_email="admin@example.com",
    contact_role="Senior Software Engineer | Agentic DevOps Platform",
    contact_team="Microsoft Azure & GitHub Accelerator Team",
    github_usernames=["@your-github", "@your-github-alt"],  # Default if omitted
    additional_contacts=[  # Optional
        {"name": "Colleague", "email": "email@microsoft.com", "role": "Role",
         "github": ["@username"]}
    ]
)

doc.save("/path/to/output.docx")
```

**Dependencies:** `pip install python-docx lxml`

## Workflow

```
1. IDENTIFY document type and target audience
2. GATHER content — NEVER invent information
3. PLAN color assignment: assign each major section a logo color (rotate evenly)
4. CREATE with scripts/create_colorful_document.py:
   a. Initialize with ALL properties (title, subtitle, subject, keywords, category)
   b. create_full_document()  → Cover + TOC + Header/Footer
   c. Add content sections with rich visual elements
   d. add_closing_page()      → Contact + Next Steps
5. SAVE with naming: {name}_v{version}.docx
```

## Document Properties — ALWAYS Fill These

The document properties (File > Properties in Word) MUST be filled:

| Property | Value | Example |
|----------|-------|---------|
| **Author** | `admin@example.com` | Always |
| **Title** | Document title | "Agentic DevOps Workshop Guide" |
| **Subject** | Topic description | "AI-Native DevOps, GitHub Copilot, Azure" |
| **Keywords** | Relevant keywords | "DevOps, AI, GitHub, Azure, Workshop" |
| **Category** | Document type | "Workshop Guide", "Assessment Report", etc. |
| **Comments** | Team attribution | "Created by Microsoft Azure & GitHub Accelerator Team" |
| **Language** | `en-US` | Always English |

## Visual Elements — Use Generously

Use these elements throughout documents to create professional, enterprise-grade content:

| Element | Method | When to Use |
|---------|--------|-------------|
| **Colored Table** | `add_table(headers, rows, color)` | Data comparisons, inventories, agendas, matrices |
| **Highlight Box** | `add_highlight_box(title, text, color, icon)` | Key points, important callouts, warnings |
| **Key Takeaway** | `add_key_takeaway(text, color)` | Section summaries, critical insights |
| **Best Practice** | `add_best_practice(text, color)` | Recommended approaches, guidelines |
| **Note/Callout** | `add_note(title, text, color)` | Tips, warnings, info callouts |
| **Icon List** | `add_icon_list([(icon, text)])` | Status lists, feature lists, checklists |
| **Diagram Placeholder** | `add_diagram_placeholder(desc, color)` | Architecture, flows, sequences |
| **Code Block** | `add_code_block(code, language)` | Configuration, API samples |
| **Color Bar** | `add_color_bar()` | Section separators |
| **Source Citation** | `add_source(text, url)` | External references |
| **Version History** | `add_version_history(versions)` | Document versioning |
| **Glossary** | `add_glossary([(term, def)])` | Technical terms |
| **Exec Summary** | `add_executive_summary(text, color)` | Long documents (5+ pages) |

### Available Icons (from `Icons` class)

```
CHECK ✅    WARNING ⚠️   INFO ℹ️      IMPORTANT ❗   TIP 💡
PIN 📌      ROCKET 🚀    TARGET 🎯    CHART 📊       GEAR ⚙️
LINK 🔗     CALENDAR 📅  PERSON 👤    TEAM 👥        EMAIL 📧
STAR ⭐     CLOCK ⏱️     SHIELD 🛡️    KEY 🔑         ARROW_RIGHT ➡️
PROGRESS 🔄 NEXT ▶️
```

## Color Assignment Strategy

Distribute colors evenly. Default rotation: Blue → Green → Yellow → Red → repeat.

Use `doc.next_color()` for auto-rotation, or specify explicitly:
```python
doc.add_section_heading("Section", color="blue")    # Explicit
doc.add_section_heading("Section")                   # Auto-rotation
```

For tables within a section, match the section's color OR use a contrasting one.

## Document Structure Standards

### For ALL Documents
```
Cover Page (themed)
Table of Contents
[Version History — if multiple versions]
[Executive Summary — if 5+ pages]
Content Sections (with visual elements)
[Glossary — if technical terms used]
Closing Page (contact + next steps)
```

### Header Format
```
Line 1: {Title} | Microsoft Azure & GitHub Accelerator Team
Line 2: Version {x.xx} | admin@example.com
```

⚠️ **IMPORTANT**: Always use "Microsoft Azure & GitHub Accelerator Team" — NEVER "Latam", "LATAM", or "Latam Software GBB".

## Content Rules

### CRITICAL — Never Invent Information
- Use ONLY information from context, directory, or project knowledge
- ALWAYS cite external sources with `doc.add_source()`
- If unavailable, state: "Information not available in provided context"

### Enterprise Best Practices
- Use tables for ANY structured/comparative data
- Add highlight boxes for key points in every major section
- Include diagrams/flow placeholders where architecture or process is described
- Add icon lists for status tracking and checklists
- Use notes/callouts for tips, warnings, and important information
- Include glossary when 3+ technical acronyms are used
- Add executive summary for documents with 5+ content pages
- Always include next steps on the closing page when actionable items exist

## Typography — Segoe UI Family ONLY

All text in the document MUST use Segoe UI and its variations. No other fonts allowed.

| Element | Font | Size | Weight |
|---------|------|------|--------|
| Cover Title | Segoe UI Light | 32pt | Regular |
| Cover Subtitle | Segoe UI Semilight | 16pt | Regular |
| Heading 1 | Segoe UI | 18pt | Bold |
| Heading 2 | Segoe UI | 15pt | Bold |
| Heading 3 | Segoe UI Semibold | 13pt | Bold |
| Heading 4 | Segoe UI | 12pt | Bold |
| Body Text | Segoe UI | 11pt | Regular |
| Table Header | Segoe UI | 10pt | Bold |
| Table Body | Segoe UI | 10pt | Regular |
| Code Blocks | Consolas | 10pt | Regular |
| Captions | Segoe UI | 9pt | Italic |
| Source Citations | Segoe UI | 9pt | Italic |
| Header | Segoe UI | 9pt/8pt | Regular |
| Footer | Segoe UI | 8pt | Regular |

## Resources

| File | Purpose |
|------|---------|
| `scripts/create_colorful_document.py` | Main class with all methods |
| `assets/logo-msft-github-white-bg.png` | Microsoft + GitHub logo for cover page (white background, auto-resolved) |

## Quality Checklist

- [ ] Cover page: logo, themed title, subtitle, 4-color bars, metadata, confidentiality
- [ ] Table of Contents generated
- [ ] Document properties filled (author, title, subject, keywords, category, language)
- [ ] Header: `{Title} \| Microsoft Azure & GitHub Accelerator Team` (NOT Latam)
- [ ] Footer: `Microsoft Internal \| Page X of Y`
- [ ] Color bars between major sections
- [ ] Each section has a distinct logo color (rotating)
- [ ] Yellow headers have dark text (not white)
- [ ] Tables used for structured data
- [ ] Highlight boxes / callouts for key points
- [ ] Icons used where appropriate
- [ ] Diagrams/flow placeholders where needed
- [ ] Sources cited with links
- [ ] No fabricated information
- [ ] Executive summary included (if 5+ pages)
- [ ] Glossary included (if 3+ acronyms)
- [ ] Closing page: Thank You + Contact (with GitHub: @your-github @your-github-alt) + Next Steps
- [ ] All content in English
- [ ] Filename: `{name}_v{version}.docx`