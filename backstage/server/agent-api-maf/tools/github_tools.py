"""GitHub REST API tools using MAF @tool decorator."""

import os
import json
import logging
from typing import Annotated, Any

import httpx
from dotenv import load_dotenv
from agent_framework import tool

load_dotenv()

logger = logging.getLogger("tools.github")

GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "")
GITHUB_API = "https://api.github.com"
GITHUB_OWNER = os.getenv("GITHUB_OWNER", "Ohorizons")


def _headers() -> dict[str, str]:
    h = {"Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"}
    if GITHUB_TOKEN:
        h["Authorization"] = f"Bearer {GITHUB_TOKEN}"
    return h


async def _get(path: str, params: dict | None = None) -> Any:
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(f"{GITHUB_API}{path}", headers=_headers(), params=params or {})
        return r.json() if r.status_code == 200 else {"error": f"GitHub API {r.status_code}", "message": r.text[:300]}


async def _post(path: str, body: dict) -> Any:
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.post(f"{GITHUB_API}{path}", headers=_headers(), json=body)
        return r.json() if r.status_code in (200, 201) else {"error": f"GitHub API {r.status_code}", "message": r.text[:300]}


# ── Pipeline tools ─────────────────────────────────────────────────

@tool
async def get_workflow_runs(
    repo: Annotated[str, "Repository name"],
    status: Annotated[str, "Filter: completed, failure, success, in_progress"] = "",
    per_page: Annotated[int, "Number of runs (max 10)"] = 5,
) -> str:
    """Get recent GitHub Actions workflow runs for a repository."""
    params: dict[str, Any] = {"per_page": per_page}
    if status:
        params["status"] = status
    data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/actions/runs", params)
    if "error" in data:
        return json.dumps(data)
    runs = [{"id": r["id"], "name": r["name"], "status": r["status"], "conclusion": r.get("conclusion"),
             "branch": r["head_branch"], "event": r["event"], "html_url": r["html_url"],
             "created_at": r["created_at"]} for r in data.get("workflow_runs", [])[:per_page]]
    return json.dumps({"total_count": data.get("total_count", 0), "runs": runs})


@tool
async def get_workflow_run_jobs(
    repo: Annotated[str, "Repository name"],
    run_id: Annotated[str, "Workflow run ID"],
) -> str:
    """Get jobs and steps for a specific workflow run. Shows which steps passed/failed."""
    data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/actions/runs/{run_id}/jobs")
    if "error" in data:
        return json.dumps(data)
    jobs = []
    for job in data.get("jobs", []):
        steps = [{"name": s["name"], "status": s["status"], "conclusion": s.get("conclusion")} for s in job.get("steps", [])]
        jobs.append({"name": job["name"], "status": job["status"], "conclusion": job.get("conclusion"), "steps": steps})
    return json.dumps({"jobs": jobs})


# ── Sentinel tools ─────────────────────────────────────────────────

@tool
async def get_check_runs(
    repo: Annotated[str, "Repository name"],
    ref: Annotated[str, "Git ref (branch or SHA)"] = "main",
) -> str:
    """Get CI check runs (test results, linting, build status) for a git ref."""
    data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/commits/{ref}/check-runs")
    if "error" in data:
        return json.dumps(data)
    checks = [{"name": c["name"], "status": c["status"], "conclusion": c.get("conclusion"),
               "html_url": c.get("html_url"), "output_title": c.get("output", {}).get("title")}
              for c in data.get("check_runs", [])]
    return json.dumps({"total_count": data.get("total_count", 0), "check_runs": checks})


@tool
async def get_pull_requests(
    repo: Annotated[str, "Repository name"],
    state: Annotated[str, "PR state: open, closed, all"] = "open",
    per_page: Annotated[int, "Number of PRs"] = 5,
) -> str:
    """List pull requests for a repository."""
    data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/pulls", {"state": state, "per_page": per_page})
    if "error" in data:
        return json.dumps(data)
    prs = [{"number": p["number"], "title": p["title"], "state": p["state"], "user": p["user"]["login"],
            "head_branch": p["head"]["ref"], "html_url": p["html_url"]} for p in data[:per_page]]
    return json.dumps({"pull_requests": prs})


# ── Compass tools ──────────────────────────────────────────────────

@tool
async def create_issue(
    repo: Annotated[str, "Repository name"],
    title: Annotated[str, "Issue title"],
    body: Annotated[str, "Issue body (markdown)"],
    labels: Annotated[str, "Comma-separated labels"] = "",
) -> str:
    """Create a GitHub Issue with title, body, and optional labels."""
    payload: dict[str, Any] = {"title": title, "body": body}
    if labels:
        payload["labels"] = [l.strip() for l in labels.split(",")]
    data = await _post(f"/repos/{GITHUB_OWNER}/{repo}/issues", payload)
    if "error" in data:
        return json.dumps(data)
    return json.dumps({"number": data["number"], "title": data["title"], "html_url": data["html_url"]})


@tool
async def list_issues(
    repo: Annotated[str, "Repository name"],
    state: Annotated[str, "Issue state: open, closed, all"] = "open",
    labels: Annotated[str, "Comma-separated label filter"] = "",
    per_page: Annotated[int, "Number of issues"] = 10,
) -> str:
    """List GitHub Issues for a repository."""
    params: dict[str, Any] = {"state": state, "per_page": per_page}
    if labels:
        params["labels"] = labels
    data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/issues", params)
    if "error" in data:
        return json.dumps(data)
    issues = [{"number": i["number"], "title": i["title"], "state": i["state"],
               "labels": [l["name"] for l in i.get("labels", [])], "html_url": i["html_url"]}
              for i in data[:per_page] if "pull_request" not in i]
    return json.dumps({"issues": issues})


@tool
async def get_issue(
    repo: Annotated[str, "Repository name"],
    issue_number: Annotated[int, "Issue number"],
) -> str:
    """Get full details of a specific GitHub Issue."""
    data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/issues/{issue_number}")
    if "error" in data:
        return json.dumps(data)
    return json.dumps({"number": data["number"], "title": data["title"], "body": data.get("body", "")[:1000],
                        "state": data["state"], "labels": [l["name"] for l in data.get("labels", [])],
                        "html_url": data["html_url"]})


# ── Guardian tools ─────────────────────────────────────────────────

@tool
async def get_dependabot_alerts(
    repo: Annotated[str, "Repository name"],
    state: Annotated[str, "Alert state: open, dismissed, fixed"] = "open",
    per_page: Annotated[int, "Number of alerts"] = 10,
) -> str:
    """List Dependabot vulnerability alerts with CVEs and severity."""
    data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/dependabot/alerts", {"state": state, "per_page": per_page})
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)
    alerts = []
    for a in data[:per_page]:
        vuln = a.get("security_vulnerability", {})
        alerts.append({"number": a.get("number"), "severity": vuln.get("severity"),
                        "package": vuln.get("package", {}).get("name"),
                        "cve_id": a.get("security_advisory", {}).get("cve_id"),
                        "summary": a.get("security_advisory", {}).get("summary", "")[:200],
                        "html_url": a.get("html_url")})
    return json.dumps({"alerts": alerts, "total": len(alerts)})


@tool
async def get_code_scanning_alerts(
    repo: Annotated[str, "Repository name"],
    state: Annotated[str, "Alert state: open, dismissed, fixed"] = "open",
) -> str:
    """List CodeQL/SAST code scanning alerts."""
    data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/code-scanning/alerts", {"state": state, "per_page": 10})
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)
    alerts = [{"number": a.get("number"), "severity": a.get("rule", {}).get("security_severity_level"),
               "rule": a.get("rule", {}).get("id"), "file": a.get("most_recent_instance", {}).get("location", {}).get("path"),
               "html_url": a.get("html_url")} for a in data[:10]]
    return json.dumps({"alerts": alerts, "total": len(alerts)})


@tool
async def get_secret_scanning_alerts(
    repo: Annotated[str, "Repository name"],
    state: Annotated[str, "Alert state: open, resolved"] = "open",
) -> str:
    """List secret scanning alerts for exposed credentials."""
    data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/secret-scanning/alerts", {"state": state, "per_page": 10})
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)
    alerts = [{"number": a.get("number"), "secret_type": a.get("secret_type_display_name"),
               "state": a.get("state"), "html_url": a.get("html_url")} for a in data[:10]]
    return json.dumps({"alerts": alerts, "total": len(alerts)})
