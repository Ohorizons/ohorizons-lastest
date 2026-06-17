# AI Impact Page

Dashboard that measures and visualizes the real impact of AI and Agentic DevOps on the SDLC. Connects to the AI Impact backend (`agent-api-impact` on port 8011) for live metrics and LLM-powered analysis.

## Features

- Hero banner with AI Impact Score
- KPI metric cards: Adoption, Productivity, Velocity, Quality
- Copilot adoption and seat utilization tracking
- Productivity metrics (acceptance rate, suggestions, hours saved, cost saved)
- Velocity metrics (merge time, deploy frequency, DORA classification)
- Quality metrics (change failure rate, vulnerabilities, risk level)
- On-demand LLM analysis with custom questions
- RAG insights history panel
- Markdown rendering for AI-generated analysis

## Screenshot Path

`/docs/assets/screenshots/ai-impact-page.png` (placeholder)

## Configuration

Requires the AI Impact proxy in `app-config.yaml`:

```yaml
proxy:
  endpoints:
    '/ai-impact':
      target: http://127.0.0.1:8011
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `@backstage/core-components` | `Page`, `Content` layout |
| `@material-ui/core` | UI components and icons |
| `react-markdown` | Render LLM analysis output |
| `../shared/HeroBanner` | Shared hero banner component |
| `../shared/StyledCard` | Shared card component |

## Usage

**Route:** `/ai-impact`

```text
Navigate to: Backstage → AI Impact
```
