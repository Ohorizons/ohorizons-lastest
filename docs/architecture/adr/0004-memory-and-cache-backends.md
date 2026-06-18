# ADR-0004: Cosmos DB for enterprise memory, Redis for semantic cache

- Status: Accepted
- Date: 2026-06-18
- Deciders: Platform architecture, Data

## Context

The L6 harness needs two distinct stateful backends: a low-latency semantic prompt cache to avoid repeated inference, and a durable enterprise memory store for cold, cross-session agent context. These have different access patterns, durability needs, and consistency requirements.

The repository already provisions Azure Cache for Redis in the databases module and PostgreSQL with the option for pgvector. Azure Cosmos DB was present only in the extra-large sizing profile.

## Decision

Use **Azure Cache for Redis** as the semantic prompt cache backend and **Azure Cosmos DB** as the enterprise memory store.

The Cosmos account uses AAD-only authentication (local authentication disabled) so the gateway authenticates with Workload Identity and never holds keys. It is serverless with a throughput ceiling, uses session consistency by default, and is provisioned only when the H3 foundry agents configuration enables `cosmos_memory`.

## Consequences

- Cache and memory scale and fail independently, matching their different roles.
- AAD-only Cosmos removes connection-string secrets from the cluster.
- The semantic cache requires a Redis tier with vector search for the semantic tier; the exact-match tier works on standard Redis. Sizing profiles flag the semantic tier accordingly.
- Cosmos is gated to H3 so H1 and H2 deployments incur no Cosmos cost.
- PostgreSQL with pgvector remains available for embedding storage where a relational store is preferred; this ADR does not remove that option.
