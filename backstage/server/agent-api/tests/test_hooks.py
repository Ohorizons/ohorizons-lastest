"""Unit tests for the pre/post tool-use governance hooks.

Run from the agent-api root:

    python3 -m unittest tests.test_hooks -v

No third-party dependencies required (stdlib unittest only).
"""

from __future__ import annotations

import os
import sys
import unittest

# Make the agent-api root importable when run from anywhere.
_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _ROOT not in sys.path:
    sys.path.insert(0, _ROOT)

from middleware.hooks import (  # noqa: E402
    ToolClass,
    ToolHookPipeline,
    classify_tool,
)


class TestClassification(unittest.TestCase):
    def test_read_only_prefixes(self):
        for name in ("get_pr_files", "list_repos", "search_code", "describe_pod"):
            self.assertEqual(classify_tool(name), ToolClass.READ_ONLY, name)

    def test_mutating_prefixes(self):
        for name in ("create_issue", "deploy_service", "apply_config",
                     "delete_branch", "merge_pr", "provision_cluster"):
            self.assertEqual(classify_tool(name), ToolClass.MUTATING, name)

    def test_github_api_override_is_mutating(self):
        self.assertEqual(classify_tool("github_api"), ToolClass.MUTATING)

    def test_unknown_when_no_match(self):
        self.assertEqual(classify_tool("frobnicate"), ToolClass.UNKNOWN)


class TestPreHook(unittest.TestCase):
    def setUp(self):
        self.hooks = ToolHookPipeline(enforce=True)

    def test_read_only_allowed_low_risk(self):
        r = self.hooks.pre_tool_use("orchestrator", "get_pr_files", {"repo": "x"})
        self.assertTrue(r.allowed)
        self.assertEqual(r.risk, "low")

    def test_mutating_allowed_medium_risk(self):
        r = self.hooks.pre_tool_use("forge", "create_issue", {"title": "x"})
        self.assertTrue(r.allowed)
        self.assertEqual(r.risk, "medium")

    def test_rm_rf_blocked(self):
        r = self.hooks.pre_tool_use("forge", "deploy_service", {"cmd": "rm -rf /"})
        self.assertFalse(r.allowed)
        self.assertEqual(r.risk, "high")

    def test_path_traversal_blocked(self):
        r = self.hooks.pre_tool_use("pipeline", "apply_config",
                                    {"path": "../../etc/passwd"})
        self.assertFalse(r.allowed)

    def test_force_push_blocked(self):
        r = self.hooks.pre_tool_use("forge", "push_branch",
                                    {"flags": "git push --force origin main"})
        self.assertFalse(r.allowed)

    def test_terraform_destroy_blocked(self):
        r = self.hooks.pre_tool_use("forge", "apply_infra",
                                    {"cmd": "terraform destroy -auto-approve"})
        self.assertFalse(r.allowed)

    def test_no_verify_blocked(self):
        r = self.hooks.pre_tool_use("pipeline", "push_branch",
                                    {"cmd": "git commit --no-verify"})
        self.assertFalse(r.allowed)


class TestEnforcementOff(unittest.TestCase):
    def test_dangerous_pattern_warns_not_blocks(self):
        hooks = ToolHookPipeline(enforce=False)
        r = hooks.pre_tool_use("forge", "deploy_service", {"cmd": "rm -rf /"})
        self.assertTrue(r.allowed)  # allowed in warn mode
        self.assertTrue(r.reason.startswith("warn:"))


class TestPostHook(unittest.TestCase):
    def setUp(self):
        self.hooks = ToolHookPipeline(enforce=True)

    def test_github_token_redacted(self):
        res = self.hooks.post_tool_use(
            "guardian", "get_secrets", "token=ghp_ABCDEFGHIJKLMNOPQRSTUVWX")
        self.assertNotIn("ghp_ABCDEFGHIJKLMNOPQRSTUVWX", res.result)
        self.assertGreaterEqual(res.redactions, 1)

    def test_multiple_secrets_redacted(self):
        payload = "api_key: sk-abcdefghijklmnopqrstuvwxyz and token=ghp_ABCDEFGHIJKLMNOPQRSTUV"
        res = self.hooks.post_tool_use("guardian", "get_config", payload)
        self.assertNotIn("sk-abcdefghijklmnopqrstuvwxyz", res.result)
        self.assertNotIn("ghp_ABCDEFGHIJKLMNOPQRSTUV", res.result)
        self.assertGreaterEqual(res.redactions, 2)

    def test_oversized_result_truncated(self):
        res = self.hooks.post_tool_use("sentinel", "get_logs", "A" * 30_000)
        self.assertTrue(res.truncated)
        self.assertLess(len(res.result), 30_000)

    def test_clean_result_untouched(self):
        res = self.hooks.post_tool_use("orchestrator", "get_pr_files", "all good")
        self.assertEqual(res.result, "all good")
        self.assertEqual(res.redactions, 0)
        self.assertFalse(res.truncated)


class TestAudit(unittest.TestCase):
    def test_summary_and_recent(self):
        hooks = ToolHookPipeline(enforce=True)
        hooks.pre_tool_use("orchestrator", "get_pr_files", {})
        hooks.pre_tool_use("forge", "deploy_service", {"cmd": "rm -rf /"})
        summary = hooks.summary()
        self.assertGreaterEqual(summary["counts"]["allow"], 1)
        self.assertGreaterEqual(summary["counts"]["deny"], 1)
        recent = hooks.recent(limit=10)
        self.assertLessEqual(len(recent), 10)
        self.assertTrue(all("decision" in e for e in recent))

    def test_recent_filtered_by_agent(self):
        hooks = ToolHookPipeline(enforce=True)
        hooks.pre_tool_use("orchestrator", "get_pr_files", {})
        hooks.pre_tool_use("forge", "create_issue", {})
        forge_only = hooks.recent(limit=10, agent="forge")
        self.assertTrue(all(e["agent"] == "forge" for e in forge_only))


if __name__ == "__main__":
    unittest.main(verbosity=2)
