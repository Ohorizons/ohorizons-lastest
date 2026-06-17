"""
GitHub Plugin — GitHub REST API tools as Semantic Kernel functions.

Wraps the same GitHub API calls from agent-api but using @kernel_function.
"""

import os
import json
import logging
from typing import Annotated, Any

import httpx
from dotenv import load_dotenv
from semantic_kernel.functions import kernel_function

load_dotenv()

logger = logging.getLogger("plugins.github")

GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "")
GITHUB_API = "https://api.github.com"
GITHUB_OWNER = os.getenv("GITHUB_OWNER", "Ohorizons")


def _headers() -> dict[str, str]:
    h = {"Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"}
    if GITHUB_TOKEN:
        h["Authorization"] = f"Bearer {GITHUB_TOKEN}"
    return h


async def _get(path: str, params: dict | None = None) -> Any:
    url = f"{GITHUB_API}{path}"
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(url, headers=_headers(), params=params or {})
        if r.status_code == 200:
            return r.json()
        return {"error": f"GitHub API {r.status_code}", "message": r.text[:300]}


async def _post(path: str, body: dict) -> Any:
    url = f"{GITHUB_API}{path}"
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.post(url, headers=_headers(), json=body)
        if r.status_code in (200, 201):
            return r.json()
        return {"error": f"GitHub API {r.status_code}", "message": r.text[:300]}


class GitHubPlugin:
    """GitHub REST API tools for Pipeline, Sentinel, and Compass agents."""

    # ── Pipeline Agent tools ───────────────────────────────────────

    @kernel_function(
        name="get_workflow_runs",
        description="Get recent GitHub Actions workflow runs for a repository. Can filter by status (completed, failure, success, in_progress).",
    )
    async def get_workflow_runs(
        self,
        repo: Annotated[str, "Repository name (e.g., 'my-service')"],
        status: Annotated[str, "Filter by status: completed, failure, success, in_progress"] = "",
        per_page: Annotated[int, "Number of runs to return (max 10)"] = 5,
    ) -> str:
        params: dict[str, Any] = {"per_page": per_page}
        if status:
            params["status"] = status

        data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/actions/runs", params)
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

    @kernel_function(
        name="get_workflow_run_jobs",
        description="Get jobs and steps for a specific workflow run. Shows which steps passed/failed with details.",
    )
    async def get_workflow_run_jobs(
        self,
        repo: Annotated[str, "Repository name"],
        run_id: Annotated[str, "Workflow run ID from get_workflow_runs"],
    ) -> str:
        data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/actions/runs/{run_id}/jobs")
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

    # ── Sentinel Agent tools ───────────────────────────────────────

    @kernel_function(
        name="get_check_runs",
        description="Get CI check runs (test results, linting, build status) for a git ref (branch or commit).",
    )
    async def get_check_runs(
        self,
        repo: Annotated[str, "Repository name"],
        ref: Annotated[str, "Git ref — branch name or commit SHA"] = "main",
    ) -> str:
        data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/commits/{ref}/check-runs")
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

    @kernel_function(
        name="get_pull_requests",
        description="List pull requests for a repository. Shows PR status, branches, and review state.",
    )
    async def get_pull_requests(
        self,
        repo: Annotated[str, "Repository name"],
        state: Annotated[str, "PR state: open, closed, all"] = "open",
        per_page: Annotated[int, "Number of PRs to return"] = 5,
    ) -> str:
        data = await _get(
            f"/repos/{GITHUB_OWNER}/{repo}/pulls",
            {"state": state, "per_page": per_page},
        )
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

    # ── Compass Agent tools ────────────────────────────────────────

    @kernel_function(
        name="create_issue",
        description="Create a GitHub Issue with title, body (markdown), and optional labels.",
    )
    async def create_issue(
        self,
        repo: Annotated[str, "Repository name"],
        title: Annotated[str, "Issue title"],
        body: Annotated[str, "Issue body in markdown format"],
        labels: Annotated[str, "Comma-separated labels (e.g., 'user-story,epic:auth')"] = "",
    ) -> str:
        payload: dict[str, Any] = {"title": title, "body": body}
        if labels:
            payload["labels"] = [l.strip() for l in labels.split(",")]

        data = await _post(f"/repos/{GITHUB_OWNER}/{repo}/issues", payload)
        if "error" in data:
            return json.dumps(data)

        return json.dumps({
            "number": data["number"],
            "title": data["title"],
            "html_url": data["html_url"],
            "state": data["state"],
            "created_at": data["created_at"],
        })

    @kernel_function(
        name="list_issues",
        description="List GitHub Issues for a repository. Can filter by state and labels.",
    )
    async def list_issues(
        self,
        repo: Annotated[str, "Repository name"],
        state: Annotated[str, "Issue state: open, closed, all"] = "open",
        labels: Annotated[str, "Comma-separated label filter"] = "",
        per_page: Annotated[int, "Number of issues to return"] = 10,
    ) -> str:
        params: dict[str, Any] = {"state": state, "per_page": per_page}
        if labels:
            params["labels"] = labels

        data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/issues", params)
        if "error" in data:
            return json.dumps(data)

        issues = []
        for issue in data[:per_page]:
            if "pull_request" in issue:
                continue
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

    @kernel_function(
        name="get_issue",
        description="Get full details of a specific GitHub Issue by number.",
    )
    async def get_issue(
        self,
        repo: Annotated[str, "Repository name"],
        issue_number: Annotated[int, "Issue number"],
    ) -> str:
        data = await _get(f"/repos/{GITHUB_OWNER}/{repo}/issues/{issue_number}")
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
