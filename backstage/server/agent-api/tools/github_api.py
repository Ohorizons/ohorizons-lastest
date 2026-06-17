"""
GitHub REST API tools — real API calls for the 3-agent system.

Uses GITHUB_TOKEN env var for authentication.
Falls back to unauthenticated requests (rate-limited) if no token.

Each function returns a JSON string ready for Claude tool_result.
"""

import os
import json
import logging
from typing import Any

import httpx
from dotenv import load_dotenv

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
    """GET request to GitHub API."""
    url = f"{GITHUB_API}{path}"
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(url, headers=_headers(), params=params or {})
        if r.status_code == 200:
            return r.json()
        return {"error": f"GitHub API {r.status_code}", "message": r.text[:300]}


async def _post(path: str, body: dict) -> Any:
    """POST request to GitHub API."""
    url = f"{GITHUB_API}{path}"
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.post(url, headers=_headers(), json=body)
        if r.status_code in (200, 201):
            return r.json()
        return {"error": f"GitHub API {r.status_code}", "message": r.text[:300]}


# ═══════════════════════════════════════════════════════════════════
# PIPELINE AGENT tools — GitHub Actions
# ═══════════════════════════════════════════════════════════════════

async def get_workflow_runs(repo: str, status: str = "", per_page: int = 5) -> str:
    """Get recent GitHub Actions workflow runs for a repo."""
    owner = GITHUB_OWNER
    params: dict[str, Any] = {"per_page": per_page}
    if status:
        params["status"] = status

    data = await _get(f"/repos/{owner}/{repo}/actions/runs", params)
    if "error" in data:
        return json.dumps(data)

    runs = []
    for run in data.get("workflow_runs", [])[:per_page]:
        runs.append({
            "id": run["id"],
            "name": run["name"],
            "status": run["status"],
            "conclusion": run.get("conclusion"),
            "branch": run["head_branch"],
            "event": run["event"],
            "created_at": run["created_at"],
            "updated_at": run["updated_at"],
            "html_url": run["html_url"],
            "run_attempt": run.get("run_attempt", 1),
        })
    return json.dumps({"total_count": data.get("total_count", 0), "runs": runs})


async def get_workflow_run_jobs(repo: str, run_id: str) -> str:
    """Get jobs for a specific workflow run — shows which steps failed."""
    owner = GITHUB_OWNER
    data = await _get(f"/repos/{owner}/{repo}/actions/runs/{run_id}/jobs")
    if "error" in data:
        return json.dumps(data)

    jobs = []
    for job in data.get("jobs", []):
        steps = []
        for step in job.get("steps", []):
            steps.append({
                "name": step["name"],
                "status": step["status"],
                "conclusion": step.get("conclusion"),
                "number": step["number"],
            })
        jobs.append({
            "id": job["id"],
            "name": job["name"],
            "status": job["status"],
            "conclusion": job.get("conclusion"),
            "started_at": job.get("started_at"),
            "completed_at": job.get("completed_at"),
            "steps": steps,
        })
    return json.dumps({"jobs": jobs})


# ═══════════════════════════════════════════════════════════════════
# SENTINEL AGENT tools — Checks API + Artifacts
# ═══════════════════════════════════════════════════════════════════

async def get_check_runs(repo: str, ref: str = "main") -> str:
    """Get check runs (CI status checks) for a git ref."""
    owner = GITHUB_OWNER
    data = await _get(f"/repos/{owner}/{repo}/commits/{ref}/check-runs")
    if "error" in data:
        return json.dumps(data)

    checks = []
    for cr in data.get("check_runs", []):
        checks.append({
            "id": cr["id"],
            "name": cr["name"],
            "status": cr["status"],
            "conclusion": cr.get("conclusion"),
            "started_at": cr.get("started_at"),
            "completed_at": cr.get("completed_at"),
            "html_url": cr.get("html_url"),
            "output_title": cr.get("output", {}).get("title"),
            "output_summary": (cr.get("output") or {}).get("summary") or "",
        })
    return json.dumps({"total_count": data.get("total_count", 0), "check_runs": checks})


async def get_pull_requests(repo: str, state: str = "open", per_page: int = 5) -> str:
    """List pull requests for a repo — useful for coverage analysis on PRs."""
    owner = GITHUB_OWNER
    data = await _get(f"/repos/{owner}/{repo}/pulls", {"state": state, "per_page": per_page})
    if "error" in data:
        return json.dumps(data)

    prs = []
    for pr in data[:per_page]:
        prs.append({
            "number": pr["number"],
            "title": pr["title"],
            "state": pr["state"],
            "user": pr["user"]["login"],
            "head_branch": pr["head"]["ref"],
            "base_branch": pr["base"]["ref"],
            "created_at": pr["created_at"],
            "updated_at": pr["updated_at"],
            "html_url": pr["html_url"],
            "mergeable_state": pr.get("mergeable_state"),
        })
    return json.dumps({"pull_requests": prs})


# ═══════════════════════════════════════════════════════════════════
# COMPASS AGENT tools — Issues API
# ═══════════════════════════════════════════════════════════════════

async def create_issue(repo: str, title: str, body: str, labels: list[str] | None = None) -> str:
    """Create a GitHub Issue."""
    owner = GITHUB_OWNER
    payload: dict[str, Any] = {"title": title, "body": body}
    if labels:
        payload["labels"] = labels

    data = await _post(f"/repos/{owner}/{repo}/issues", payload)
    if "error" in data:
        return json.dumps(data)

    return json.dumps({
        "number": data["number"],
        "title": data["title"],
        "html_url": data["html_url"],
        "state": data["state"],
        "created_at": data["created_at"],
    })


async def list_issues(repo: str, state: str = "open", labels: str = "", per_page: int = 10) -> str:
    """List GitHub Issues for a repo."""
    owner = GITHUB_OWNER
    params: dict[str, Any] = {"state": state, "per_page": per_page}
    if labels:
        params["labels"] = labels

    data = await _get(f"/repos/{owner}/{repo}/issues", params)
    if "error" in data:
        return json.dumps(data)

    issues = []
    for issue in data[:per_page]:
        if "pull_request" in issue:
            continue  # skip PRs
        issues.append({
            "number": issue["number"],
            "title": issue["title"],
            "state": issue["state"],
            "labels": [l["name"] for l in issue.get("labels", [])],
            "assignees": [a["login"] for a in issue.get("assignees", [])],
            "created_at": issue["created_at"],
            "html_url": issue["html_url"],
        })
    return json.dumps({"issues": issues})


async def get_issue(repo: str, issue_number: int) -> str:
    """Get details of a specific GitHub Issue."""
    owner = GITHUB_OWNER
    data = await _get(f"/repos/{owner}/{repo}/issues/{issue_number}")
    if "error" in data:
        return json.dumps(data)

    return json.dumps({
        "number": data["number"],
        "title": data["title"],
        "body": data.get("body", "")[:1000],
        "state": data["state"],
        "labels": [l["name"] for l in data.get("labels", [])],
        "assignees": [a["login"] for a in data.get("assignees", [])],
        "created_at": data["created_at"],
        "updated_at": data["updated_at"],
        "html_url": data["html_url"],
        "comments": data.get("comments", 0),
    })


# ═══════════════════════════════════════════════════════════════════
# GUARDIAN AGENT tools — GitHub Advanced Security (GHAS)
# ═══════════════════════════════════════════════════════════════════

async def get_code_scanning_alerts(repo: str, state: str = "open", severity: str = "", per_page: int = 10) -> str:
    """Get code scanning (CodeQL/SAST) alerts for a repo."""
    owner = GITHUB_OWNER
    params: dict[str, Any] = {"state": state, "per_page": min(per_page, 30)}
    if severity:
        params["severity"] = severity
    data = await _get(f"/repos/{owner}/{repo}/code-scanning/alerts", params)
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)
    if not isinstance(data, list):
        return json.dumps({"alerts": [], "total": 0, "note": "Code scanning may not be enabled"})

    alerts = []
    for a in data[:per_page]:
        alerts.append({
            "number": a.get("number"),
            "rule_id": a.get("rule", {}).get("id", ""),
            "rule_description": a.get("rule", {}).get("description", ""),
            "severity": a.get("rule", {}).get("security_severity_level", a.get("rule", {}).get("severity", "")),
            "state": a.get("state"),
            "tool": a.get("tool", {}).get("name", ""),
            "file": a.get("most_recent_instance", {}).get("location", {}).get("path", ""),
            "line": a.get("most_recent_instance", {}).get("location", {}).get("start_line", ""),
            "html_url": a.get("html_url", ""),
            "created_at": a.get("created_at", ""),
        })
    return json.dumps({"alerts": alerts, "total": len(alerts)})


async def get_secret_scanning_alerts(repo: str, state: str = "open", per_page: int = 10) -> str:
    """Get secret scanning alerts for a repo."""
    owner = GITHUB_OWNER
    params: dict[str, Any] = {"state": state, "per_page": min(per_page, 30)}
    data = await _get(f"/repos/{owner}/{repo}/secret-scanning/alerts", params)
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)
    if not isinstance(data, list):
        return json.dumps({"alerts": [], "total": 0, "note": "Secret scanning may not be enabled"})

    alerts = []
    for a in data[:per_page]:
        alerts.append({
            "number": a.get("number"),
            "secret_type": a.get("secret_type_display_name", a.get("secret_type", "")),
            "state": a.get("state"),
            "resolution": a.get("resolution"),
            "push_protection_bypassed": a.get("push_protection_bypassed", False),
            "html_url": a.get("html_url", ""),
            "created_at": a.get("created_at", ""),
        })
    return json.dumps({"alerts": alerts, "total": len(alerts)})


async def get_dependabot_alerts(repo: str, state: str = "open", severity: str = "", per_page: int = 10) -> str:
    """Get Dependabot vulnerability alerts for a repo."""
    owner = GITHUB_OWNER
    params: dict[str, Any] = {"state": state, "per_page": min(per_page, 30)}
    if severity:
        params["severity"] = severity
    data = await _get(f"/repos/{owner}/{repo}/dependabot/alerts", params)
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)
    if not isinstance(data, list):
        return json.dumps({"alerts": [], "total": 0, "note": "Dependabot may not be enabled"})

    alerts = []
    for a in data[:per_page]:
        vuln = a.get("security_vulnerability", {})
        advisory = a.get("security_advisory", {})
        alerts.append({
            "number": a.get("number"),
            "state": a.get("state"),
            "severity": vuln.get("severity", ""),
            "package": vuln.get("package", {}).get("name", ""),
            "ecosystem": vuln.get("package", {}).get("ecosystem", ""),
            "vulnerable_range": vuln.get("vulnerable_version_range", ""),
            "patched_version": vuln.get("first_patched_version", {}).get("identifier", "no fix yet"),
            "cve_id": advisory.get("cve_id", ""),
            "summary": advisory.get("summary", "")[:200],
            "html_url": a.get("html_url", ""),
            "created_at": a.get("created_at", ""),
        })
    return json.dumps({"alerts": alerts, "total": len(alerts)})


# ═══════════════════════════════════════════════════════════════════
# LIGHTHOUSE AGENT tools — GitHub Deployments & Environments
# ═══════════════════════════════════════════════════════════════════

async def get_deployments(repo: str, environment: str = "", per_page: int = 5) -> str:
    """Get recent deployments for a repo."""
    owner = GITHUB_OWNER
    params: dict[str, Any] = {"per_page": min(per_page, 10)}
    if environment:
        params["environment"] = environment
    data = await _get(f"/repos/{owner}/{repo}/deployments", params)
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)
    if not isinstance(data, list):
        return json.dumps({"deployments": [], "total": 0})

    deployments = []
    for d in data[:per_page]:
        deployments.append({
            "id": d.get("id"),
            "environment": d.get("environment", ""),
            "ref": d.get("ref", ""),
            "sha": d.get("sha", "")[:8],
            "task": d.get("task", "deploy"),
            "creator": d.get("creator", {}).get("login", ""),
            "description": d.get("description", ""),
            "created_at": d.get("created_at", ""),
            "updated_at": d.get("updated_at", ""),
        })
    return json.dumps({"deployments": deployments, "total": len(deployments)})


async def get_deployment_statuses(repo: str, deployment_id: str) -> str:
    """Get status history for a specific deployment."""
    owner = GITHUB_OWNER
    data = await _get(f"/repos/{owner}/{repo}/deployments/{deployment_id}/statuses")
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)
    if not isinstance(data, list):
        return json.dumps({"statuses": []})

    statuses = []
    for s in data[:10]:
        statuses.append({
            "state": s.get("state", ""),
            "description": s.get("description", ""),
            "environment": s.get("environment", ""),
            "creator": s.get("creator", {}).get("login", ""),
            "target_url": s.get("target_url", ""),
            "created_at": s.get("created_at", ""),
        })
    return json.dumps({"deployment_id": deployment_id, "statuses": statuses})


async def get_environments(repo: str) -> str:
    """List deployment environments for a repo."""
    owner = GITHUB_OWNER
    data = await _get(f"/repos/{owner}/{repo}/environments")
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)

    envs = []
    for e in data.get("environments", []):
        rules = e.get("protection_rules", [])
        envs.append({
            "name": e.get("name", ""),
            "html_url": e.get("html_url", ""),
            "created_at": e.get("created_at", ""),
            "updated_at": e.get("updated_at", ""),
            "protection_rules": [
                {"type": r.get("type", ""), "wait_timer": r.get("wait_timer", 0)}
                for r in rules
            ],
        })
    return json.dumps({"environments": envs, "total": len(envs)})


# ═══════════════════════════════════════════════════════════════════
# FORGE AGENT tools — GitHub Repos, Branches, Tags, Releases
# ═══════════════════════════════════════════════════════════════════

async def get_repo_info(repo: str) -> str:
    """Get detailed information about a repository."""
    owner = GITHUB_OWNER
    data = await _get(f"/repos/{owner}/{repo}")
    if "error" in data:
        return json.dumps(data)

    return json.dumps({
        "name": data.get("name"),
        "full_name": data.get("full_name"),
        "description": data.get("description", ""),
        "visibility": data.get("visibility", ""),
        "default_branch": data.get("default_branch", "main"),
        "language": data.get("language", ""),
        "size_kb": data.get("size", 0),
        "open_issues": data.get("open_issues_count", 0),
        "forks": data.get("forks_count", 0),
        "stars": data.get("stargazers_count", 0),
        "topics": data.get("topics", []),
        "has_wiki": data.get("has_wiki", False),
        "has_pages": data.get("has_pages", False),
        "archived": data.get("archived", False),
        "pushed_at": data.get("pushed_at", ""),
        "created_at": data.get("created_at", ""),
        "html_url": data.get("html_url", ""),
        "license": data.get("license", {}).get("spdx_id", "none") if data.get("license") else "none",
    })


async def list_branches(repo: str, per_page: int = 10) -> str:
    """List branches for a repository."""
    owner = GITHUB_OWNER
    data = await _get(f"/repos/{owner}/{repo}/branches", {"per_page": min(per_page, 30)})
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)
    if not isinstance(data, list):
        return json.dumps({"branches": []})

    branches = []
    for b in data[:per_page]:
        branches.append({
            "name": b.get("name", ""),
            "protected": b.get("protected", False),
            "sha": b.get("commit", {}).get("sha", "")[:8],
        })
    return json.dumps({"branches": branches, "total": len(branches)})


async def list_tags(repo: str, per_page: int = 10) -> str:
    """List tags for a repository."""
    owner = GITHUB_OWNER
    data = await _get(f"/repos/{owner}/{repo}/tags", {"per_page": min(per_page, 30)})
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)
    if not isinstance(data, list):
        return json.dumps({"tags": []})

    tags = []
    for t in data[:per_page]:
        tags.append({
            "name": t.get("name", ""),
            "sha": t.get("commit", {}).get("sha", "")[:8],
        })
    return json.dumps({"tags": tags, "total": len(tags)})


async def list_releases(repo: str, per_page: int = 5) -> str:
    """List published releases for a repository."""
    owner = GITHUB_OWNER
    data = await _get(f"/repos/{owner}/{repo}/releases", {"per_page": min(per_page, 10)})
    if isinstance(data, dict) and "error" in data:
        return json.dumps(data)
    if not isinstance(data, list):
        return json.dumps({"releases": []})

    releases = []
    for r in data[:per_page]:
        releases.append({
            "tag_name": r.get("tag_name", ""),
            "name": r.get("name", ""),
            "draft": r.get("draft", False),
            "prerelease": r.get("prerelease", False),
            "author": r.get("author", {}).get("login", ""),
            "body": r.get("body", "")[:500],
            "assets": len(r.get("assets", [])),
            "html_url": r.get("html_url", ""),
            "published_at": r.get("published_at", ""),
            "created_at": r.get("created_at", ""),
        })
    return json.dumps({"releases": releases, "total": len(releases)})


# ═══════════════════════════════════════════════════════════════════
# TOOL DISPATCHER — maps tool names to functions
# ═══════════════════════════════════════════════════════════════════

TOOL_REGISTRY: dict[str, Any] = {
    # Pipeline
    "get_workflow_runs": get_workflow_runs,
    "get_workflow_run_jobs": get_workflow_run_jobs,
    # Sentinel
    "get_check_runs": get_check_runs,
    "get_pull_requests": get_pull_requests,
    # Compass
    "create_issue": create_issue,
    "list_issues": list_issues,
    "get_issue": get_issue,
    # Guardian (GHAS)
    "get_code_scanning_alerts": get_code_scanning_alerts,
    "get_secret_scanning_alerts": get_secret_scanning_alerts,
    "get_dependabot_alerts": get_dependabot_alerts,
    # Lighthouse (Deployments)
    "get_deployments": get_deployments,
    "get_deployment_statuses": get_deployment_statuses,
    "get_environments": get_environments,
    # Forge (Repos)
    "get_repo_info": get_repo_info,
    "list_branches": list_branches,
    "list_tags": list_tags,
    "list_releases": list_releases,
}


async def execute_tool(name: str, input_data: dict) -> str:
    """Dispatch a tool call to the correct GitHub API function."""
    func = TOOL_REGISTRY.get(name)
    if not func:
        return json.dumps({"error": f"Unknown tool: {name}"})

    try:
        return await func(**input_data)
    except TypeError as e:
        logger.error("Tool %s param error: %s", name, e)
        return json.dumps({"error": f"Invalid parameters for {name}: {e}"})
    except Exception as e:
        logger.error("Tool %s failed: %s", name, e, exc_info=True)
        return json.dumps({"error": f"Tool execution failed: {e}"})
