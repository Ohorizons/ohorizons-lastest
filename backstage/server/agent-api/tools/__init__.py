"""Tools package — unified tool dispatcher for all tool sources."""

import json
import logging

from .github_api import execute_tool as _github_execute
from .backstage_mcp import execute_backstage_tool as _backstage_execute
from .mcp_ecosystem import execute_ecosystem_tool as _ecosystem_execute

logger = logging.getLogger("tools")

# Prefixes for routing
GITHUB_TOOLS = {
    "get_workflow_runs", "get_workflow_run_jobs",
    "get_check_runs", "get_pull_requests",
    "create_issue", "list_issues", "get_issue",
    # Guardian (GHAS)
    "get_code_scanning_alerts", "get_secret_scanning_alerts", "get_dependabot_alerts",
    # Lighthouse (Deployments)
    "get_deployments", "get_deployment_statuses", "get_environments",
    # Forge (Repos)
    "get_repo_info", "list_branches", "list_tags", "list_releases",
}

BACKSTAGE_TOOLS = {
    "backstage_catalog_search", "backstage_list_templates",
    "backstage_list_tools", "backstage_call_tool",
}

ECOSYSTEM_TOOLS = {
    "ecosystem_list_tools", "ecosystem_call_tool",
    "search_backstage_docs", "search_copilot_docs",
    "search_anthropic_docs", "get_spec_kit_methodology",
    "search_awesome_copilot",
}


async def execute_tool(name: str, input_data: dict) -> str:
    """Unified tool dispatcher — routes to GitHub, Backstage MCP, or Ecosystem."""
    logger.info("Dispatching tool: %s", name)
    if name in GITHUB_TOOLS:
        return await _github_execute(name, input_data)
    if name in BACKSTAGE_TOOLS:
        return await _backstage_execute(name, input_data)
    if name in ECOSYSTEM_TOOLS:
        return await _ecosystem_execute(name, input_data)

    # Fallback: try GitHub first, then Backstage, then Ecosystem
    logger.warning("Unknown tool '%s' — trying all dispatchers", name)
    result = await _github_execute(name, input_data)
    if "Unknown tool" not in result:
        return result
    result = await _backstage_execute(name, input_data)
    if "Unknown" not in result:
        return result
    return await _ecosystem_execute(name, input_data)

