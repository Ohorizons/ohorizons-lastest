"""
Open Horizons — AI Impact Agent API

Measures the real impact of AI and Agentic DevOps on the SDLC.
Powered by Microsoft Agent Framework + ChromaDB RAG + GitHub APIs.

Endpoints:
  GET  /health                  → health check
  GET  /api/impact/summary      → consolidated KPIs + AI narrative
  GET  /api/impact/copilot      → Copilot billing + usage metrics
  GET  /api/impact/velocity     → developer velocity metrics
  GET  /api/impact/quality      → code quality + DORA + security
  GET  /api/impact/adoption     → AI adoption rates
  POST /api/impact/analyze      → trigger on-demand LLM analysis
  GET  /api/impact/insights     → stored RAG insights
"""

import json
import os
import logging
from contextlib import asynccontextmanager
from typing import Any

from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from openai import AsyncAzureOpenAI
from pydantic import BaseModel

from memory.metrics_store import init_db, get_latest_snapshot, save_snapshot
from memory.knowledge_base import get_all_insights, count_insights, search_insights, store_insight
from collectors.copilot import collect_copilot_billing, collect_copilot_metrics
from collectors.developer import collect_org_activity
from collectors.pipelines import collect_dora_metrics
from collectors.security import collect_security_posture
from analyzers.kpi_engine import calculate_impact_summary

load_dotenv()

# ── Config ──────────────────────────────────────────────────────────
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "")
GITHUB_ORG = os.getenv("GITHUB_ORG", "Ohorizons")
GITHUB_REPO = os.getenv("GITHUB_REPO", "ohorizons-demo")
AZURE_OPENAI_ENDPOINT = os.getenv("AZURE_OPENAI_ENDPOINT", "")
AZURE_OPENAI_API_VERSION = os.getenv("AZURE_OPENAI_API_VERSION", "2025-04-01-preview")
AZURE_OPENAI_DEPLOYMENT = os.getenv("AZURE_OPENAI_DEPLOYMENT", "gpt-5-1")
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "http://localhost:3000,http://localhost:7007").split(",")
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

logging.basicConfig(level=LOG_LEVEL, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger("ai-impact-api")


def _json_dumps(data: Any) -> str:
    return json.dumps(data, indent=2, ensure_ascii=True, default=str)


def _extract_text(content: Any) -> str:
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        parts: list[str] = []
        for item in content:
            if isinstance(item, dict):
                text = item.get("text") or item.get("content") or ""
                if text:
                    parts.append(str(text))
            elif hasattr(item, "text"):
                parts.append(str(item.text))
            else:
                parts.append(str(item))
        return "\n".join(part for part in parts if part).strip()
    return str(content).strip()


def _create_analysis_client() -> AsyncAzureOpenAI:
    credential = DefaultAzureCredential()
    token = credential.get_token("https://cognitiveservices.azure.com/.default")
    return AsyncAzureOpenAI(
        azure_endpoint=AZURE_OPENAI_ENDPOINT,
        azure_ad_token=token.token,
        api_version=AZURE_OPENAI_API_VERSION,
    )


def _build_analysis_prompt(question: str, summary: dict, details: dict, prior_summary: dict | None, related_insights: list[dict]) -> str:
    return f"""
You are the AI Impact Analyzer for the Open Horizons platform.

Your job is to produce an executive-grade analysis, not a shallow metric dump.

User request:
{question}

Write the response in the same language as the user request.

Mandatory requirements:
- Minimum 700 words unless the user explicitly asked for a short response.
- Use clear sections and short paragraphs.
- Do not output raw JSON.
- Do not fabricate numbers. If a metric is unavailable because GitHub returns 403 or 404, say the feature is unavailable or not enabled.
- Translate technical metrics into business impact.
- Explain limitations and confidence level.
- End with prioritized recommendations.

Use this exact structure:
1. Executive Summary
2. Current State
3. Trend and Change Analysis
4. Business Impact
5. Risks, Gaps, and Data Limitations
6. Recommendations

Current summary:
{_json_dumps(summary)}

Detailed collected data:
{_json_dumps(details)}

Previous summary, if available:
{_json_dumps(prior_summary) if prior_summary else 'No previous summary available.'}

Relevant historical insights:
{_json_dumps(related_insights) if related_insights else 'No prior insights found.'}

Additional guidance:
- If Copilot metrics are unavailable, explicitly say usage telemetry is unavailable and rely on billing/adoption plus repo activity.
- If security APIs are unavailable, say GHAS-related signals are unavailable instead of implying zero risk.
- Use the AI Impact Score, deployment frequency, change failure rate, contributor activity, and security posture to form a balanced view.
- Recommendations must be concrete, prioritized, and tied to the data above.
""".strip()


# ── App Lifecycle ───────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    logger.info("AI Impact API starting — org=%s, repo=%s", GITHUB_ORG, GITHUB_REPO)
    yield
    logger.info("AI Impact API shutting down")


app = FastAPI(title="Open Horizons AI Impact API", version="1.0.0", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=CORS_ORIGINS, allow_credentials=True,
                   allow_methods=["*"], allow_headers=["*"])


# ── Health ──────────────────────────────────────────────────────────
@app.get("/health")
async def health():
    return {
        "status": "ok",
        "service": "ai-impact",
        "org": GITHUB_ORG,
        "insights_stored": count_insights(),
    }


# ── GET /api/impact/summary ────────────────────────────────────────
@app.get("/api/impact/summary")
async def impact_summary():
    """Get consolidated AI Impact KPIs. Collects fresh data if no snapshot exists."""
    cached = get_latest_snapshot("impact_summary")
    if cached:
        return cached

    # First run — collect everything
    billing = await collect_copilot_billing(GITHUB_ORG, GITHUB_TOKEN)
    save_snapshot("copilot_billing", billing)
    metrics = await collect_copilot_metrics(GITHUB_ORG, GITHUB_TOKEN)
    save_snapshot("copilot_metrics", metrics)
    activity = await collect_org_activity(GITHUB_ORG, GITHUB_TOKEN)
    save_snapshot("org_activity", activity)
    dora = await collect_dora_metrics(GITHUB_ORG, GITHUB_REPO, GITHUB_TOKEN)
    save_snapshot("dora_metrics", dora)
    security = await collect_security_posture(GITHUB_ORG, GITHUB_REPO, GITHUB_TOKEN)
    save_snapshot("security_posture", security)

    summary = calculate_impact_summary(billing, metrics, activity, dora, security)
    save_snapshot("impact_summary", summary)
    return summary


# ── GET /api/impact/copilot ────────────────────────────────────────
@app.get("/api/impact/copilot")
async def impact_copilot():
    """Get Copilot billing and usage metrics."""
    billing = await collect_copilot_billing(GITHUB_ORG, GITHUB_TOKEN)
    save_snapshot("copilot_billing", billing)
    metrics = await collect_copilot_metrics(GITHUB_ORG, GITHUB_TOKEN)
    save_snapshot("copilot_metrics", metrics)
    return {"billing": billing, "metrics": metrics}


# ── GET /api/impact/velocity ───────────────────────────────────────
@app.get("/api/impact/velocity")
async def impact_velocity():
    """Get developer velocity metrics."""
    activity = await collect_org_activity(GITHUB_ORG, GITHUB_TOKEN)
    save_snapshot("org_activity", activity)
    return activity


# ── GET /api/impact/quality ────────────────────────────────────────
@app.get("/api/impact/quality")
async def impact_quality():
    """Get code quality, DORA metrics, and security posture."""
    dora = await collect_dora_metrics(GITHUB_ORG, GITHUB_REPO, GITHUB_TOKEN)
    save_snapshot("dora_metrics", dora)
    security = await collect_security_posture(GITHUB_ORG, GITHUB_REPO, GITHUB_TOKEN)
    save_snapshot("security_posture", security)
    return {"dora": dora, "security": security}


# ── GET /api/impact/adoption ──────────────────────────────────────
@app.get("/api/impact/adoption")
async def impact_adoption():
    """Get AI adoption rates and seat utilization."""
    billing = await collect_copilot_billing(GITHUB_ORG, GITHUB_TOKEN)
    save_snapshot("copilot_billing", billing)
    total = billing.get("total_seats", 0)
    active = billing.get("active_this_cycle", 0)
    return {
        **billing,
        "adoption_rate": round(active / max(total, 1) * 100, 1),
    }


# ── POST /api/impact/analyze ──────────────────────────────────────
class AnalyzeRequest(BaseModel):
    question: str | None = None


@app.post("/api/impact/analyze")
async def analyze(request: AnalyzeRequest):
    """Generate a comprehensive AI impact analysis using fresh metrics and Azure OpenAI."""
    question = request.question or (
        "Provide a comprehensive AI impact analysis for the current organization and repository."
    )

    prior_summary = get_latest_snapshot("impact_summary")

    billing = await collect_copilot_billing(GITHUB_ORG, GITHUB_TOKEN)
    save_snapshot("copilot_billing", billing)

    metrics = await collect_copilot_metrics(GITHUB_ORG, GITHUB_TOKEN)
    save_snapshot("copilot_metrics", metrics)

    activity = await collect_org_activity(GITHUB_ORG, GITHUB_TOKEN)
    save_snapshot("org_activity", activity)

    dora = await collect_dora_metrics(GITHUB_ORG, GITHUB_REPO, GITHUB_TOKEN)
    save_snapshot("dora_metrics", dora)

    security = await collect_security_posture(GITHUB_ORG, GITHUB_REPO, GITHUB_TOKEN)
    save_snapshot("security_posture", security)

    summary = calculate_impact_summary(billing, metrics, activity, dora, security)
    save_snapshot("impact_summary", summary)

    related_insights = search_insights(question, n_results=5)
    details = {
        "copilot_billing": billing,
        "copilot_metrics": metrics,
        "org_activity": activity,
        "dora_metrics": dora,
        "security_posture": security,
    }

    client = _create_analysis_client()
    prompt = _build_analysis_prompt(question, summary, details, prior_summary, related_insights)

    response = await client.responses.create(
        model=AZURE_OPENAI_DEPLOYMENT,
        input=[
            {
                "role": "system",
                "content": [
                    {
                        "type": "input_text",
                        "text": "You are a senior AI impact consultant producing high-quality executive analyses grounded only in provided evidence.",
                    }
                ],
            },
            {
                "role": "user",
                "content": [{"type": "input_text", "text": prompt}],
            },
        ],
        max_output_tokens=2500,
        temperature=0.3,
    )

    analysis = getattr(response, "output_text", "").strip()
    if not analysis:
        analysis = _extract_text(getattr(response, "output", []))
    if not analysis:
        analysis = "No analysis content was returned by the model."
    else:
        store_insight(
            analysis[:1200],
            "analysis",
            metadata={
                "ai_impact_score": summary.get("ai_impact_score"),
                "org": GITHUB_ORG,
                "repo": GITHUB_REPO,
            },
        )

    return {
        "analysis": analysis,
        "insights_stored": count_insights(),
        "summary": summary,
    }


# ── GET /api/impact/insights ──────────────────────────────────────
@app.get("/api/impact/insights")
async def insights():
    """Get all stored RAG insights."""
    return {
        "total": count_insights(),
        "insights": get_all_insights(),
    }


# ── Run ────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8011"))
    uvicorn.run("main:app", host=host, port=port, reload=True, log_level=LOG_LEVEL.lower())
