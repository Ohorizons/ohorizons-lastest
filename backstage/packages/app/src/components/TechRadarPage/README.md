# Tech Radar Page

Organization-wide technology radar visualizing technology adoption status. Displays technologies across quadrants (Languages, Infrastructure, Tools, Frameworks) with adoption rings (Adopt, Trial, Assess, Hold).

## Features

- Hero banner with technology landscape summary
- Interactive SVG radar visualization with quadrant layout
- Quadrant filter buttons (All, Languages, Infrastructure, Tools, Frameworks)
- Adoption ring classification: Adopt, Trial, Assess, Hold
- Technology detail table with descriptions and ring status
- Color-coded chips for adoption status
- Static data derived from golden-paths templates and platform stack
- Responsive layout with Recharts-free custom SVG rendering

## Screenshot Path

`/docs/assets/screenshots/tech-radar-page.png` (placeholder)

## Configuration

No additional configuration required. Technology entries are defined as static data within the component.

To update the radar, edit the technology entries in `TechRadarPage.tsx`.

## Dependencies

| Package | Purpose |
|---------|---------|
| `@backstage/core-components` | `Page`, `Content` layout |
| `@material-ui/core` | UI components, icons, table |
| `../shared/HeroBanner` | Shared hero banner component |
| `../shared/StyledCard` | Shared card component |

## Usage

**Route:** `/tech-radar`

```text
Navigate to: Backstage → Tech Radar
```
