---
name: pdf-creator
description: "Creates professional Microsoft-branded PDF documents with cover pages, tables, charts, headers, footers, executive formatting, and source-backed content. USE FOR: create PDF, generate pdf, build PDF report, Microsoft branded PDF, PDF proposal, PDF whitepaper, executive PDF, PDF with charts, PDF with tables. DO NOT USE FOR: Word documents (use docx-creator), presentations (use pptx-creator), Excel workbooks (use xlsx-creator), diagrams (use figjam-diagrams)."
---

# PDF Creator

Create professional Microsoft-branded PDF documents using Python and `reportlab`.

## When to Use

Use this skill for:

- Executive PDF reports.
- Technical whitepapers.
- Proposal documents.
- Workshop reports.
- PDF documents with tables or charts.

## Design Standards

- Use Segoe UI when available; fall back to Helvetica.
- Use Microsoft blue `#0078D4` for primary headings.
- Use the Microsoft 4-color palette as accents only.
- Keep pages clean, structured, and print-friendly.
- Include headers, footers, page numbers, and document metadata.

## Content Standards

- Write all content in English.
- Do not fabricate metrics, market data, ROI, or customer outcomes.
- Cite credible sources for every external claim.
- Include a `References` section for sourced reports.
- Avoid internal-only labels unless the user explicitly asks for an internal document.

## Recommended Structure

1. Cover page.
2. Executive summary.
3. Key findings.
4. Detailed sections.
5. Recommendations.
6. References.
7. Appendix, if needed.

## Quality Checklist

- [ ] Document is Microsoft-branded and enterprise-ready.
- [ ] Content is in English.
- [ ] Cover page includes title, subtitle, date, author, and version.
- [ ] Tables and charts are readable.
- [ ] Sources are cited.
- [ ] No confidential label is added unless explicitly requested.
