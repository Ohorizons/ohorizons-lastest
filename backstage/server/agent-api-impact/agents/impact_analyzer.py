"""
Impact Analyzer Agent — MAF Agent with learning capabilities.

Uses Microsoft Agent Framework to:
1. Collect metrics from GitHub APIs
2. Calculate KPIs
3. Generate AI-powered insights using LLM
4. Store insights in ChromaDB for RAG-based learning
5. Compare historical trends
"""

import os
import json
import logging

from agent_framework import Agent, FunctionTool, tool, ChatOptions
from agent_framework.openai import OpenAIChatClient

from collectors.copilot import collect_copilot_billing, collect_copilot_metrics
from collectors.developer import collect_org_activity
from collectors.pipelines import collect_dora_metrics
from collectors.security import collect_security_posture
from memory.metrics_store import save_snapshot, get_latest_snapshot, compare_snapshots, save_kpi
from memory.knowledge_base import store_insight, search_insights, count_insights
from analyzers.kpi_engine import calculate_impact_summary

logger = logging.getLogger("agents.impact_analyzer")

GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "")
GITHUB_ORG = os.getenv("GITHUB_ORG", "Ohorizons")
GITHUB_REPO = os.getenv("GITHUB_REPO", "ohorizons-demo")


# ── MAF Tools ──────────────────────────────────────────────────────

@tool
async def collect_all_metrics() -> str:
    """Collect current metrics from all GitHub API sources and save snapshots."""
    results = {}

    billing = await collect_copilot_billing(GITHUB_ORG, GITHUB_TOKEN)
    save_snapshot("copilot_billing", billing)
    results["copilot_billing"] = billing

    metrics = await collect_copilot_metrics(GITHUB_ORG, GITHUB_TOKEN)
    save_snapshot("copilot_metrics", metrics)
    results["copilot_metrics"] = metrics

    activity = await collect_org_activity(GITHUB_ORG, GITHUB_TOKEN)
    save_snapshot("org_activity", activity)
    results["org_activity"] = activity

    dora = await collect_dora_metrics(GITHUB_ORG, GITHUB_REPO, GITHUB_TOKEN)
    save_snapshot("dora_metrics", dora)
    results["dora_metrics"] = dora

    security = await collect_security_posture(GITHUB_ORG, GITHUB_REPO, GITHUB_TOKEN)
    save_snapshot("security_posture", security)
    results["security_posture"] = security

    # Calculate and save KPIs
    summary = calculate_impact_summary(billing, metrics, activity, dora, security)
    save_snapshot("impact_summary", summary)
    save_kpi("ai_impact_score", summary["ai_impact_score"], "points", "current")
    save_kpi("adoption_rate", summary["adoption"]["adoption_rate"], "%", "current")
    save_kpi("acceptance_rate", summary["productivity"]["acceptance_rate"], "%", "current")

    return json.dumps({"status": "collected", "summary": summary}, indent=2)


@tool
async def get_impact_summary() -> str:
    """Get the latest AI Impact summary with all KPIs."""
    summary = get_latest_snapshot("impact_summary")
    if not summary:
        return json.dumps({"status": "no_data", "message": "No metrics collected yet. Run collect_all_metrics first."})
    return json.dumps(summary, indent=2)


@tool
async def compare_with_previous(category: str) -> str:
    """Compare latest metrics with previous snapshot for trend analysis.

    Args:
        category: One of copilot_billing, copilot_metrics, org_activity, dora_metrics, security_posture, impact_summary
    """
    comparison = compare_snapshots(category)
    if not comparison:
        return json.dumps({"status": "insufficient_data", "message": f"Need at least 2 snapshots of '{category}' for comparison."})
    return json.dumps(comparison, indent=2)


@tool
async def search_past_insights(query: str) -> str:
    """Search historical insights using RAG for relevant context.

    Args:
        query: Natural language query to search for relevant past insights.
    """
    insights = search_insights(query, n_results=5)
    total = count_insights()
    return json.dumps({"total_insights_stored": total, "relevant_insights": insights}, indent=2)


@tool
async def save_learned_insight(insight: str, category: str) -> str:
    """Store a new insight for future RAG retrieval. Call this when you generate a novel observation.

    Args:
        insight: The insight text to store (e.g., "Teams using Copilot for TypeScript improved velocity by 40%").
        category: Category tag (e.g., adoption, velocity, quality, security, roi).
    """
    store_insight(insight, category)
    return json.dumps({"status": "stored", "category": category, "insight_preview": insight[:100]})


# ── Agent Factory ──────────────────────────────────────────────────

def create_impact_agent() -> Agent:
    """Create the AI Impact Analyzer MAF Agent."""
    endpoint = os.getenv("AZURE_OPENAI_ENDPOINT", "")
    api_key = os.getenv("AZURE_OPENAI_API_KEY", "")
    api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2025-04-01-preview")
    deployment = os.getenv("AZURE_OPENAI_DEPLOYMENT", "gpt-5-1")

    if api_key:
        client = OpenAIChatClient(
            api_key=api_key,
            model=deployment,
            azure_endpoint=endpoint,
            api_version=api_version,
        )
    else:
        from azure.identity import DefaultAzureCredential
        credential = DefaultAzureCredential()
        token = credential.get_token("https://cognitiveservices.azure.com/.default").token
        import openai
        openai_client = openai.AsyncAzureOpenAI(
            azure_endpoint=endpoint,
            azure_ad_token=token,
            api_version=api_version,
        )
        client = OpenAIChatClient(model=deployment, async_client=openai_client)

    instructions = """You are the **AI Impact Analyzer** — an expert at measuring and communicating the impact of AI and Agentic DevOps on software development lifecycle (SDLC).

Your mission:
1. COLLECT metrics from GitHub APIs (Copilot, Actions, PRs, Security)
2. ANALYZE the data to identify trends, patterns, and impact
3. LEARN by storing insights for future reference (RAG)
4. COMMUNICATE impact through clear narratives and actionable recommendations

When analyzing, always:
- Compare current metrics with historical data when available
- Search past insights for relevant context before generating new ones
- Store novel insights for future learning
- Express impact in business terms (hours saved, cost reduction, velocity improvement)
- Use the AI Impact Score (0-100) as a composite health indicator

KPI Framework:
- Adoption: seat utilization, active users, team coverage
- Productivity: acceptance rate, lines generated, suggestions acted on
- Velocity: PR merge time, deploy frequency, contributor count
- Quality: change failure rate, vulnerability count, risk level
- ROI: estimated hours saved, cost per suggestion, automation rate

Respond in the same language the user writes in (English, Portuguese, Spanish).
NEVER display raw JSON, tool calls, or function names — present results as clear narratives with data points."""

    return Agent(
        client=client,
        name="impact_analyzer",
        instructions=instructions,
        tools=[
            collect_all_metrics,
            get_impact_summary,
            compare_with_previous,
            search_past_insights,
            save_learned_insight,
        ],
        default_options=ChatOptions(temperature=0.4, max_tokens=4096),
    )
