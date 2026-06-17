---
name: pptx-creator
description: "Creates professional Microsoft PowerPoint (.pptx) presentations with Microsoft branding, 16:9 format, 10-slide structure, and executive-grade content. USE FOR: create PowerPoint, generate pptx, build presentation, Microsoft branded slides, executive deck, technical presentation. DO NOT USE FOR: diagrams (use figjam-diagrams), Word documents (use docx-creator)."
---

# PPTX Creator

Create professional Microsoft-branded PowerPoint presentations (.pptx).

## Branding Defaults

| Element | Value |
|---------|-------|
| Theme | Microsoft (white background) |
| Dimensions | 16:9 widescreen |
| Primary Color | #0078D4 (Microsoft Blue) |
| Accent Colors | #F25022, #7FBA00, #00A4EF, #FFB900 |
| Font (titles) | Segoe UI Semibold, 28-36pt |
| Font (body) | Segoe UI, 16-20pt |
| Font (small text) | Segoe UI, 12pt |
| Slide count | Always exactly 10 slides |

## The 10-Slide Structure (MANDATORY)

| # | Slide Type | Content |
|---|-----------|---------|
| 1 | **Executive Cover** | Title, subtitle, logos, date |
| 2 | **Agenda / Overview** | What we'll cover (5-7 bullets max) |
| 3 | **Context / Challenge** | Problem statement, market data, pain points |
| 4 | **Solution Overview** | High-level approach, architecture diagram |
| 5 | **Deep Dive 1** | Technical detail, component breakdown |
| 6 | **Deep Dive 2** | Integration, data flow, or process detail |
| 7 | **Demo / Visual** | Screenshots, architecture diagram, live flow |
| 8 | **Benefits / Value** | ROI, metrics, comparison table |
| 9 | **Timeline / Roadmap** | Phases, milestones, delivery dates |
| 10 | **Next Steps / CTA** | Action items, contacts, follow-up |

## Design Rules

- **Max 6 bullets per slide** — if more, split into 2 slides
- **One key message per slide** — what should the audience remember?
- **Use visuals** — diagrams, icons, charts over text
- **Consistent alignment** — left-aligned text, centered diagrams
- **Color coding** — use 4-color palette to differentiate categories
- **No clip art** — use clean icons or AI-generated illustrations
- **Speaker notes** — add detailed notes for each slide

## Content Quality

- Every slide has a clear title that communicates the key takeaway
- Data claims have source citations with hyperlinks
- Technical slides include architecture diagrams
- Comparison slides use tables, not paragraphs
- Roadmap slides use timeline visuals, not bullet lists

## Factual Integrity

- NEVER fabricate metrics, KPIs, ROI figures, market data, or statistics
- Only use data from: workspace context, user-provided materials, or credible official sources
- Credible sources: Gartner, Forrester, IDC, McKinsey, Microsoft Learn, IEEE, ACM, HBR, official vendor docs
- Also valid: Microsoft Blog, GitHub Blog, Anthropic Blog/Engineering, GitHub Docs, Azure Architecture Center, Microsoft Tech Community, official product release notes
- Every metric or market claim on a slide MUST have a source citation in the speaker notes with hyperlink
- If no credible source exists, state as assumption or omit entirely
- Slide 10 (Next Steps) should include a "Sources" footnote listing all cited references

## Versioning & Archiving

- Every presentation MUST display: **date**, **version** (semver), and **author** on the cover slide (Slide 1) and in the footer of every slide
- Filename pattern: `{Title}_v{version}_{YYYY-MM-DD}.pptx`
- Save to: `output/pptx/`
- Before overwriting an existing file, move the previous version to `output/pptx/archive/`
- Slide 1 cover must show: title, subtitle, author, date, version

## Quality Checklist

- [ ] Exactly 10 slides
- [ ] 16:9 format
- [ ] Microsoft branding colors applied
- [ ] Segoe UI font throughout
- [ ] No slide has more than 6 bullet points
- [ ] Every slide has speaker notes
- [ ] Cover slide has date, author, version, and subtitle
- [ ] Final slide has clear next steps
- [ ] No fabricated data — all metrics have source citations in speaker notes
- [ ] Sources listed on final slide or in appendix
- [ ] Filename follows `{Title}_v{version}_{date}.pptx` pattern
- [ ] Saved to `output/pptx/` with previous version archived
