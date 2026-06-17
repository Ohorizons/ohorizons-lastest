---
name: xlsx-creator
description: "Creates professional Microsoft Excel (.xlsx) workbooks with dashboards, charts, connected tabs, conditional formatting, and Microsoft branding. USE FOR: create Excel, generate xlsx, build spreadsheet, dashboard Excel, KPI tracker, financial model, data tracker, project tracker, Microsoft branded Excel, create workbook with charts. DO NOT USE FOR: Word documents (use docx-creator), presentations (use pptx-creator), diagrams (use figjam-diagrams)."
---

# XLSX Creator

Create professional Microsoft-branded Excel workbooks (.xlsx) with dashboards, interactive charts, connected tabs, conditional formatting, and enterprise-grade structure using Python and openpyxl.

## Technology

All Excel files are generated using **Python 3 + openpyxl**. The agent writes a Python script, executes it, and delivers the `.xlsx` file.

### Required Package

```bash
pip install openpyxl
```

If not installed, the agent installs it automatically before generating.

## Branding Defaults

### Color Palette (Microsoft Brand)

| Element | Hex | RGB | openpyxl PatternFill |
|---------|-----|-----|---------------------|
| Header Blue | `#0078D4` | `(0, 120, 212)` | `PatternFill(start_color="0078D4", fill_type="solid")` |
| Header Text | `#FFFFFF` | `(255, 255, 255)` | `Font(color="FFFFFF", bold=True)` |
| Accent Red | `#F25022` | `(242, 80, 34)` | For negative values, risks |
| Accent Green | `#7FBA00` | `(127, 186, 0)` | For positive values, success |
| Accent Blue | `#00A4EF` | `(0, 164, 239)` | For info, links |
| Accent Yellow | `#FFB900` | `(255, 185, 0)` | For warnings, in-progress |
| Alt Row Light | `#F3F2F1` | `(243, 242, 241)` | Alternating row background |
| Alt Row White | `#FFFFFF` | `(255, 255, 255)` | Alternating row background |
| Border Gray | `#D2D0CE` | `(210, 208, 206)` | Table borders |
| Text Primary | `#323130` | `(50, 49, 48)` | Body text |
| Text Secondary | `#605E5C` | `(96, 94, 92)` | Captions, metadata |

### Fonts

| Element | Font | Size | Style |
|---------|------|------|-------|
| Workbook title | Segoe UI | 18pt | Bold |
| Sheet headers | Segoe UI | 11pt | Bold, White on Blue |
| Column headers | Segoe UI | 11pt | Bold, White on #0078D4 |
| Body text | Segoe UI | 10pt | Regular |
| KPI numbers | Segoe UI | 24pt | Bold |
| KPI labels | Segoe UI | 9pt | Regular, #605E5C |
| Footer/metadata | Segoe UI | 8pt | Italic, #605E5C |

## Workbook Structure

Every workbook MUST follow this multi-tab architecture:

### Tab 1: Dashboard (always first)

The summary view with KPIs, charts, and key metrics. Structure:

```
Row 1-2:    Title bar (merged cells, Microsoft Blue background, white text)
            "{{workbook_title}} — {{client_name}}"
            "v{{version}} | {{date}} | {{author_name}}"

Row 3:      Empty spacer

Row 4-7:    KPI Cards (4 cards side-by-side in columns B, D, F, H)
            Each card: Large number (24pt bold) + Label below (9pt gray)
            Background: light brand color tint
            Border: 2px brand color

Row 8:      Empty spacer

Row 9-25:   Chart area (2 charts side-by-side or stacked)
            Chart 1: Bar/Column chart (primary data)
            Chart 2: Line/Trend chart (progress over time)

Row 26:     Empty spacer

Row 27-35:  Summary table (top items from data tabs)
            Branded header row, alternating rows, conditional formatting

Row 36:     Footer: "Microsoft Confidential | Generated {{date}}"
```

### Tab 2-N: Data Tabs (domain-specific)

Each data tab contains the raw data that feeds the Dashboard:

```
Row 1:      Tab title (merged, blue background, white text)
Row 2:      Column headers (blue background, white bold text, filters enabled)
Row 3+:     Data rows (alternating colors, conditional formatting)
Last row:   Totals/Summary row (bold, light blue background)
```

### Tab N+1: Reference/Config (optional)

Dropdowns, lookup tables, and validation lists:

```
- Status values: Not Started, In Progress, Blocked, Done
- Priority values: Critical, High, Medium, Low
- Category values: (domain-specific)
```

## Workbook Types

| Type | Tabs | Dashboard KPIs | Charts |
|------|------|---------------|--------|
| **Project Tracker** | Dashboard, Tasks, Milestones, Risks, Config | Total tasks, % Complete, Overdue, Blocked | Gantt-style bar, Burndown line |
| **KPI Dashboard** | Dashboard, Metrics, Targets, History | 4 key metrics with targets | Gauge-style bars, Trend lines |
| **Financial Model** | Dashboard, Revenue, Costs, Projections | Revenue, Margin, Growth, Runway | Stacked bar (rev vs cost), Line (projection) |
| **Assessment Tracker** | Dashboard, Categories, Items, Scoring | Overall score, Categories assessed, Gaps, Recommendations | Radar/Spider, Heatmap table |
| **Resource Tracker** | Dashboard, Team, Allocation, Timeline | Headcount, Utilization %, Available, Cost | Stacked bar (allocation), Line (utilization) |
| **Engagement Tracker** | Dashboard, Activities, Deliverables, Timeline | Activities completed, Pending, Overdue, Satisfaction | Progress bars, Timeline |

## Formatting Rules

### Column Headers

```python
header_fill = PatternFill(start_color="0078D4", fill_type="solid")
header_font = Font(name="Segoe UI", size=11, bold=True, color="FFFFFF")
header_alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
header_border = Border(
    bottom=Side(style="medium", color="0078D4"),
    left=Side(style="thin", color="D2D0CE"),
    right=Side(style="thin", color="D2D0CE")
)
```

### Alternating Rows

```python
light_fill = PatternFill(start_color="F3F2F1", fill_type="solid")
white_fill = PatternFill(start_color="FFFFFF", fill_type="solid")
# Apply in loop: row % 2 == 0 gets light_fill
```

### Conditional Formatting

```python
# Status column: color-coded
from openpyxl.formatting.rule import CellIsRule

# Green for "Done"
ws.conditional_formatting.add('E3:E100',
    CellIsRule(operator='equal', formula=['"Done"'],
              fill=PatternFill(start_color="E8F5E9", fill_type="solid"),
              font=Font(color="107C10")))

# Red for "Blocked"
ws.conditional_formatting.add('E3:E100',
    CellIsRule(operator='equal', formula=['"Blocked"'],
              fill=PatternFill(start_color="FDEDED", fill_type="solid"),
              font=Font(color="E81123")))

# Yellow for "In Progress"
ws.conditional_formatting.add('E3:E100',
    CellIsRule(operator='equal', formula=['"In Progress"'],
              fill=PatternFill(start_color="FFF3E0", fill_type="solid"),
              font=Font(color="D83B01")))
```

### Number Formatting

| Data Type | Format | Example |
|-----------|--------|---------|
| Currency | `#,##0.00` | 1,234.56 |
| Percentage | `0.0%` | 85.5% |
| Date | `YYYY-MM-DD` | 2026-03-04 |
| Integer | `#,##0` | 1,234 |
| Score | `0.0` | 8.5 |

### Column Widths

```python
# Auto-width with minimum standards
ws.column_dimensions['A'].width = 5     # Row numbers
ws.column_dimensions['B'].width = 30    # Names/descriptions
ws.column_dimensions['C'].width = 15    # Status
ws.column_dimensions['D'].width = 12    # Dates
ws.column_dimensions['E'].width = 12    # Numbers
```

## Charts

### Bar Chart (Primary Data)

```python
from openpyxl.chart import BarChart, Reference

chart = BarChart()
chart.type = "col"
chart.style = 10
chart.title = "{{chart_title}}"
chart.y_axis.title = "{{y_axis}}"
chart.x_axis.title = "{{x_axis}}"
chart.width = 20
chart.height = 12

# Microsoft brand colors for series
from openpyxl.chart.series import DataPoint
chart.series[0].graphicalProperties.solidFill = "0078D4"
```

### Line Chart (Trends)

```python
from openpyxl.chart import LineChart

chart = LineChart()
chart.style = 10
chart.title = "{{trend_title}}"
chart.width = 20
chart.height = 12
chart.series[0].graphicalProperties.line.solidFill = "0078D4"
chart.series[0].smooth = True
```

### Pie Chart (Distribution)

```python
from openpyxl.chart import PieChart

chart = PieChart()
chart.title = "{{distribution_title}}"
chart.width = 15
chart.height = 12
# Custom colors: F25022, 7FBA00, 00A4EF, FFB900, 0078D4
```

## Data Validation

```python
from openpyxl.worksheet.datavalidation import DataValidation

# Status dropdown
status_val = DataValidation(
    type="list",
    formula1='"Not Started,In Progress,Blocked,Done"',
    allow_blank=True
)
status_val.prompt = "Select status"
status_val.promptTitle = "Status"
ws.add_data_validation(status_val)
status_val.add('E3:E100')

# Priority dropdown
priority_val = DataValidation(
    type="list",
    formula1='"Critical,High,Medium,Low"',
    allow_blank=True
)
ws.add_data_validation(priority_val)
priority_val.add('F3:F100')
```

## Cross-Tab Formulas

Dashboard cells reference data tabs using formulas:

```python
# Total tasks from Tasks tab
ws['B5'] = "=COUNTA(Tasks!B3:B100)"

# Completed percentage
ws['D5'] = '=COUNTIF(Tasks!E3:E100,"Done")/COUNTA(Tasks!B3:B100)'

# Overdue count
ws['F5'] = '=COUNTIFS(Tasks!D3:D100,"<"&TODAY(),Tasks!E3:E100,"<>Done")'

# SUM from financial tab
ws['B5'] = "=SUM(Revenue!D3:D100)"
```

## Print Setup

```python
ws.print_title_rows = '1:2'  # Repeat header rows when printing
ws.sheet_properties.pageSetUpPr = PrintPageSetup(fitToWidth=1)
ws.page_setup.orientation = 'landscape'
ws.page_setup.paperSize = ws.PAPERSIZE_A4
ws.page_margins = PageMargins(left=0.5, right=0.5, top=0.75, bottom=0.75)
ws.oddHeader.center.text = "{{workbook_title}} — {{client_name}}"
ws.oddFooter.center.text = "Page &P of &N | Confidential"
```

## Versioning and Archiving

- Filename: `{Title}_v{version}_{YYYY-MM-DD}.xlsx`
- Save to: `output/xlsx/`
- Archive previous: `output/xlsx/archive/`
- Metadata on Dashboard tab: version, date, author

## Freeze Panes and Filters

```python
# Freeze header row on data tabs
ws.freeze_panes = 'A3'

# Enable auto-filter on data tabs
ws.auto_filter.ref = f"A2:{get_column_letter(max_col)}{max_row}"
```

## Quality Checklist

- [ ] Dashboard is the first tab with KPI cards and charts
- [ ] All data tabs have branded headers (blue background, white text)
- [ ] Alternating row colors applied on all data tabs
- [ ] Conditional formatting on status/priority columns
- [ ] Column widths set (no truncated content)
- [ ] Number formats applied (currency, %, dates)
- [ ] Charts use Microsoft brand colors
- [ ] Cross-tab formulas connect Dashboard to data tabs
- [ ] Data validation dropdowns on status/priority columns
- [ ] Freeze panes and auto-filters enabled on data tabs
- [ ] Print setup configured (landscape, A4, headers/footers)
- [ ] No empty cells in header rows
- [ ] Footer with version, date, and confidentiality notice
- [ ] Filename follows `{Title}_v{version}_{date}.xlsx` pattern
- [ ] Saved to `output/xlsx/` with previous version archived
