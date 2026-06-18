#!/usr/bin/env bash
# Render the foundry-agents source ConfigMap from local Python files.
# Use this for source-mounted deploy (no custom image required).
set -euo pipefail

NS="${NS:-ai-services}"
CM_NAME="${CM_NAME:-foundry-agents-source}"
SRC_DIR="$(cd "$(dirname "$0")/../../../../new-features/foundry/agents-service" && pwd)"
REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"

echo "Source: $SRC_DIR"
echo "Namespace: $NS"
echo "ConfigMap: $CM_NAME"

oc create configmap "$CM_NAME" \
  -n "$NS" \
  --from-file="__init__.py=$SRC_DIR/app/__init__.py" \
  --from-file="config.py=$SRC_DIR/app/config.py" \
  --from-file="agents.py=$SRC_DIR/app/agents.py" \
  --from-file="azure_openai.py=$SRC_DIR/app/azure_openai.py" \
  --from-file="cosmos_memory.py=$SRC_DIR/app/cosmos_memory.py" \
  --from-file="main.py=$SRC_DIR/app/main.py" \
  --from-file="toolbox.py=$SRC_DIR/app/toolbox.py" \
  --from-file="a2a.py=$SRC_DIR/app/a2a.py" \
  --from-file="cache.py=$SRC_DIR/app/cache.py" \
  --from-file="tool_hooks.py=$SRC_DIR/app/tool_hooks.py" \
  --from-file="telemetry.py=$SRC_DIR/app/telemetry.py" \
  --from-file="purview_audit.py=$SRC_DIR/app/purview_audit.py" \
  --from-file="requirements.txt=$SRC_DIR/requirements.txt" \
  --from-file="mcp-config.json=$REPO_ROOT/mcp-servers/mcp-config.json" \
  --dry-run=client -o yaml | oc apply -f -

echo "✅ ConfigMap $CM_NAME applied to namespace $NS"
