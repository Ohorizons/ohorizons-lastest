#!/usr/bin/env bash
#
# uninstall-user-mcp-ecosystem.sh
#
# Removes the per-user MCP Ecosystem service installed by
# scripts/install-user-mcp-ecosystem.sh.
#
# By default it stops the service, unloads the LaunchAgent, and removes the
# VS Code user mcp.json entry. Pass --purge to also delete the install
# directory (including the cached data volume reference and your .env).
#
# Usage:
#   scripts/uninstall-user-mcp-ecosystem.sh [--purge]
#
set -euo pipefail

SERVICE_NAME="mcp-ecosystem"
INSTALL_DIR="${HOME}/.local/${SERVICE_NAME}"
STACK_DIR="${INSTALL_DIR}/stack"

LAUNCH_USER="$(id -un)"
LAUNCH_LABEL="com.${LAUNCH_USER}.${SERVICE_NAME}"
LAUNCH_AGENT_PLIST="${HOME}/Library/LaunchAgents/${LAUNCH_LABEL}.plist"
GUI_DOMAIN="gui/$(id -u)"

PURGE="false"
[[ "${1:-}" == "--purge" ]] && PURGE="true"

log()  { printf '\033[0;34m[uninstall]\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m[ ok ]\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m[warn]\033[0m %s\n' "$*" >&2; }

# Unload the LaunchAgent.
if launchctl print "${GUI_DOMAIN}/${LAUNCH_LABEL}" >/dev/null 2>&1; then
  launchctl bootout "${GUI_DOMAIN}/${LAUNCH_LABEL}" >/dev/null 2>&1 || true
  ok "LaunchAgent ${LAUNCH_LABEL} unloaded."
fi
if [[ -f "${LAUNCH_AGENT_PLIST}" ]]; then
  rm -f "${LAUNCH_AGENT_PLIST}"
  ok "Removed ${LAUNCH_AGENT_PLIST}"
fi

# Stop the container.
if [[ -f "${STACK_DIR}/docker-compose.yml" ]] && command -v docker >/dev/null 2>&1; then
  if [[ "${PURGE}" == "true" ]]; then
    ( cd "${STACK_DIR}" && docker compose down -v ) || true
    ok "Stopped service and removed data volume."
  else
    ( cd "${STACK_DIR}" && docker compose down ) || true
    ok "Stopped service (data volume kept)."
  fi
fi

# Remove the VS Code user mcp.json entry.
remove_vscode() {
  local mcp_json="$1"
  [[ -f "${mcp_json}" ]] || return 0
  MCP_JSON="${mcp_json}" python3 - <<'PY'
import json, os, sys
path = os.environ["MCP_JSON"]
try:
    with open(path) as f:
        data = json.load(f)
except Exception:
    sys.exit(0)
servers = data.get("servers", {})
if servers.pop("mcp-ecosystem", None) is not None:
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print(f"  removed mcp-ecosystem from {path}")
PY
}
remove_vscode "${HOME}/Library/Application Support/Code - Insiders/User/mcp.json" || true
remove_vscode "${HOME}/Library/Application Support/Code/User/mcp.json" || true

# Optionally purge the install directory.
if [[ "${PURGE}" == "true" ]]; then
  rm -rf "${INSTALL_DIR}"
  ok "Removed ${INSTALL_DIR}"
else
  log "Install directory kept at ${INSTALL_DIR} (use --purge to delete)."
fi

ok "Uninstall complete."
