"""
PDF Template — Microsoft-Branded PDF Document Generator
Uses reportlab to create professional PDF documents with cover pages and branding.

Usage:
    python3 pdf_template.py

Requirements:
    pip install reportlab

Customization:
    Replace the {{variables}} and sample content with real data.
    The agent should modify this template for each document request.
"""

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.colors import HexColor
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm, inch
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether
)
from datetime import date
import os

# === CONFIG ===
TITLE = "{{title}}"
SUBTITLE = "{{subtitle}}"
AUTHOR = "{{author_name}}"
CLIENT = "{{client_name}}"
VERSION = "1.0.0"
DATE = date.today().isoformat()

# === MICROSOFT BRAND COLORS ===
BLUE = HexColor('#0078D4')
RED = HexColor('#F25022')
GREEN = HexColor('#7FBA00')
LIGHT_BLUE = HexColor('#00A4EF')
YELLOW = HexColor('#FFB900')
DARK_GREEN = HexColor('#107C10')
RED_ALERT = HexColor('#E81123')
TEXT_PRIMARY = HexColor('#323130')
TEXT_SECONDARY = HexColor('#605E5C')
ALT_ROW = HexColor('#F3F2F1')
BORDER_GRAY = HexColor('#D2D0CE')

PAGE_WIDTH, PAGE_HEIGHT = A4
MARGIN = 60
CONTENT_WIDTH = PAGE_WIDTH - 2 * MARGIN

# === FONT SETUP ===
# Try Segoe UI, fall back to Helvetica
FONT_NAME = 'Helvetica'
FONT_BOLD = 'Helvetica-Bold'
try:
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    for path in ['/Library/Fonts/Segoe UI.ttf', 'C:/Windows/Fonts/segoeui.ttf']:
        if os.path.exists(path):
            pdfmetrics.registerFont(TTFont('SegoeUI', path))
            FONT_NAME = 'SegoeUI'
            break
except Exception:
    pass


def draw_4color_bar(canvas, x, y, width, height=4):
    """Draw the Microsoft 4-color bar."""
    bar_colors = [RED, GREEN, LIGHT_BLUE, YELLOW]
    segment = width / 4
    for i, color in enumerate(bar_colors):
        canvas.setFillColor(color)
        canvas.rect(x + i * segment, y, segment, height, fill=1, stroke=0)


def on_cover_page(canvas, doc):
    """Render the cover page."""
    canvas.saveState()
    width, height = A4

    # 4-color bar at top
    draw_4color_bar(canvas, 0, height - 20, width, 6)

    # Title
    canvas.setFont(FONT_BOLD, 28)
    canvas.setFillColor(BLUE)
    canvas.drawCentredString(width / 2, height - 280, TITLE)

    # Subtitle
    canvas.setFont(FONT_NAME, 16)
    canvas.setFillColor(TEXT_SECONDARY)
    canvas.drawCentredString(width / 2, height - 320, SUBTITLE)

    # Metadata box
    y_start = height - 450
    meta_items = [
        f"Author: {AUTHOR}",
        f"Date: {DATE}",
        f"Version: {VERSION}",
        f"Client: {CLIENT}",
        f"Status: Draft",
    ]
    canvas.setFont(FONT_NAME, 10)
    canvas.setFillColor(TEXT_PRIMARY)
    for i, item in enumerate(meta_items):
        canvas.drawCentredString(width / 2, y_start - i * 18, item)

    # Confidentiality notice
    canvas.setFont(FONT_NAME, 8)
    canvas.setFillColor(TEXT_SECONDARY)
    canvas.drawCentredString(width / 2, 80, "Microsoft Confidential")

    # 4-color bar at bottom
    draw_4color_bar(canvas, 0, 60, width, 6)

    canvas.restoreState()


def on_content_page(canvas, doc):
    """Render header and footer on content pages."""
    canvas.saveState()
    width, height = A4

    # Header: 4-color bar
    draw_4color_bar(canvas, 0, height - 15, width, 2)

    # Header: title and page number
    canvas.setFont(FONT_NAME, 8)
    canvas.setFillColor(TEXT_SECONDARY)
    canvas.drawString(MARGIN, height - 35, TITLE)
    canvas.drawRightString(width - MARGIN, height - 35, f"Page {doc.page}")

    # Footer: separator line
    canvas.setStrokeColor(BORDER_GRAY)
    canvas.line(MARGIN, 35, width - MARGIN, 35)

    # Footer: text
    canvas.setFont(FONT_NAME, 7)
    canvas.setFillColor(TEXT_SECONDARY)
    canvas.drawString(MARGIN, 22, f"{CLIENT} | v{VERSION} | Confidential")
    canvas.drawRightString(width - MARGIN, 22, f"Page {doc.page}")

    canvas.restoreState()


def get_styles():
    """Create branded paragraph styles."""
    styles = getSampleStyleSheet()

    styles.add(ParagraphStyle(
        'MSHeading1',
        parent=styles['Heading1'],
        fontName=FONT_BOLD,
        fontSize=18,
        textColor=BLUE,
        spaceBefore=20,
        spaceAfter=10,
    ))

    styles.add(ParagraphStyle(
        'MSHeading2',
        parent=styles['Heading2'],
        fontName=FONT_BOLD,
        fontSize=14,
        textColor=TEXT_PRIMARY,
        spaceBefore=16,
        spaceAfter=8,
    ))

    styles.add(ParagraphStyle(
        'MSBody',
        parent=styles['Normal'],
        fontName=FONT_NAME,
        fontSize=10,
        textColor=TEXT_PRIMARY,
        leading=14,
        spaceBefore=4,
        spaceAfter=8,
    ))

    styles.add(ParagraphStyle(
        'MSCalloutInfo',
        parent=styles['Normal'],
        fontName=FONT_NAME,
        fontSize=9,
        textColor=TEXT_PRIMARY,
        backColor=HexColor('#E8F4FD'),
        borderColor=BLUE,
        borderWidth=2,
        borderPadding=10,
        leftIndent=4,
        spaceBefore=8,
        spaceAfter=8,
    ))

    styles.add(ParagraphStyle(
        'MSCalloutWarning',
        parent=styles['Normal'],
        fontName=FONT_NAME,
        fontSize=9,
        textColor=TEXT_PRIMARY,
        backColor=HexColor('#FFF3E0'),
        borderColor=YELLOW,
        borderWidth=2,
        borderPadding=10,
        leftIndent=4,
        spaceBefore=8,
        spaceAfter=8,
    ))

    return styles


def create_branded_table(data, col_widths=None):
    """Create a Microsoft-branded table."""
    if col_widths is None:
        col_widths = [CONTENT_WIDTH / len(data[0])] * len(data[0])

    table = Table(data, colWidths=col_widths)
    style_commands = [
        # Header
        ('BACKGROUND', (0, 0), (-1, 0), BLUE),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), FONT_BOLD),
        ('FONTSIZE', (0, 0), (-1, 0), 10),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
        ('TOPPADDING', (0, 0), (-1, 0), 8),
        ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
        # Body
        ('FONTNAME', (0, 1), (-1, -1), FONT_NAME),
        ('FONTSIZE', (0, 1), (-1, -1), 9),
        ('TEXTCOLOR', (0, 1), (-1, -1), TEXT_PRIMARY),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 6),
        ('TOPPADDING', (0, 1), (-1, -1), 6),
        # Borders
        ('GRID', (0, 0), (-1, -1), 0.5, BORDER_GRAY),
        ('LINEBELOW', (0, 0), (-1, 0), 1.5, BLUE),
        # Alignment
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ]
    # Alternating rows
    for i in range(1, len(data)):
        if i % 2 == 0:
            style_commands.append(('BACKGROUND', (0, i), (-1, i), ALT_ROW))

    table.setStyle(TableStyle(style_commands))
    return table


def create_document():
    """Generate the complete branded PDF document."""
    os.makedirs('output/pdf', exist_ok=True)
    filename = f"{TITLE.replace(' ', '_')}_v{VERSION}_{DATE}.pdf"
    filepath = f"output/pdf/{filename}"

    doc = SimpleDocTemplate(
        filepath,
        pagesize=A4,
        leftMargin=MARGIN,
        rightMargin=MARGIN,
        topMargin=MARGIN,
        bottomMargin=50,
    )

    styles = get_styles()
    story = []

    # === PAGE 1 is the cover (handled by on_cover_page) ===
    # Use NextPageTemplate to switch from cover to content layout
    story.append(PageBreak())  # Cover page content is drawn by on_cover_page callback

    # === DOCUMENT HISTORY ===
    story.append(Paragraph('Document History', styles['MSHeading2']))
    story.append(create_branded_table([
        ['Version', 'Date', 'Author', 'Changes'],
        [VERSION, DATE, AUTHOR, 'Initial version'],
    ]))
    story.append(Spacer(1, 20))

    # === EXECUTIVE SUMMARY ===
    story.append(PageBreak())
    story.append(Paragraph('Executive Summary', styles['MSHeading1']))
    story.append(Paragraph(
        'This document provides an overview of the project scope, objectives, '
        'and recommended approach. [Replace with 150-250 word summary.]',
        styles['MSBody']
    ))

    # === SECTION 1 ===
    story.append(Paragraph('1. Overview', styles['MSHeading1']))
    story.append(Paragraph(
        'Content for the overview section. Describe the context, background, '
        'and purpose of this document.',
        styles['MSBody']
    ))

    # Info callout
    story.append(Paragraph(
        '<b>Key Insight:</b> This is an informational callout box highlighting '
        'an important point for the reader.',
        styles['MSCalloutInfo']
    ))

    # === SECTION 2 WITH TABLE ===
    story.append(Paragraph('2. Analysis', styles['MSHeading1']))
    story.append(Paragraph(
        'The following table summarizes the key findings:',
        styles['MSBody']
    ))
    story.append(create_branded_table([
        ['Category', 'Current', 'Target', 'Gap', 'Status'],
        ['Performance', '75%', '95%', '20%', 'In Progress'],
        ['Security', '80%', '100%', '20%', 'At Risk'],
        ['Reliability', '99.5%', '99.9%', '0.4%', 'On Track'],
    ]))

    # === SECTION 3 ===
    story.append(Paragraph('3. Recommendations', styles['MSHeading1']))
    story.append(Paragraph(
        '1. First recommendation with rationale.<br/>'
        '2. Second recommendation with expected impact.<br/>'
        '3. Third recommendation with timeline.',
        styles['MSBody']
    ))

    # Warning callout
    story.append(Paragraph(
        '<b>Important:</b> All metrics cited in this document must include '
        'source references. No data has been fabricated.',
        styles['MSCalloutWarning']
    ))

    # === NEXT STEPS ===
    story.append(PageBreak())
    story.append(Paragraph('Next Steps', styles['MSHeading1']))
    story.append(create_branded_table([
        ['#', 'Action', 'Owner', 'Deadline'],
        ['1', 'Action item 1', 'Owner', 'Date'],
        ['2', 'Action item 2', 'Owner', 'Date'],
        ['3', 'Action item 3', 'Owner', 'Date'],
    ]))

    # === REFERENCES ===
    story.append(Spacer(1, 30))
    story.append(Paragraph('References', styles['MSHeading1']))
    story.append(Paragraph(
        '[1] Source URL — Description<br/>'
        '[2] Source URL — Description',
        styles['MSBody']
    ))

    # === BUILD ===
    doc.build(story, onFirstPage=on_cover_page, onLaterPages=on_content_page)
    print(f"Created: {filepath}")


if __name__ == '__main__':
    create_document()
