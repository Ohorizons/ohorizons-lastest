---
title: "The Context Platform Stack: Integration Playbook"
description: "How the four layers integrate in practice, maturity model, model routing decisions, ten principles, and quick-start guides by persona"
author: "Open Horizons"
date: "2026-04-11"
version: "1.2.0"
status: "approved"
tags: ["playbook", "integration", "maturity-model", "model-routing", "SDLC", "enterprise", "quick-start"]
---

# Integration: The Practical Playbook


## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|--------|
| 1.2.0 | 2026-04-11 | Open Horizons | Enriched with paper-map research data: FeatureBench, OWASP security, AdaptOrch, Beyond the Commit, Enterprise AI requirements, Embedded Software practices, Agentic Reasoning survey |
| 1.1.0 | 2026-04-11 | Open Horizons | Voice rewrite: casual first-person, removed em dashes, added original reasoning |
| 1.0.0 | 2026-04-11 | Open Horizons | Initial version |

## Table of Contents

- [How the Four Layers Integrate](#how-the-four-layers-integrate)
- [The Agent Cemetery Anti-Pattern](#the-agent-cemetery-anti-pattern)
- [Enterprise Maturity Map](#enterprise-maturity-map)
- [Model Routing by SDLC Phase](#model-routing-by-sdlc-phase)
- [Topology Routing: Beyond Model Selection](#topology-routing-beyond-model-selection)
- [Security Across the Stack: OWASP + CWE Dual-Lens](#security-across-the-stack-owasp--cwe-dual-lens)
- [Measuring What Matters: Beyond DORA](#measuring-what-matters-beyond-dora)
- [Special Considerations: Embedded and Safety-Critical Systems](#special-considerations-embedded-and-safety-critical-systems)
- [The Ten Principles of the Context Platform Stack](#the-ten-principles-of-the-context-platform-stack)
- [Quick-Start by Persona](#quick-start-by-persona)
- [References](#references)

---

## How the Four Layers Integrate

The Context Platform Stack is not a sequential process. It is a dependency graph. Each layer serves the next layer above it; each layer constrains the one below. The flow is bidirectional.

![How the Four Layers Integrate](img_integration_flow.svg)

**Cloud and Infrastructure** provide compute, storage, and GPU capacity. This layer answers: where do agents run, and at what cost? Without discipline here, context and intent engineering are purely theoretical.

**Platform Engineering** layers governance on top of infrastructure. This layer provides internal developer platforms (IDPs), golden paths, RBAC, cost governance, and observability. It answers: what can agents do, and who can deploy them? The IDP is the container that makes agentic systems safe at scale.

**Context Engineering** layers cognition on top of the platform. ACE patterns, skill libraries, memory strategies, and MCP servers determine what agents know. This layer answers: what is the agent aware of? Knowledge determines capability.

**Intent Engineering** layers strategy on top of context. Specification, governance models, and intent artifacts determine what agents optimize for. This layer answers: what should the agent do? Without clear intent, even well-informed agents drift.

The dotted lines in the diagram show feedback loops. Intent constrains what context is needed. Context determines which platform capabilities matter. Platform capabilities constrain infrastructure decisions. These feedback loops are where most failures happen: engineers build infrastructure without understanding intent, or build context without governance, or build agents without specification.

---

## The Agent Cemetery Anti-Pattern

Every large enterprise I work with has one: a repository of abandoned agent prototypes. They shipped briefly. Executives got excited. Then they disappeared. This section exists to help you avoid it.

**Why it happens.** Agent development moves at startup velocity but enterprise adoption requires discipline velocity. The excitement of a working POC is real; the work of sustaining it is invisible. Early wins happen without CONSTITUTION.md, without AGENTS.md curation, without model routing discipline. Teams scale agents before they scale governance.

**Early warning signs.** You are heading toward the cemetery if: (1) agents have no SLOs, no DORA metrics, no daily KPI tracking; (2) no named owner responsible for the agent's evolution; (3) no golden path for deploying new agents; (4) context is maintained by one person; (5) intent drift goes undetected for more than two weeks.

**The benchmark reality.** FeatureBench (ICLR 2026) tested agents on feature-level tasks across 200 tasks and 3,825 executable environments. Claude Opus 4.5 achieves an 11.0% solve rate. The best model (Codex+GPT5.1) reaches 12.5%. For comparison, Claude Opus 4.5 achieves 74.4% on SWE-bench bug fixes. Feature-level tasks are roughly 7 times harder than bug fixes. This is the gap between what demos show and what production demands. If your agent POC only demonstrates bug fixes, you are operating in the easy 74% zone and ignoring the hard 11% zone where real feature work lives.

**The typical failure arc.** Specification is vague but fast. A POC agent ships in four weeks and works on the demo. Executives see it and push for rollout. Engineering scales it to three teams without defining golden paths or RBAC. The context layer grows unmaintained. Skills are duplicated, memory strategies conflict, MCP servers are reimplemented. After six months, the agent costs three times the original estimate and delivers 60% of the promised value. A new executive initiative arrives. The team moves on. The agent becomes a line item in "technical debt."

The antidote is not better tooling. It is discipline earlier. Define CONSTITUTION.md before the first agent ships. Measure intent drift and cognitive debt before they compound. Make model routing decisions explicit, not implicit. Without these, infrastructure and platform improvements will not save you.

---

## Enterprise Maturity Map

Maturity is not about having agents. It is about having governance that scales agents. Use this table to locate your organization and plan the next phase.

| Stage | Description | Indicators | Next Step |
|-------|------------|------------|-----------|
| 0. Chaos | Agents without strategy | No metrics, no owner, no spec discipline | Define CONSTITUTION.md; assign ownership |
| 1. Aware | Has platform, no agents | IDP exists, DORA measured, but no AI workload support | Add MCP server registry to IDP; enable agent personas in RBAC |
| 2. Emerging | Agents in pilot | 1–3 agents in production, proof-of-value clear | Create golden path for agent deployment; define AGENTS.md curation process |
| 3. Structured | Context codified | AGENTS.md maintained, skills versioned, hooks instrumented | Implement full SDD; add cost governance per agent; instrument intent drift metrics |
| 4. Intent-Driven | All layers active | Intent artifacts in every project, agent RBAC enforced, observability covers trajectories | Autonomous infrastructure; agents optimize for enterprise goals, not local KPIs |

**How to read this table.** Your stage is determined by your limiting factor, not your best practice. If you have DORA metrics but no AGENTS.md curation, you are at stage 1. If you have 50 agents but no intent metrics, you are at stage 2. Maturity is the minimum of all four layers.

**Progression takes time.** Moving from stage 0 to stage 1 typically takes one quarter and requires platform engineering investment. Stages 1–2 can overlap; stage 2–3 takes two quarters because context codification is discipline-intensive. Stages 3–4 require intent engineering, which is new for most teams; plan one to two quarters.

---

## Model Routing by SDLC Phase

Model choice is not global. It is task-specific and phase-specific. This table encodes the discipline that separates sustainable agent systems from the agent cemetery.

| SDLC Phase | Task Type | VS Code Mode | Agent/Primitive | Model | Extended Thinking | Cost Tier |
|-----------|-----------|-------------|-----------------|-------|-------------------|-----------|
| Specification | Vague requirements | Ask | Planner + /spec | Opus 4.6 | Yes | High (intentional) |
| Architecture | Planning >5 files | Ask | Planner agent | Opus 4.6 | Yes | High (intentional) |
| TDD Spec | Test cases from clear spec | Edit | /tdd prompt | Sonnet 4.6 | No | Medium |
| Implementation | Docstring, commit msg | Ask | Direct | Haiku 4.5 | No | Low |
| Implementation | Feature 3–10 files | Agent | Implementer + hooks | Sonnet 4.6 | No | Medium |
| Code Review | Quality + security | Ask | Reviewer (read-only) | Opus 4.6 | Yes | High |
| Summarization | PR description, changelog | Ask | Direct | Haiku 4.5 | No | Low |

**Why this routing matters.** Extended thinking costs 43% more and degrades quality by 30% on iterative implementation tasks, making it counterproductive for coding in tight loops (arXiv:2502.08235). Opus is necessary for specification and architecture because these require decomposition under uncertainty. Haiku is sufficient for well-defined tasks like docstring generation. Using Opus for every task is both wasteful and suboptimal.

**Reading the table.** The "Mode" column indicates how Claude Code operates: Ask mode waits for user input between steps; Agent mode runs autonomously. The "Cost Tier" column reflects both model cost and extended thinking expense. "High (intentional)" means the high cost is justified because specification and review require cognitive depth.

**Applying this in practice.** Create a .cursorrules file in your project that documents this routing. When a developer says "I need an agent to implement this feature," ask: Is the feature spec clear? If no, route to Opus + planner + Ask mode. If yes, route to Sonnet + implementer + Agent mode. If the developer disagrees, that is usually a sign the spec is not clear enough.

---

## Topology Routing: Beyond Model Selection

Model routing is necessary but not sufficient. AdaptOrch (Korea National Open University, 2026) demonstrated that as models converge in performance, orchestration topology becomes the dominant factor in multi-agent system quality. Their Performance Convergence Scaling Law formalizes this: the better the models get, the more the topology matters.

Four topologies, each optimal for different task types: **parallel** (independent subtasks like test generation), **sequential** (dependent steps like spec-then-implement), **hierarchical** (complex decomposition like feature development), and **hybrid** (mixed workloads). A linear-time Topology Routing Algorithm selects the right topology based on task characteristics, achieving 12 to 23% improvement over static baselines on SWE-bench, GPQA, and RAG benchmarks (arXiv:2602.16873).

For the Context Platform Stack, this means: use hierarchical topology for spec-to-implementation workflows. Use parallel topology for test generation. Use sequential topology for review pipelines. Don't default to a single topology for all tasks.

The Agentic Reasoning Survey (UIUC, Meta, Amazon, DeepMind, Yale) provides the theoretical framework: three layers of reasoning (arXiv:2601.12538). Foundational (planning, tool use, search). Self-evolving (feedback, memory, adaptation). Collective multi-agent (role assigning, collaboration, co-evolving). Each layer maps to different primitives: foundational = prompts and tools, self-evolving = hooks and memory, collective = orchestration topology. Understanding which layer your task requires determines which primitives to invest in.

---

## Security Across the Stack: OWASP + CWE Dual-Lens

Security in agentic systems requires a dual-lens approach that maps to OWASP LLM Top 10 and CWE categories simultaneously. An analysis of 295 GitHub Security Advisories (January 2025 to January 2026) found three dominant threat categories: Supply Chain attacks at 44%, Excessive Agency at 20%, and Prompt Injection at 18% (arXiv:2604.04288). The CWE perspective adds specificity: Code Injection (CWE-94), Command Injection (CWE-77/78), and Deserialization (CWE-502) are the most exploited vulnerabilities. 37% of advisories carry multiple labels, and the combination of LLM03 (Training Data Poisoning) with LLM06 (Excessive Agency) co-occurs 12 times more frequently than expected.

For security teams implementing the Context Platform Stack: include an OWASP LLM Top 10 checklist in every CONSTITUTION.md. Limit agent permissions by default (addressing Excessive Agency). Validate all MCP server inputs (addressing Prompt Injection). Audit the supply chain of every skill and plugin you install (addressing Supply Chain).

---

## Measuring What Matters: Beyond DORA

Traditional productivity frameworks (SPACE, DORA) are insufficient for the era of AI-assisted development. A study of 2,989 developers and 11 in-depth interviews at BNY Mellon and CMU identified six dimensions of productivity with AI that these frameworks miss (arXiv:2602.03593): self-sufficiency, frustration and cognitive load, task completion, peer review quality, technical expertise development, and code ownership.

Long-term factors are systematically undervalued. Teams measuring only velocity and throughput miss the erosion of technical expertise, the increase in cognitive load, and the degradation of code ownership that AI tools can cause. For the Context Platform Stack, this means your maturity map (stage 0 through 4) should track these six dimensions, not just DORA metrics.

IBM Research found that trust and quality are the central enterprise requirements for AI coding assistants (arXiv:2601.20112). Novices benefit more than experts. Quality assurance is the largest gap. For enterprise deployments in LATAM (where regulatory requirements are often stringent), this means: invest in quality gates before investing in agent capabilities. The platform that enterprises will trust is the one that demonstrates quality, not the one that demonstrates speed.

---

## Special Considerations: Embedded and Safety-Critical Systems

Not all systems have the same tolerance for agent autonomy. A study of 10 senior embedded software engineers across 4 companies identified 11 emerging practices and 14 challenges specific to agentic pipelines in embedded contexts (arXiv:2601.10220). The non-negotiable requirements are determinism, reliability, and traceability. Agent output must be bit-for-bit reproducible. Every decision must be traceable to a specification. Failures must be recoverable.

Two practices stood out as critical: human-in-the-loop supervision (agents propose, humans approve, for every production change) and compiler-in-the-loop feedback (using the compiler as a verifier, similar to TerraFormer's approach with `terraform plan`).

For LATAM enterprises with embedded or safety-critical workloads (automotive, medical devices, industrial control), the Context Platform Stack applies with one modification: the human review gate in the SDD workflow is not optional. Ever. The maturity map stage 4 ("agents optimize for enterprise goals") does not apply to safety-critical systems. Stage 3 ("context codified, intent measured") is the ceiling, and the human gate remains permanent.

---

## The Ten Principles of the Context Platform Stack

These principles synthesize the book for C-level and technology leadership. Use them to evaluate decisions, prioritize investments, and communicate trade-offs.

**1. Agentic infrastructure is not infrastructure with AI bolted on. It requires deliberate architecture.** Many organizations treat agents as an application layer problem. This fails. Agentic systems require changes to cloud strategy (GPU allocation, multi-region latency), platform strategy (golden paths for AI workloads, cost governance per agent), and observability (trajectory logging, intent drift detection). If your IDP does not have a section on agents, you are not ready to scale them.

**2. Platform engineering is the context governance layer, not just DevOps with AI.** The IDP is where intent becomes policy. RBAC for agents is not a security feature; it is a specification compliance feature. Golden paths are not convenience; they are the codification of acceptable agent behavior. Without platform discipline, context engineering becomes a free-for-all and intent drift accelerates.

**3. Context engineering is the cognition layer. What the agent knows determines what it can do.** A well-specified agent with poor context will fail at harder tasks. A poorly-specified agent with rich context will drift. Context (skills, memory, MCP servers, retrieval) is the layer where engineering rigor translates into capability. Underinvesting here is the most common path to the agent cemetery.

**4. Intent engineering is the strategic layer. Without it, well-contextualized agents optimize for the wrong things.** An agent that is well-informed and autonomous can cause more damage than a poorly-informed one. Intent artifacts (CONSTITUTION.md, SDD, goal hierarchies) are not bureaucracy; they are safety rails. Scaling agents without intent discipline is like scaling production services without SLOs.

**5. MCP is not a product. It is a protocol. Differentiate above the protocol layer.** Most vendors will commoditize MCP servers. Your competitive advantage is not in implementing the MCP spec; it is in the skills you encode, the memory strategies you adopt, the governance discipline you enforce. Invest in context engineering, not in MCP server implementation.

**6. Cognitive debt and intent debt are invisible but compound. Measure them before they become critical.** You can quantify cognitive debt: untested skills, stale memory, duplicated context. You can quantify intent drift: agent decisions that violate CONSTITUTION.md or violate domain guardrails. Most teams measure neither. By the time these become visible, remediation costs 10x more (arXiv:2603.22106). Define observability before you define agents.

**7. LLM choice is first-order; framework choice is second-order.** Choosing between Opus and Sonnet affects task quality more than choosing between two frameworks. Choose models for the task (specification vs. implementation). Choose frameworks for compatibility with your platform. Too many teams invert this order, obsessing over framework choice while making poor model decisions.

**8. Extended thinking costs 43% more and degrades quality by 30% on iterative implementation tasks. Route correctly.** This is a specific, measurable principle. If your SDLC routing does not reflect it, your cost will compound faster than your quality improves (arXiv:2502.08235). This is the highest-ROI routing decision to get right.

**9. LLM-generated AGENTS.md is counterproductive. Only human curation helps.** Agents that curate themselves tend toward false certainty and task creep. Agents that are human-curated tend toward humility and scope discipline. Your AGENTS.md is a contract between intent and context; contracts require human review (arXiv:2601.20404). Budget two to three hours per week per ten-agent portfolio for curation.

**10. You cannot govern what you cannot measure. Define intent metrics before scaling agents.** If you have no way to detect that an agent has drifted from its intent, you have no way to prevent the drift. Define metrics (e.g., "agent decisions violate CONSTITUTION.md in <0.1% of cases") before the agent ships, not after. This is the discipline that separates stage 3 from stage 2.

---

## Quick-Start by Persona

### For CTO / VP Engineering

**Your approval decision checklist.** Do not approve an agent initiative without answers to these five questions:

1. **Has CONSTITUTION.md been written?** This is not optional. If a team cannot articulate the agent's scope and constraints in writing, they do not understand them. This takes four to eight hours and pays for itself in the first week of operation.

2. **Is ownership clear and named?** One person owns the agent's evolution. This person is responsible for SLOs, for intent drift detection, for AGENTS.md curation. Without named ownership, the agent becomes orphaned within three months.

3. **Are SLOs defined?** At minimum: latency, cost per task, intent drift rate, and skill uptime. If you cannot measure it, you cannot govern it. SLO definitions take one to two days; they clarify thinking more than they clarify monitoring.

4. **Is there a golden path for the next agent?** If the first agent required custom work, the second will require two times the work and the third will fail. Invest in golden paths early. This pays for itself by agent three.

5. **Is cost governance in place?** Know the cost per agent, per task, per month. Route correctly (principle 8). Without cost governance, agent costs will exceed agent value within six months.

**What to measure.** Add these to your quarterly business reviews:

- **DORA metrics for agents** (deployment frequency, lead time, MTTR, change failure rate, but applied to agent rollouts, not just infrastructure)
- **Intent drift rate** (percentage of agent decisions that violate CONSTITUTION.md; target <0.1%)
- **Cognitive debt inventory** (untested skills, stale memory, duplicated context; should decrease each quarter)
- **Agent ROI** (business value delivered / total cost of ownership; should be >3:1 for production agents)

**When to say no.** Do not approve: (1) agents without CONSTITUTION.md; (2) attempts to scale agents without golden paths; (3) agents with no named owner; (4) agents that are intended to be autonomous without observability in place; (5) agent initiatives that cannot articulate success metrics before launch.

### For Platform Engineering Lead

**Your implementation sequence.** This is the order that minimizes rework:

1. **Build a service catalog.** Document all services, APIs, databases, and tools that agents might need to access. This becomes your context layer. Most platform teams already have this; just make sure it is accessible to agents.

2. **Create golden paths for AI workloads.** A golden path is a templated project structure that teams can fork to start a new agent. Include: CONSTITUTION.md template, SPECIFICATION.md template, IMPLEMENTATION_PLAN.md template, observability hooks, cost tracking, RBAC configuration. This takes three to four weeks and saves teams two to three weeks per agent.

3. **Build an MCP server registry.** Document which MCP servers are available, what they do, who maintains them, and SLAs. Make it easy for developers to find and use existing servers instead of building new ones. This is a spreadsheet at first; automate later.

4. **Implement agent RBAC.** Define agent personas (viewer, contributor, deployer, owner). Map these to the IDP. Test RBAC enforcement before agents are running at scale. This takes two weeks and prevents more problems than it creates.

5. **Add observability for agent trajectories.** Log each step of agent reasoning, not just inputs and outputs. This is where you detect intent drift early. Use spans and events, not just logs. This takes three to four weeks and is the highest-ROI security investment.

6. **Implement cost governance per agent.** Tag all cloud resources used by agents. Create dashboards that show cost per agent, per model, per task type. Set alarms at 80% of quarterly budget. This is boring and unglamorous and the most important thing you can do.

**Quick wins.** If you have a week, do these three things: (1) expose your existing platform capabilities via MCP servers (credentials, service catalog, deployment APIs); (2) add agent personas to your RBAC system; (3) instrument one existing agent with trajectory logging. These three things unblock 80% of the work of the next quarter.

### For AI-Native Developer

**Your daily work ritual.** This is the discipline that prevents drift:

1. **Start with CONSTITUTION.md.** Before any code, write the constitution. What is this agent allowed to do? What is it forbidden to do? What are its constraints? What are its success metrics? This is a one to two page document. It takes two to four hours and clarifies more than design reviews.

2. **Write SPECIFICATION.md.** Use Ask mode (Opus) with extended thinking to decompose requirements. This is not pseudo-code; it is English prose that describes what the agent will do in concrete terms. Include failure modes. Include examples of acceptable and unacceptable behavior. This takes four to eight hours and is where most teams skip steps.

3. **Create IMPLEMENTATION_PLAN.md.** Map the spec to code structure. Identify which libraries you will use, which skills you will need, which memory patterns apply. This is your contract with the implementation phase. It takes two to four hours and prevents implementation thrashing.

4. **Implement in Agent mode.** Use Sonnet with the Implementer agent for features >three files. Use direct prompts (Haiku) for docstrings and commit messages. Never use Opus for iterative coding; it is wasteful. Let the agent work autonomously within the IMPLEMENTATION_PLAN. Review the code, not the reasoning.

5. **Curate AGENTS.md weekly.** Spend one to two hours per week reviewing which skills your agent actually uses, which memory patterns are stale, what context is missing. This is not automated. Only humans can judge whether a skill is genuinely useful or whether it is cruft. This is where principle 9 applies.

**When you are stuck.** (1) Reread CONSTITUTION.md; you have drifted from intent. (2) Check AGENTS.md; you are using the wrong skill or memory pattern. (3) Route to Ask mode (Opus) to replan; you have hit a specification gap. Implement your way out of problems, not planning your way out.

### For Security / Compliance

**MCP security framework.** MCP servers introduce three attack surfaces:

1. **Tool poisoning.** An MCP server that claims to do one thing but does another. Mitigate: sign all MCP servers with a trusted key; implement a registry of approved servers; audit server implementations quarterly (arXiv:2504.08623).

2. **Rug pull attacks.** An MCP server that stops functioning or reverses behavior in production. Mitigate: implement health checks; require SLAs from server maintainers; have fallback servers for critical operations.

3. **Server impersonation.** An unauthorized service that claims to be an approved MCP server. Mitigate: enforce TLS certificate validation; require mutual authentication between agent and server; log all server interactions (arXiv:2503.23278).

**Agent RBAC.** Implement the five agent personas (viewer, contributor, deployer, owner, security) in your identity system. Enforce: (1) only owners can change CONSTITUTION.md; (2) only deployers can promote agents to production; (3) only security can approve new MCP servers; (4) all decisions are auditable. This is not optional for agents handling sensitive data.

**Audit trails.** Every agent trajectory must be logged with: (1) timestamp; (2) user who triggered the agent (if applicable); (3) intent (what was the agent asked to do); (4) trajectory (what did the agent actually do); (5) outcome (success or failure); (6) cost (for chargeback). Retention: minimum 90 days for critical agents, 30 days for others.

**Policy-as-Code for AI workloads.** Codify: (1) approved models (e.g., "no closed-source models for sensitive data"); (2) approved MCP servers (whitelist); (3) cost limits per agent; (4) data classification rules (what data agents are allowed to access). Review these policies quarterly. This is where compliance becomes engineering, not process.

---

## References

- arXiv:2502.08235. Extended Thinking Cost Analysis.
- arXiv:2603.22106. Storey (2026). Cognitive Debt: Measurement and Remediation.
- arXiv:2601.20404. LLM Self-Curation in Agent Repositories.
- arXiv:2604.02547. Model Choice vs. Framework Choice in Agentic Systems.
- arXiv:2504.08623. MCP Security: Tool Poisoning and Attestation.
- arXiv:2503.23278. MCP Threat Model: Impersonation, Man-in-the-Middle, and Rug Pulls.
- arXiv:2602.16873. AdaptOrch: Task-Adaptive Multi-Agent Orchestration. Korea National Open University.
- arXiv:2601.12538. Agentic Reasoning Survey. UIUC/Meta/Amazon/DeepMind/Yale.
- arXiv:2604.04288. LLM-Enabled OSS Vulnerabilities in GitHub Security Advisories. Missouri S&T + Nebraska.
- arXiv:2602.03593. Beyond the Commit: 6 Dimensions of AI Productivity. BNY Mellon + CMU.
- arXiv:2601.20112. Enterprise AI Coding Requirements. IBM Research.
- arXiv:2601.10220. Agentic Pipelines in Embedded Software. Chalmers.
- 495_featurebench. FeatureBench: Feature-Level Agentic Coding. Chinese Academy of Sciences + Huawei. ICLR 2026.

---

*This playbook is the capstone of "The Context Platform Stack." Use it as a reference when building enterprise agentic systems. The ten principles and quick-start guides are designed to be shared with leaders and teams. Maturity is a discipline, not a feature.*
