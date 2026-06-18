# Architecture Decision Records

Architecture Decision Records (ADRs) capture the significant decisions behind the Open Horizons platform: the context, the options considered, the decision, and its consequences.

| ADR | Title | Status |
| --- | --- | --- |
| [ADR-0001](0001-context-platform-stack-layers.md) | Five-layer Context Platform Stack | Accepted |
| [ADR-0002](0002-foundry-agents-gateway-l6-harness.md) | Foundry agents gateway as the L6 harness service | Accepted |
| [ADR-0003](0003-backstage-oss-not-rhdh.md) | Backstage OSS and ai-chat instead of RHDH and Lightspeed | Accepted |
| [ADR-0004](0004-memory-and-cache-backends.md) | Cosmos DB for enterprise memory, Redis for semantic cache | Accepted |
| [ADR-0005](0005-foundry-resources-gated-to-h3.md) | Foundry resources gated to the H3 Horizon | Accepted |

## Conventions

- One decision per file, named `NNNN-short-title.md`.
- Status is one of Proposed, Accepted, Superseded, or Deprecated.
- Superseding ADRs link back to the record they replace.
- Keep each record short: context, decision, consequences.
