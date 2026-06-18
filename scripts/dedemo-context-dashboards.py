#!/usr/bin/env python3
"""One-shot transform: convert the ported Context Platform dashboards from the
demo edition (TestData + Acme labels + hardcoded Azure resource IDs) into the
final, client-implementable edition.

What it does to every JSON in grafana/dashboards/context-platform/:
  * strips ``acme`` / ``demo`` / ``sympol`` from ``tags``
  * rewrites ``__comment`` into a production note
  * removes Acme / demo wording from ``description``
  * replaces the hardcoded App Insights resource ID with the ``${appInsightsResource}``
    dashboard variable
  * injects an ``appInsightsResource`` textbox template variable so the client
    binds their own Application Insights component

Idempotent: safe to run more than once.
"""
from __future__ import annotations

import json
import pathlib
import re

DASH_DIR = pathlib.Path(__file__).resolve().parent.parent / "grafana" / "dashboards" / "context-platform"

RESOURCE_VAR = "${appInsightsResource}"

# Matches the full App Insights resource ID in any case, including the half-rewritten
# form whose tail was already replaced with "your App Insights component".
RESOURCE_RE = re.compile(
    r"/subscriptions/[0-9a-fA-F-]+/resourceGroups/[^/\"]+/providers/"
    r"[Mm]icrosoft\.[Ii]nsights/components/[^\"]+"
)
SUBSCRIPTION_RE = re.compile(r"REDACTED-SUBSCRIPTION-ID")
RG_RE = re.compile(r"rg-openhorizons-example")

PROD_COMMENT = (
    "Context Platform reference dashboard. Bind the App Insights resource via the "
    "'appInsightsResource' dashboard variable. Panels carry the real Azure Monitor / "
    "Prometheus query in their description; partners wire each target to the client "
    "datasource during onboarding."
)

DEMO_TAGS = {"acme", "demo", "sympol"}

APPINSIGHTS_VAR = {
    "type": "textbox",
    "name": "appInsightsResource",
    "label": "App Insights resource ID",
    "description": (
        "Azure resource ID of your Application Insights component, e.g. "
        "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Insights/components/<name>"
    ),
    "query": "",
    "current": {"text": "", "value": ""},
    "options": [],
    "hide": 0,
    "skipUrlSync": False,
}


def clean_text(value: str) -> str:
    value = RESOURCE_RE.sub(RESOURCE_VAR, value)
    value = value.replace("appi-openhorizons-example", "your App Insights component")
    value = SUBSCRIPTION_RE.sub("${subscription}", value)
    value = RG_RE.sub("your resource group", value)
    # Drop Acme demo-agent phrasing, keep the platform-agents statement.
    value = re.sub(r"\(17 platform \+ 5 [Aa]cme[^)]*\)", "(platform + tenant agents)", value)
    value = value.replace("17 platform Copilot agents + 5 Acme demo agents", "the platform Copilot agents")
    value = value.replace("5 Acme demo agents", "tenant agents")
    value = value.replace("Acme demo agents", "tenant agents")
    value = value.replace("Acme agents", "tenant agents")
    value = value.replace("Acme agent", "tenant agent")
    value = value.replace("Demo data via TestData; wire to App Insights once telemetry is seeded.", "Bind to App Insights once telemetry is flowing.")
    value = value.replace("Acme DEV", "your")
    # Genericise any remaining demo-client tokens (CSV sample rows, panel aliases)
    # into a neutral 'tenant' placeholder that partners replace per client.
    value = re.sub(r"[Aa]cme", "tenant", value)
    value = re.sub(r"\s{2,}", " ", value).strip()
    return value


def walk(node):
    """Recursively clean every string value in the dashboard tree."""
    if isinstance(node, dict):
        return {k: walk(v) for k, v in node.items()}
    if isinstance(node, list):
        return [walk(v) for v in node]
    if isinstance(node, str):
        return clean_text(node)
    return node


def transform(path: pathlib.Path) -> bool:
    data = json.loads(path.read_text())

    data["__comment"] = PROD_COMMENT

    if isinstance(data.get("description"), str):
        data["description"] = clean_text(data["description"])

    if isinstance(data.get("tags"), list):
        data["tags"] = [t for t in data["tags"] if t.lower() not in DEMO_TAGS]

    # Clean every nested string (panel descriptions, targets, resource arrays).
    data = walk(data)

    # Inject the appInsightsResource variable if a panel references it.
    serialized = json.dumps(data)
    if RESOURCE_VAR in serialized:
        templating = data.setdefault("templating", {})
        var_list = templating.setdefault("list", [])
        names = {v.get("name") for v in var_list if isinstance(v, dict)}
        if "appInsightsResource" not in names:
            var_list.insert(0, json.loads(json.dumps(APPINSIGHTS_VAR)))

    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    return True


def main() -> None:
    files = sorted(DASH_DIR.glob("*.json"))
    if not files:
        raise SystemExit(f"no dashboards found in {DASH_DIR}")
    for path in files:
        transform(path)
        print(f"cleaned {path.name}")


if __name__ == "__main__":
    main()
