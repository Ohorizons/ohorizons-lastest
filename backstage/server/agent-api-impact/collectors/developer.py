"""
Developer Velocity Collector — GitHub User & Org Activity

Collects:
- User events (commits, PRs, reviews)
- PR velocity (merge time, review time)
- Org-level contributor activity
"""

import httpx
import logging
from datetime import datetime, timedelta

logger = logging.getLogger("collector.developer")

GITHUB_API = "https://api.github.com"


async def collect_org_activity(org: str, token: str, days: int = 30) -> dict:
    """Fetch org-level development activity from repos and PRs."""
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"}
    since = (datetime.utcnow() - timedelta(days=days)).isoformat() + "Z"

    async with httpx.AsyncClient(timeout=30) as client:
        try:
            # Fetch recent PRs across the org
            repos_res = await client.get(
                f"{GITHUB_API}/orgs/{org}/repos?sort=pushed&per_page=20", headers=headers
            )
            repos = repos_res.json() if repos_res.status_code == 200 else []

            total_prs = 0
            merged_prs = 0
            pr_merge_times = []
            pr_review_times = []
            contributors = set()

            for repo in repos[:10]:  # Top 10 most active repos
                repo_name = repo.get("full_name", "")
                # Fetch closed PRs
                prs_res = await client.get(
                    f"{GITHUB_API}/repos/{repo_name}/pulls?state=closed&sort=updated&direction=desc&per_page=50",
                    headers=headers,
                )
                if prs_res.status_code != 200:
                    continue
                prs = prs_res.json()

                for pr in prs:
                    created = pr.get("created_at", "")
                    merged_at = pr.get("merged_at")
                    if not created or datetime.fromisoformat(created.replace("Z", "+00:00")) < datetime.fromisoformat(since.replace("Z", "+00:00")):
                        continue

                    total_prs += 1
                    if pr.get("user", {}).get("login"):
                        contributors.add(pr["user"]["login"])

                    if merged_at:
                        merged_prs += 1
                        created_dt = datetime.fromisoformat(created.replace("Z", "+00:00"))
                        merged_dt = datetime.fromisoformat(merged_at.replace("Z", "+00:00"))
                        merge_hours = (merged_dt - created_dt).total_seconds() / 3600
                        if 0 < merge_hours < 720:
                            pr_merge_times.append(merge_hours)

            avg_merge_time = round(sum(pr_merge_times) / len(pr_merge_times), 1) if pr_merge_times else 0
            merge_rate = round(merged_prs / total_prs * 100, 1) if total_prs > 0 else 0

            return {
                "collected_at": datetime.utcnow().isoformat(),
                "period_days": days,
                "total_repos_analyzed": min(len(repos), 10),
                "total_prs": total_prs,
                "merged_prs": merged_prs,
                "merge_rate_pct": merge_rate,
                "avg_merge_time_hours": avg_merge_time,
                "unique_contributors": len(contributors),
                "top_contributors": list(contributors)[:10],
            }
        except Exception as e:
            logger.error("Failed to collect org activity: %s", e)
            return {"error": str(e), "collected_at": datetime.utcnow().isoformat()}


async def collect_user_activity(username: str, token: str) -> dict:
    """Fetch individual developer activity from GitHub events."""
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"}
    async with httpx.AsyncClient(timeout=30) as client:
        try:
            res = await client.get(f"{GITHUB_API}/users/{username}/events?per_page=100", headers=headers)
            if res.status_code != 200:
                return {"error": f"HTTP {res.status_code}", "collected_at": datetime.utcnow().isoformat()}

            events = res.json()
            push_events = [e for e in events if e["type"] == "PushEvent"]
            pr_events = [e for e in events if e["type"] == "PullRequestEvent"]
            review_events = [e for e in events if e["type"] == "PullRequestReviewEvent"]

            total_commits = sum(len(e.get("payload", {}).get("commits", [])) for e in push_events)
            prs_opened = len([e for e in pr_events if e.get("payload", {}).get("action") == "opened"])
            prs_merged = len([e for e in pr_events if e.get("payload", {}).get("pull_request", {}).get("merged")])
            reviews_done = len(review_events)
            repos = list(set(e["repo"]["name"] for e in events))

            return {
                "collected_at": datetime.utcnow().isoformat(),
                "username": username,
                "total_commits": total_commits,
                "prs_opened": prs_opened,
                "prs_merged": prs_merged,
                "reviews_done": reviews_done,
                "repos_contributed": len(repos),
                "top_repos": repos[:5],
            }
        except Exception as e:
            logger.error("Failed to collect user activity: %s", e)
            return {"error": str(e), "collected_at": datetime.utcnow().isoformat()}
