---
name: pdf-creator
description: "Creates professional Microsoft-branded PDF documents with cover pages, 4-color palette, tables, charts, headers/footers, and executive formatting using Python and reportlab. USE FOR: create PDF, generate pdf, build PDF report, Microsoft branded PDF, PDF proposal, PDF whitepaper, executive PDF, PDF with charts, PDF with tables. DO NOT USE FOR: Word documents (use docx-creator), presentations (use pptx-creator), Excel (use xlsx-creator), diagrams (use figjam-diagrams)."
---

# PDF Creator

Create professional Microsoft-branded PDF documents (.pdf) using Python and reportlab with enterprise-grade formatting, cover pages, tables, charts, headers/footers, and the Microsoft 4-color palette.

## Technology

All PDF files are generated using **Python 3 + reportlab**. The agent writes a Python script, executes it, and delivers the `.pdf` file.

### Required Package

```bash
pip install reportlab
```

If not installed, the agent installs it automatically before generating.

## Branding Defaults

### Color Palette (Microsoft Brand)

| Element | Hex | reportlab Color | Use For |
|---------|-----|----------------|---------|
| Primary Blue | `#0078D4` | `HexColor('#0078D4')` | Headers, title bars, section dividers |
| Red | `#F25022` | `HexColor('#F25022')` | Alerts, risks, critical items |
| Green | `#7FBA00` | `HexColor('#7FBA00')` | Success, positive metrics, completed |
| Blue | `#00A4EF` | `HexColor('#00A4EF')` | Info, links, secondary elements |
| Yellow | `#FFB900` | `HexColor('#FFB900')` | Warnings, in-progress, highlights |
| Dark Green | `#107C10` | `HexColor('#107C10')` | Confirmed, healthy status |
| Red Alert | `#E81123` | `HexColor('#E81123')` | Security, blocked, critical |
| Teal | `#008272` | `HexColor('#008272')` | Infrastructure, monitoring |
| Purple | `#5C2D91` | `HexColor('#5C2D91')` | AI, modernization |
| Orange | `#D83B01` | `HexColor('#D83B01')` | Manual actions, human steps |
| Text Primary | `#323130` | `HexColor('#323130')` | Body text |
| Text Secondary | `#605E5C` | `HexColor('#605E5C')` | Captions, metadata, footers |
| Background Light | `#F3F2F1` | `HexColor('#F3F2F1')` | Alternating table rows |
| Background White | `#FFFFFF` | `colors.white` | Page background |
| Border Gray | `#D2D0CE` | `HexColor('#D2D0CE')` | Table borders |

### 4-Color Bar

Every PDF includes the Microsoft 4-color gradient bar on the cover page and as a thin line in the header:

```python
from reportlab.lib.colors import HexColor

def draw_4color_bar(canvas, x, y, width, height=4):
    """Draw the Microsoft 4-color bar."""
    segment = width / 4
    bar_colors = [
        HexColor('#F25022'),  # Red
        HexColor('#7FBA00'),  # Green
        HexColor('#00A4EF'),  # Blue
        HexColor('#FFB900'),  # Yellow
    ]
    for i, color in enumerate(bar_colors):
        canvas.setFillColor(color)
        canvas.rect(x + i * segment, y, segment, height, fill=1, stroke=0)
```

### Fonts

reportlab includes Helvetica by default. For Microsoft branding, register Segoe UI if available:

```python
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import os

# Try to register Segoe UI (available on Windows/macOS with Office installed)
segoe_paths = [
    '/Library/Fonts/Segoe UI.ttf',
    '/System/Library/Fonts/SegoeUI.ttf',
    'C:/Windows/Fonts/segoeui.ttf',
]
FONT_NAME = 'Helvetica'  # Fallback
for path in segoe_paths:
    if os.path.exists(path):
        pdfmetrics.registerFont(TTFont('SegoeUI', path))
        FONT_NAME = 'SegoeUI'
        break
```

| Element | Font | Size | Style |
|---------|------|------|-------|
| Cover title | FONT_NAME | 28pt | Bold |
| Cover subtitle | FONT_NAME | 16pt | Regular |
| Section heading (H1) | FONT_NAME | 18pt | Bold, #0078D4 |
| Subsection heading (H2) | FONT_NAME | 14pt | Bold, #323130 |
| Body text | FONT_NAME | 10pt | Regular, #323130 |
| Table header | FONT_NAME | 10pt | Bold, White on #0078D4 |
| Table body | FONT_NAME | 9pt | Regular |
| Footer | FONT_NAME | 8pt | Italic, #605E5C |
| KPI number | FONT_NAME | 36pt | Bold |
| KPI label | FONT_NAME | 10pt | Regular, #605E5C |

## Document Structure

### Page Setup

```python
from reportlab.lib.pagesizes import A4

PAGE_WIDTH, PAGE_HEIGHT = A4
MARGIN_LEFT = 60
MARGIN_RIGHT = 60
MARGIN_TOP = 60
MARGIN_BOTTOM = 50
CONTENT_WIDTH = PAGE_WIDTH - MARGIN_LEFT - MARGIN_RIGHT
```

### Page 1: Cover Page

```
┌─────────────────────────────────────────┐
│  [4-color bar across full width]        │
│                                         │
│         (vertical spacer ~200pt)        │
│                                         │
│         DOCUMENT TITLE                  │
│         28pt Bold, #0078D4              │
│                                         │
│         Subtitle or Description         │
│         16pt Regular, #605E5C           │
│                                         │
│         (vertical spacer ~100pt)        │
│                                         │
│  ┌──────────────────────────────┐       │
│  │  Author: {{author_name}}    │       │
│  │  Date: {{date}}             │       │
│  │  Version: {{version}}       │       │
│  │  Client: {{client_name}}    │       │
│  │  Status: {{status}}         │       │
│  └──────────────────────────────┘       │
│                                         │
│  Microsoft Confidential                 │
│  [4-color bar across full width]        │
└─────────────────────────────────────────┘
```

### Content Pages

```
┌─────────────────────────────────────────┐
│  [thin 4-color bar - 2px]              │
│  Document Title          Page X of Y    │
│  ─────────────────────────────────────  │
│                                         │
│  ## Section Title                       │
│  Body text...                           │
│                                         │
│  ┌─────────────────────────────┐        │
│  │  Table with branded headers │        │
│  │  Alternating row colors     │        │
│  └─────────────────────────────┘        │
│                                         │
│  Body text continues...                 │
│                                         │
│  ─────────────────────────────────────  │
│  {{client_name}} | v{{version}} | Conf  │
└─────────────────────────────────────────┘
```

## Table Formatting

```python
from reportlab.lib import colors
from reportlab.platypus import Table, TableStyle

def create_branded_table(data, col_widths=None):
    """Create a Microsoft-branded table."""
    table = Table(data, colWidths=col_widths)
    style = TableStyle([
        # Header row
        ('BACKGROUND', (0, 0), (-1, 0), HexColor('#0078D4')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), FONT_NAME),
        ('FONTSIZE', (0, 0), (-1, 0), 10),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
        ('TOPPADDING', (0, 0), (-1, 0), 8),

        # Body rows
        ('FONTNAME', (0, 1), (-1, -1), FONT_NAME),
        ('FONTSIZE', (0, 1), (-1, -1), 9),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 6),
        ('TOPPADDING', (0, 1), (-1, -1), 6),
        ('TEXTCOLOR', (0, 1), (-1, -1), HexColor('#323130')),

        # Alternating rows
        *[('BACKGROUND', (0, i), (-1, i),
           HexColor('#F3F2F1') if i % 2 == 0 else colors.white)
          for i in range(1, len(data))],

        # Borders
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#D2D0CE')),
        ('LINEBELOW', (0, 0), (-1, 0), 1.5, HexColor('#0078D4')),

        # Alignment
        ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ])
    table.setStyle(style)
    return table
```

## Header and Footer

```python
def add_header_footer(canvas, doc, title, client_name, version):
    """Add branded header and footer to every page."""
    canvas.saveState()
    width, height = A4

    # Header: 4-color bar (2px)
    draw_4color_bar(canvas, 0, height - 15, width, height=2)

    # Header: title left, page number right
    canvas.setFont(FONT_NAME, 8)
    canvas.setFillColor(HexColor('#605E5C'))
    canvas.drawString(MARGIN_LEFT, height - 35, title)
    canvas.drawRightString(width - MARGIN_RIGHT, height - 35,
                          f"Page {doc.page}")

    # Footer: separator line
    canvas.setStrokeColor(HexColor('#D2D0CE'))
    canvas.line(MARGIN_LEFT, 35, width - MARGIN_RIGHT, 35)

    # Footer: text
    canvas.setFont(FONT_NAME, 7)
    canvas.setFillColor(HexColor('#605E5C'))
    canvas.drawString(MARGIN_LEFT, 22,
                     f"{client_name} | v{version} | Confidential")
    canvas.drawRightString(width - MARGIN_RIGHT, 22,
                          f"Page {doc.page}")

    canvas.restoreState()
```

## Document Types

| Type | Sections | Key Features |
|------|----------|-------------|
| **Report** | Executive Summary, Findings, Analysis, Recommendations, References | Tables, metrics, charts |
| **Proposal** | Context, Solution, Approach, Timeline, Investment, Next Steps | Value tables, roadmap |
| **Whitepaper** | Abstract, Introduction, Methodology, Results, Conclusion, References | Academic style, citations |
| **Assessment** | Scope, Methodology, Findings, Scoring, Recommendations, Appendix | Radar charts, heatmaps, scoring tables |
| **Guide** | Overview, Prerequisites, Steps, Troubleshooting, FAQ, Appendix | Numbered steps, code blocks, callouts |
| **Executive Brief** | Context, Key Findings, Recommendations, Next Steps | 2-4 pages, KPI cards, concise |

## Callout Boxes

```python
from reportlab.platypus import Paragraph, Spacer
from reportlab.lib.styles import ParagraphStyle

def create_callout(text, callout_type='info'):
    """Create a colored callout box."""
    colors_map = {
        'info': ('#E8F4FD', '#0078D4'),
        'warning': ('#FFF3E0', '#FFB900'),
        'success': ('#E8F5E9', '#107C10'),
        'critical': ('#FDEDED', '#E81123'),
    }
    bg, border = colors_map.get(callout_type, colors_map['info'])
    style = ParagraphStyle(
        'Callout',
        fontName=FONT_NAME,
        fontSize=9,
        leading=13,
        textColor=HexColor('#323130'),
        backColor=HexColor(bg),
        borderColor=HexColor(border),
        borderWidth=2,
        borderPadding=10,
        leftIndent=4,
        spaceBefore=8,
        spaceAfter=8,
    )
    return Paragraph(text, style)
```

## KPI Cards

```python
def create_kpi_card(canvas, x, y, value, label, color='#0078D4', width=120, height=70):
    """Draw a KPI card with large number and label."""
    # Background
    canvas.setFillColor(HexColor('#FFFFFF'))
    canvas.setStrokeColor(HexColor(color))
    canvas.setLineWidth(2)
    canvas.roundRect(x, y, width, height, 6, fill=1, stroke=1)

    # Value
    canvas.setFont(FONT_NAME, 28)
    canvas.setFillColor(HexColor(color))
    canvas.drawCentredString(x + width/2, y + height - 35, str(value))

    # Label
    canvas.setFont(FONT_NAME, 8)
    canvas.setFillColor(HexColor('#605E5C'))
    canvas.drawCentredString(x + width/2, y + 10, label)
```

## Factual Integrity

- NEVER fabricate metrics, KPIs, ROI figures, market data, or statistics
- Only use data from: workspace context, user-provided materials, or credible official sources
- Every metric or market claim MUST include a source citation
- If no credible source exists, state as assumption or omit entirely
- Add a References section at the end of every document
- Use footnote-style citations: "...reduced costs by 40% [1]"

## Versioning and Archiving

- Filename: `{Title}_v{version}_{YYYY-MM-DD}.pdf`
- Save to: `output/pdf/`
- Archive previous: `output/pdf/archive/`
- Cover page MUST show: title, version, date, author, client

## Script Template

```python
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.colors import HexColor
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm, inch
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, Image, KeepTogether
)
from reportlab.pdfbase import pdfmetrics
from datetime import date
import os

# === CONFIG ===
TITLE = "{{title}}"
SUBTITLE = "{{subtitle}}"
CLIENT = "{{client_name}}"
AUTHOR = "{{author_name}}"
VERSION = "{{version}}"
DATE = date.today().isoformat()

# === COLORS ===
BLUE = HexColor('#0078D4')
RED = HexColor('#F25022')
GREEN = HexColor('#7FBA00')
LIGHT_BLUE = HexColor('#00A4EF')
YELLOW = HexColor('#FFB900')
TEXT = HexColor('#323130')
TEXT_LIGHT = HexColor('#605E5C')
BG_ALT = HexColor('#F3F2F1')
BORDER = HexColor('#D2D0CE')

# === BUILD ===
filename = f"{TITLE.replace(' ', '_')}_v{VERSION}_{DATE}.pdf"
filepath = f"output/pdf/{filename}"
doc = SimpleDocTemplate(filepath, pagesize=A4,
    leftMargin=60, rightMargin=60, topMargin=60, bottomMargin=50)

story = []
# ... build content ...
doc.build(story, onFirstPage=on_cover_page, onLaterPages=on_content_page)
print(f"Created: {filepath}")
```

## Quality Checklist

- [ ] Cover page has title, subtitle, date, author, version, client, 4-color bar
- [ ] All section headings use #0078D4 blue
- [ ] Tables have branded headers (blue background, white text)
- [ ] Alternating row colors on all tables
- [ ] Header with 4-color bar and title on every content page
- [ ] Footer with client name, version, confidentiality, page numbers
- [ ] KPI cards use Microsoft brand colors with large numbers
- [ ] Callout boxes use appropriate colors (info/warning/success/critical)
- [ ] Fonts are consistent throughout (Segoe UI or Helvetica fallback)
- [ ] No fabricated data — all metrics have source citations
- [ ] References section present with all cited sources
- [ ] Filename follows `{Title}_v{version}_{date}.pdf` pattern
- [ ] Saved to `output/pdf/` with previous version archived
