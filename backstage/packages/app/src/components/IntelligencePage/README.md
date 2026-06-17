# Intelligence Page

Agentic Operations center showcasing the platform's autonomous AI agents. Provides access to AI Chat and Platform Graph, displays agent status with load metrics, and shows real-time neural telemetry.

## Features

- **HeroBanner** — Stats: 7 Active Agents, 1.2k Nodes, 14ms Latency, 99.9% Accuracy
- **Agentic Capabilities Grid** — 7 agent cards in a 4-column layout:
  - **AI Chat** → `/ai-chat` — Conversational agent for infrastructure and workflows
  - **Platform Graph** → `/catalog-graph` — Service dependency visualization
  - **Orchestrator** — Pipeline orchestration and deployment coordination (demo)
  - **Sentinel** — Security monitoring and policy enforcement (demo)
  - **Guardian** — CVE scanning, secret leak detection via GHAS
  - **Lighthouse** — Observability and SRE monitoring
  - **Forge** — Infrastructure and cloud resource management
- **Agent Status Panel** — 7 agents with load percentage bars (Compass, Pipeline, Sentinel, Guardian, Lighthouse, Forge, Orchestrator)
- **Neural Telemetry** — Real-time metrics: Avg Latency (14ms), Throughput (2.4k/s), Model Accuracy (99.9%), Memory Usage (4.2GB)
- **Coming Soon badges** — Disabled launch buttons for agents not yet linked

## Screenshot Path

`/docs/assets/screenshots/intelligence-page.png` (placeholder)

## Configuration

No additional configuration required. Agent status and telemetry data is currently static/demo data.

## Dependencies

- `@backstage/core-components` — Page, Content
- `@material-ui/core` — Chip, LinearProgress
- `@material-ui/icons` — Various agent and metric icons
- `react-router-dom` — RouterLink for tool navigation
- `../shared/HeroBanner` — Hero banner component
- `../shared/StyledCard` — Styled card component

## Usage

**Route:** `/intelligence`

Access via the Backstage sidebar or navigate directly to `/intelligence`.
