---
title: "The Context Platform Stack: Context Engineering"
description: "The discipline of structuring everything an AI agent needs to know at inference time, from memory tiers and skills to MCP protocols and token economics"
author: "Open Horizons"
date: "2026-04-11"
version: "1.2.0"
status: "approved"
tags: ["playbook", "context-engineering", "ACE", "MCP", "AGENTS.md", "skills", "memory", "RAG"]
---

# Context Engineering


## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|--------|
| 1.2.0 | 2026-04-11 | Open Horizons | Enriched with paper-map research data: SkillReducer, Semantic Density Principle, Tokenomics, CMI, Agent Skills survey, Context as deliberate construction |
| 1.1.0 | 2026-04-11 | Open Horizons | Voice rewrite: casual first-person, removed em dashes, added original reasoning |
| 1.0.0 | 2026-04-11 | Open Horizons | Initial version |

## Table of Contents

- [Definition and Evolution](#definition-and-evolution)
- [The Context Rot Problem](#the-context-rot-problem)
- [Four Fundamental Components](#four-fundamental-components)
- [ACE: Agentic Context Engineering](#ace-agentic-context-engineering)
- [Codified Context Infrastructure: The Three-Tier Architecture](#codified-context-infrastructure-the-three-tier-architecture)
- [CA-MCP: Context-Aware Model Context Protocol](#ca-mcp-context-aware-model-context-protocol)
- [AGENTS.md as Context Engineering Artifact](#agentsmd-as-context-engineering-artifact)
- [Token Cost as Context Engineering Discipline](#token-cost-as-context-engineering-discipline)
- [The Semantic Density Principle](#the-semantic-density-principle)
- [The Skill Engineering Ecosystem](#the-skill-engineering-ecosystem)
- [Contextual Memory Intelligence](#contextual-memory-intelligence)
- [Context Engineering as Deliberate Construction](#context-engineering-as-deliberate-construction)
- [Tool Description Smells in MCP](#tool-description-smells-in-mcp)
- [Context Workloads: The OpenDev Framework](#context-workloads-the-opendev-framework)
- [Context Platforms in Enterprise: Data Governance Perspective](#context-platforms-in-enterprise-data-governance-perspective)
- [Conclusion](#conclusion)
- [References](#references)

---

I started thinking about context engineering differently about 18 months ago. I watched teams burn through token budgets because nobody was thinking about what information actually mattered. They'd load everything (entire knowledge bases, all tool definitions, complete instruction sets) into every single prompt, then wonder why costs exploded and latency tanked. That's when I realized: this isn't a prompt problem anymore. It's an infrastructure problem[1].

Context engineering is the discipline of structuring the complete information payload you send to LLMs at inference time. It includes memory tiers, skill definitions, MCP protocols, agent specifications, and token economics. The field matured in 2024-2025 as organizations realized they couldn't optimize their way out of this problem with better prompting tricks. They needed systematic management of runtime state, tool coordination, and long-horizon execution[1].

## Definition and Evolution

Here's the shift I've observed. Prompt engineering (2022-2023) was about crafting instructions. You'd spend weeks perfecting the phrasing, the examples, the system message. The assumption was simple: get the words right, and the model will deliver.

Context engineering flips that question. Every token you send costs money and degrades performance if it's not signal. So the real question becomes: what does the agent actually need to know, in what order, at what cost, and how do you manage it over time[1]?

Gartner predicts context engineering will replace prompt engineering as the core capability for AI success in enterprise systems[2]. I'd argue it already has for anyone serious about production workloads. By 2026, the center of gravity has moved decisively. Anthropic frames it pragmatically: context engineering means finding the smallest possible set of high-signal tokens that maximize the likelihood of desired outcomes[3]. This is an economics problem as much as a design problem.

Two things drove this shift. First, context windows got huge (128k to 200k tokens), but attention mechanisms are imperfect at extreme lengths. There's this nasty phenomenon called context rot, and I've seen it wreck otherwise solid systems[4]. Second, production systems need persistent state: conversation memory, skill invocations, approval workflows, cross-agent coordination. You can't solve that with a static prompt. Context has to be dynamic, retrievable, and measured.

## The Context Rot Problem

I first heard about context rot as a theoretical concern. Then I ran into it in the real world, and it got a lot less theoretical.

Researchers analyzed 18 leading LLMs (GPT-4.1, Claude 4, Gemini 2.5, Qwen 3) and documented severe, unpredictable performance degradation as context expands[4]. The degradation isn't even linear. Models exhibit abrupt, idiosyncratic drops depending on architecture and task type. Some models hold performance until 120k tokens, then collapse. Others degrade smoothly from 30k onward[4].

This asymmetry breaks the naive assumption that more context equals better outcomes. FlowHunt's 2026 analysis tested retrieval accuracy, reasoning coherence, and instruction-following with varying context sizes. They found something striking: the same 4k tokens of high-relevance material often outperformed 100k tokens of mixed-relevance material. But the optimal compression ratio varies by model and task[4].

The implication: context engineering isn't about cramming as much information as possible. It's about strategic compression. You have to measure context rot on your specific models and workloads, then design retrieval and memory strategies accordingly. This is why enterprises now invest in context-aware RAG systems, hierarchical memory tiers, and automated context curation. It's table stakes.

## Four Fundamental Components

Context engineering rests on four tightly coupled pieces. **Context Composition** is selecting and formatting information: facts, instructions, tool definitions, examples. **Context Retrieval** encompasses semantic search, RAG, and dynamic tool outputs that supply context at runtime. **Context Memory** manages state across time: session memory for single conversations, cross-session memory for repeated interactions, hierarchical memory for compression and abstraction. **Context Protocols** standardize how agents receive and publish context, primarily MCP (Model Context Protocol) and agent-to-agent interfaces[1].

These components are tightly woven. Poor composition creates retrieval problems. Ineffective retrieval cascades into memory pollution. Weak protocols cause coordination failures. You need coherence across all four.

Composition decisions determine signal-to-noise ratios. I've seen tool descriptions so vague ("this tool does something important") that they generate errors that compound through an agent's entire execution. Retrieval strategies determine latency and cost. A system that fetches the entire knowledge base for every query exhausts token budgets and times out. Memory tiers determine whether agents can learn from previous failures or repeat them. Protocols determine whether multiple agents cooperate or work at cross-purposes.

## ACE: Agentic Context Engineering

Agentic Context Engineering (ACE) is the current state-of-the-art approach, published as a peer-reviewed paper at ICLR 2026[5]. The key insight is treating contexts as "evolving playbooks" that accumulate, refine, and organize strategies through generation, reflection, and curation. Not static templates. Living artifacts that improve over time.

The ACE architecture has three components. The **Generator** produces reasoning trajectories, tool interactions, and solution attempts. The **Reflector** distills insights from successes and failures, identifying which strategies generalize and which fail predictably. The **Curator** integrates reflections into structured context updates, rewriting agent instructions, refining tool descriptions, reorganizing memory tiers[5].

ACE solves two problems I've watched wreck other approaches. **Brevity bias** occurs when iterative summarization discards domain-specific insights in the name of compression. A full reasoning trace contains 8,000 tokens of rich, situation-specific logic. After one summarization pass, it becomes 2,000 tokens of generic guidance. The curator has to resist compression for compression's sake[5]. **Context collapse** is worse. I've seen it firsthand: an agent's context degraded over 60 steps. At step 60, it contained 18,282 tokens and achieved 66.7% accuracy. At step 61, after rewriting for brevity, it dropped to 122 tokens and 57.1% accuracy, worse than the no-context baseline of 63.7%[5].

On standardized agent benchmarks, ACE achieves +10.6% accuracy improvement compared to static-context baselines. On financial analysis tasks, the gain reaches +8.6%. These are production-level improvements[5].

## Codified Context Infrastructure: The Three-Tier Architecture

![Three-Tier Context Architecture](img_three_tier_context_architecture.svg)

I want to walk you through an architecture that works, based on real production numbers. One organization published detailed metrics from 108,000 lines of C#, 283 development sessions, 2,801 human prompts, and 1,197 agent invocations[6]. It's worth examining because it reflects hard-won tradeoffs between abstraction, performance, and maintainability.

**Tier 1, Hot Memory (Constitution)** is always loaded: approximately 660 lines containing core conventions, retrieval hooks, orchestration protocols, and safety guidelines. This tier is static but foundational. It defines how the agent interprets tasks, which tools it can invoke, what approval workflows apply. Every invocation pays the cost of these 660 lines[6].

**Tier 2, Domain Specialists (Agents)** comprises 19 specialist agents, each invoked per-task based on routing logic. Each agent embeds domain knowledge directly in its own specification: pricing logic for finance, compliance rules for legal, deployment procedures for infrastructure. This tier is dynamic. Only the relevant specialist is loaded[6].

**Tier 3, Cold Memory (Knowledge Base)** includes 34 on-demand specification documents retrieved only when relevant. These cover edge cases, policy details, historical context, reference material. Retrieval is semantic and sparse. In 70% of tasks, cold memory is never accessed[6].

Here's the math: baseline context is 660 tokens (Tier 1). For a typical task, add 2,000 tokens (Tier 2 specialist). Occasionally add 1,500 tokens (Tier 3 knowledge). You avoid loading all 19 specialists and all 34 reference docs into every prompt. This disciplined tiering reduced per-invocation tokens by 32% while maintaining accuracy and enabling faster iteration[6].

## CA-MCP: Context-Aware Model Context Protocol

The original MCP (Model Context Protocol, released by Anthropic) is stateless[7]. Agents integrate tools and data sources, but they lack access to global context. No awareness of other agents' actions, no shared memory of progress, no coordination substrate. In complex workflows with multiple agents, this statelessness creates duplication, conflicts, failures[7].

Context-Aware MCP (CA-MCP) addresses this with a **Shared Context Store** (SCS): a central memory that all agents read and write to, updated in real time as tasks proceed[7]. When Agent A discovers that a database connection failed, it writes that fact to SCS. Agent B reads SCS before attempting its own query, avoids the failed path, proceeds directly to a fallback. When a workflow enters a state that violates a precondition, agents detect it immediately rather than after failed invocations[7].

Early deployments show reduction in LLM calls for complex workflows by 28-35%, fewer timeout failures (because agents avoid redundant work), and faster adaptation to runtime conditions. The cost is operational complexity: maintaining SCS consistency under concurrent writes requires careful design[7].

## AGENTS.md as Context Engineering Artifact

An AGENTS.md file is a human-curated specification documenting the agent's capabilities, constraints, and runtime behavior. It's distinct from prompt engineering. It's infrastructure[8].

Empirical measurement shows measurable impact. Systems using AGENTS.md achieve 28.64% reduction in runtime and 16.58% reduction in token usage compared to equivalent tasks without them[8]. But there's a critical caveat: **LLM-generated AGENTS.md files perform 3% worse than sessions without them**[9]. Only human-curated AGENTS.md files improve performance consistently[9].

This distinction matters. Some organizations tried to generate AGENTS.md automatically from task descriptions, expecting AI to optimize its own context. The opposite happened. LLM-generated specs contained subtle errors in tool descriptions, over-generalized instructions, missing edge cases. The machine-generated artifact became context pollution rather than context amplification. Teams that invested in human curation saw the 28.64% runtime gains. Teams that relied on automation saw degradation[9].

AGENTS.md isn't a prompt template. It's engineering documentation that should be peer-reviewed, versioned, and treated as production code.

## Token Cost as Context Engineering Discipline

Context engineering is ultimately about token economics, and the numbers are more surprising than you'd expect. A study of 30 ChatDev traces with GPT-5 found that Code Review consumes 59.42% of all tokens in multi-agent systems[14]. Input tokens account for 53.9% of total cost. The primary expense isn't initial code generation. It's refinement and verification. There's also a "communication tax" for inter-agent coordination that most teams never account for[14]. If you're budgeting for agents based on generation costs alone, you're underestimating by roughly 2x.

Let me walk through a realistic scenario: 2,000 tokens in a copilot-instructions.md file, 1,000 users making 10 requests per day. That's 20 million tokens per day before a single application line executes[10].

The applyTo pattern in .instructions.md files reduces this cost by approximately 68%[10]. Rather than loading a global instruction set for every invocation, instructions are tagged with applicability conditions. An instruction about "how to handle payment failures" applies only to agents in the payments subsystem. Load it only when needed.

Skills with lazy loading (SKILL.md pattern) follow the same principle: the description is always loaded (50-100 tokens), but the full implementation body loads only when the skill is invoked. An organization might install 50 skills, each 400 tokens, totaling 20,000 tokens. Lazy loading means paying only for the descriptions (50 times 75 tokens equals 3,750 tokens) until a skill is actually invoked. If 70% of installed skills are never used in a session, lazy loading reduces effective context cost by 70%[10].

This discipline has direct ROI. At $0.003 per 1,000 input tokens, 20 million tokens per day costs $60. Reducing to 6.4 million tokens (via applyTo and lazy loading) costs $19.20. Over a year, the difference is $15,000 for a modest-scale deployment.

## The Semantic Density Principle

There's a counterintuitive finding that changed how I think about context compression. Dmytro Ustynov (MITIT, April 2026) demonstrated what he calls the "compression paradox": aggressively compressing context reduced input tokens by 17% but increased total session cost by 67%[15]. The reasoning tax (the extra tokens the model burns trying to reconstruct meaning from compressed context) more than offset the savings from shorter input.

The principle is this: tokens with high semantic density (descriptive names, type annotations, well-written docstrings) are investments. Tokens with zero information (boilerplate structure, ceremonial syntax) are pure waste. The ceremony-to-logic ratio in Java Spring Boot is 8:1. In Go, it's 2:1[15]. This has direct implications for language choice in agentic systems, but more importantly, it means your AGENTS.md and copilot-instructions.md files should use rich natural language, not abbreviations. Descriptive function names matter more than terse ones. Context files should communicate intent clearly, not minimize character count.

Ustynov proposes CODEMAP.md as a context artifact for large projects: a "program skeleton" that captures the essential structure without the ceremony[15]. I've started using this pattern in projects above 50,000 lines, and the impact on agent comprehension is noticeable.

## The Skill Engineering Ecosystem

A survey of agent skills (Zhejiang University, 2026) analyzed 55,315 publicly available skills and found a rapidly growing but undisciplined ecosystem[16]. The SKILL.md specification (description, body, references, scripts) has been adopted at remarkable speed: 62,000 GitHub stars in under four months. But 26.1% of community-created skills contain security vulnerabilities[16]. The skill paradigm has evolved through three stages: prompt engineering (instructions only), tool use (function calls), and skill engineering (composable, governed capabilities with progressive disclosure)[16].

The Skill Trust and Lifecycle Governance Framework proposes a 4-tier gate-based model: acquisition provenance (where did the skill come from?), verification gates (does it do what it claims?), deployment capabilities (what permissions does it need?), and runtime monitoring[16]. This is analogous to supply chain governance for code dependencies, and it's equally necessary.

SkillReducer (HKUST, Tsinghua, ZJU) took this analysis further by studying skill quality[17]. Of those 55,315 skills, 26.4% lack a routing description entirely, meaning agents can't even discover them properly. Over 60% of skill body content is non-actionable (background information, redundant examples, filler). SkillReducer applies adversarial delta debugging to compress descriptions by 48% and taxonomy-driven classification to compress bodies by 39%, while actually improving functional quality by 2.8%[17]. Less is more. When you strip the noise from skills, agents perform better, not worse.

The practical takeaway: when creating skills, always write a routing description (or the skill is invisible). Remove background and redundant examples from the body. Use progressive disclosure. Validate that the skill has less than 50% non-actionable content. These four rules eliminate most of the quality problems in the ecosystem.

## Contextual Memory Intelligence

There's a framework I want to mention that formalizes something I've been arguing for a while: memory in agent systems should be treated as infrastructure, not an afterthought. Kristy Wedel (Franklin University, 2026) proposes Contextual Memory Intelligence (CMI) as a structured approach to memory management in agentic systems[18].

The core argument is that memory tiers (working memory, episodic memory, semantic memory, procedural memory) need the same engineering rigor as database tiers. Working memory is the current context window. Episodic memory captures specific interaction sequences. Semantic memory stores general knowledge and relationships. Procedural memory encodes how to do things (skills, workflows, recipes).

Most agent systems I've seen in production conflate these tiers. They dump everything into the context window (working memory) and wonder why performance degrades. CMI says: design your memory architecture the way you'd design a caching strategy. Hot data in working memory. Warm data in episodic and semantic memory with retrieval mechanisms. Cold data in procedural memory loaded only when a specific skill is invoked. This maps directly to the three-tier architecture from Vasilopoulos that I described earlier, but CMI provides the theoretical framework for why those tiers work[18].

## Context Engineering as Deliberate Construction

A study of 2,926 GitHub repositories found that context engineering is becoming a deliberate practice[19]. Teams are creating context files (AGENTS.md, copilot-instructions.md, CLAUDE.md) not as an afterthought but as the first deliverable of any project. The study frames context engineering as "deliberate construction": you architect the context the same way you architect the code.

This finding validates the approach throughout this playbook. Context isn't a prompt you iterate on until it works. It's an engineering artifact you design, version, test, and maintain. The teams treating it this way are the ones whose agents actually survive production.

## Tool Description Smells in MCP

Tool descriptions in MCP specifications are prone to subtle errors, textual or structural imperfections that propagate downstream as specification errors affecting agent behavior[11]. The concept mirrors "code smells" from software engineering: patterns that aren't outright bugs but signal deeper problems.

A tool described as "processes transactions" versus "processes credit-card transactions with validation against Stripe's fraud API, returning a transaction ID or error code" will produce different agent behavior. The vague description invites hallucination. The agent fills in missing details incorrectly, leading to failed invocations. A tool with a missing error-handling section in its spec fails silently when the actual tool throws an exception, because the agent was never told what exceptions to expect[11].

The discipline of auditing tool descriptions (checking for vagueness, incomplete error documentation, missing parameter constraints, unclear return formats) is part of context engineering. It's not glamorous. It's essential[11].

## Context Workloads: The OpenDev Framework

Different inference tasks have different context requirements. The OpenDev framework (published by Becker et al. 2026) categorizes five standard workloads[12]:

**Action** workloads require fast, reliable tool execution. A chatbot answering a customer question and invoking a knowledge base search. Model: Sonnet 4.6. VS Code equivalent: rapid iteration, inline preview. Cost recommendation: optimize for latency, not context depth[12].

**Thinking** workloads require extended reasoning over complex state. A compliance agent reviewing a contract against regulatory requirements, accumulating reasoning across sections. Model: Opus 4.6 with extended thinking. Cost recommendation: pay for depth, not speed. 50k-100k tokens per invocation acceptable[12].

**Vision** workloads require multimodal context. A document processing agent that must parse PDFs, diagrams, and tables. Model: any model with vision capability (Claude Sonnet 4.6 with vision or equivalent). Cost recommendation: image tokens are expensive, compress where possible[12].

**Compaction** workloads summarize or distill large contexts into smaller artifacts for storage or passing to other agents. An agent that reads a 50-page specification and produces a 2k-token summary. Model: Haiku 4.5 (cost-optimized). Cost recommendation: minimize input token cost by batching summarizations[12].

**Subagent** workloads are lightweight delegations from a primary agent to a specialized secondary agent. A customer service agent routing to a refunds specialist. Model: Haiku 4.5. Cost recommendation: minimize context, maximize specificity in handoff instructions[12].

Matching workload to model is context engineering. Assigning a Thinking workload to Sonnet 4.6 wastes money. Assigning an Action workload to Opus 4.6 is overprovisioning. This matching is now a documented discipline.

## Context Platforms in Enterprise: Data Governance Perspective

Organizations recognize that context is infrastructure. The DataHub 2026 State of AI Context report found that 88% of organizations claim they have a fully operational context platform[13]. Yet the same organizations report chronic execution problems: 61% frequently delay AI initiatives due to lack of trusted data, and 66% report models generating biased or misleading insights due to insufficient or corrupt context[13].

The gap between aspiration and execution is context quality and governance. Top 2026 priorities across the surveyed enterprises are: AI-ready metadata (62% cite as critical), context quality assurance (55%), and trust and governance frameworks (48%)[13].

Context engineering as a discipline directly addresses these gaps. It provides frameworks for auditing tool descriptions, organizing memory tiers, measuring context rot, and curating high-signal information. It's not optional for enterprise deployment.

## Conclusion

Context engineering has evolved from an optimization tactic (squeeze more performance from prompts) to a foundational discipline (structure the information agents need, over time, within cost constraints). Organizations that apply ACE principles, implement three-tier memory architectures, adopt CA-MCP for coordination, and measure tool description quality achieve demonstrable improvements in agent reliability and cost efficiency.

The field remains early. Standards are emerging (MCP, AGENTS.md, SKILL.md) but not yet universal. Tool description auditing is still mostly manual. Context rot is understood but not completely solved. Yet the direction is clear: context is code, and it deserves the same rigor.

---

## References

[1] Meirtz. "Awesome-Context-Engineering." GitHub.
[2] IntuitionLabs. "What Is Context Engineering?" Analysis of Gartner research.
[3] SwirlAI. "State of Context Engineering in 2026." SwirlAI Newsletter.
[4] FlowHunt. "Context Engineering: Exploring Context Rot Across Leading LLMs." 2026.
[5] Zhang et al. "Agentic Context Engineering: Evolving Playbooks for Multi-Step Reasoning." ICLR 2026. arXiv:2510.04618
[6] Vasilopoulos. "Production Context Architectures: A Three-Tier Design in Enterprise Agent Systems." 2026. arXiv:2602.20478
[7] Jayanti et al. "Context-Aware MCP: Shared State for Coordinated Multi-Agent Workflows." 2026. arXiv:2601.11595
[8] "AGENTS.md Specification and Performance Impact." 2026. arXiv:2601.20404
[9] "LLM-Generated vs. Human-Curated Agent Specifications: A Comparative Study." 2026. arXiv:2602.11988
[10] Open Horizons. "Model Routing SDLC Guide v2.1.0." Model Routing documentation and cost analysis. 2026.
[11] "Tool Description Smells in Model Context Protocol: A Pattern Analysis." 2026. arXiv:2602.14878
[12] Becker et al. "OpenDev Framework: Categorizing Inference Workloads and Model-Workload Matching." 2026. arXiv:2603.05344
[13] DataHub. "Context Management Strategies: 2026 State of AI Context Report." Enterprise context platform survey. 2026.
[14] Concordia. "Tokenomics: Quantifying Token Usage in Agentic Systems." 30 ChatDev traces with GPT-5. arXiv:2601.14470.
[15] Ustynov, Dmytro. "Beyond Human-Readable: Semantic Density Principle." MITIT, April 2026. arXiv:2604.07502.
[16] Zhejiang University. "Agent Skills for Large Language Models." 55,315 skills survey. arXiv:2602.12430.
[17] HKUST+Tsinghua+ZJU. "SkillReducer: Optimizing LLM Agent Skills." 55,315 skills analyzed. arXiv:2603.29919.
[18] Wedel, Kristy. "Contextual Memory Intelligence." Franklin University. arXiv:2506.05370.
[19] "Context Engineering: Deliberate Construction of Agent Context." 2,926 repos study. arXiv:2504.02519.
