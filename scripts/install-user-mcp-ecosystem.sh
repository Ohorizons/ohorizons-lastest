#!/usr/bin/env bash
#
# install-user-mcp-ecosystem.sh
#
# Installs the Open Horizons MCP Ecosystem server as a per-USER, always-on
# local service so it is available to every VS Code workspace — not just this
# repository checkout.
#
# What it provisions (macOS):
#   ~/.local/mcp-ecosystem/
#     ├── stack/docker-compose.yml   # localhost-bound Docker service (:3100)
#     ├── .env                       # port / cache / optional GH_TOKEN
#     ├── bin/{start,stop,status}.sh # wrapper commands
#     └── logs/                      # wrapper + container logs
#   ~/Library/LaunchAgents/com.<user>.mcp-ecosystem.plist  # starts at login
#
# It is idempotent: re-running updates files and restarts the service without
# clobbering an existing .env (so your GH_TOKEN is preserved).
#
# Usage:
#   scripts/install-user-mcp-ecosystem.sh [--port N] [--image REF]
#                                         [--gh-token TOKEN] [--no-register-vscode]
#
# Endpoint after install:  http://localhost:<port>/mcp   (default port 3100)
# Health:                  http://localhost:<port>/health
#
set -euo pipefail

# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #
DEFAULT_IMAGE="ghcr.io/ohorizons/mcp-ecosystem:v7.2.4"
DEFAULT_PORT="3100"

SERVICE_NAME="mcp-ecosystem"
INSTALL_DIR="${HOME}/.local/${SERVICE_NAME}"
STACK_DIR="${INSTALL_DIR}/stack"
BIN_DIR="${INSTALL_DIR}/bin"
LOG_DIR="${INSTALL_DIR}/logs"
ENV_FILE="${STACK_DIR}/.env"
COMPOSE_FILE="${STACK_DIR}/docker-compose.yml"

LAUNCH_USER="$(id -un)"
LAUNCH_LABEL="com.${LAUNCH_USER}.${SERVICE_NAME}"
LAUNCH_AGENT_DIR="${HOME}/Library/LaunchAgents"
LAUNCH_AGENT_PLIST="${LAUNCH_AGENT_DIR}/${LAUNCH_LABEL}.plist"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_DIR="${REPO_ROOT}/mcp-servers"

PORT="${DEFAULT_PORT}"
IMAGE="${MCP_ECOSYSTEM_IMAGE:-${DEFAULT_IMAGE}}"
GH_TOKEN_ARG=""
REGISTER_VSCODE="true"

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
log()  { printf '\033[0;34m[install]\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m[ ok ]\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m[warn]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[0;31m[fail]\033[0m %s\n' "$*" >&2; }

usage() {
  sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
}

# --------------------------------------------------------------------------- #
# Parse args
# --------------------------------------------------------------------------- #
while [[ $# -gt 0 ]]; do
  case "$1" in
    --port)               PORT="${2:?--port needs a value}"; shift 2 ;;
    --image)              IMAGE="${2:?--image needs a value}"; shift 2 ;;
    --gh-token)           GH_TOKEN_ARG="${2:?--gh-token needs a value}"; shift 2 ;;
    --no-register-vscode) REGISTER_VSCODE="false"; shift ;;
    -h|--help)            usage ;;
    *) err "Unknown argument: $1"; exit 2 ;;
  esac
done

# --------------------------------------------------------------------------- #
# Pre-flight
# --------------------------------------------------------------------------- #
if [[ "$(uname -s)" != "Darwin" ]]; then
  err "This installer targets macOS (LaunchAgent). Detected: $(uname -s)."
  err "On Linux use a systemd --user unit wrapping the same compose stack."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  err "Docker CLI not found. Install Docker Desktop first: https://docker.com/products/docker-desktop"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  warn "Docker daemon is not running. Attempting to start Docker Desktop..."
  open -a Docker >/dev/null 2>&1 || true
  for _ in $(seq 1 30); do
    docker info >/dev/null 2>&1 && break
    sleep 2
  done
  if ! docker info >/dev/null 2>&1; then
    err "Docker daemon did not become ready. Start Docker Desktop and re-run."
    exit 1
  fi
fi
ok "Docker is available."

# --------------------------------------------------------------------------- #
# Resolve the image: prefer the requested image, else build from repo source.
# --------------------------------------------------------------------------- #
log "Resolving server image: ${IMAGE}"
if docker pull "${IMAGE}" >/dev/null 2>&1; then
  ok "Pulled image ${IMAGE}"
elif docker image inspect "${IMAGE}" >/dev/null 2>&1; then
  ok "Using cached local image ${IMAGE}"
elif [[ -f "${SOURCE_DIR}/Dockerfile" ]]; then
  warn "Could not pull ${IMAGE}. Building from source: ${SOURCE_DIR}"
  docker build -t "${SERVICE_NAME}:local" "${SOURCE_DIR}"
  IMAGE="${SERVICE_NAME}:local"
  ok "Built local image ${IMAGE}"
else
  err "Image ${IMAGE} is unavailable and no source Dockerfile found at ${SOURCE_DIR}."
  exit 1
fi

# --------------------------------------------------------------------------- #
# Lay out the per-user install directory
# --------------------------------------------------------------------------- #
log "Provisioning ${INSTALL_DIR}"
mkdir -p "${STACK_DIR}" "${BIN_DIR}" "${LOG_DIR}" "${LAUNCH_AGENT_DIR}"

# docker-compose.yml — localhost-bound, auto-restarting, health-checked.
cat > "${COMPOSE_FILE}" <<'COMPOSE_EOF'
# Managed by scripts/install-user-mcp-ecosystem.sh — regenerated on each run.
# Per-user, always-on MCP Ecosystem server bound to localhost only.
services:
  mcp-ecosystem:
    image: ${MCP_ECOSYSTEM_IMAGE:-ghcr.io/ohorizons/mcp-ecosystem:v7.2.4}
    container_name: mcp-ecosystem
    restart: unless-stopped
    ports:
      - "127.0.0.1:${MCP_ECOSYSTEM_PORT:-3100}:3100"
    environment:
      - PORT=3100
      - CACHE_DIR=/app/cache
      - GH_TOKEN=${GH_TOKEN:-}
      - CACHE_TTL_MS=${CACHE_TTL_MS:-3600000}
    volumes:
      - mcp-cache:/app/cache
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://127.0.0.1:3100/health"]
      interval: 30s
      timeout: 5s
      start_period: 10s
      retries: 3

volumes:
  mcp-cache:
    driver: local
COMPOSE_EOF
ok "Wrote ${COMPOSE_FILE}"

# .env — created once (preserves any existing GH_TOKEN). Image/port refreshed.
if [[ ! -f "${ENV_FILE}" ]]; then
  cat > "${ENV_FILE}" <<ENV_EOF
# Compose interpolation + container env for the user MCP Ecosystem service.
# This file is created once; re-running the installer preserves it.
MCP_ECOSYSTEM_IMAGE=${IMAGE}
MCP_ECOSYSTEM_PORT=${PORT}
# Optional: a GitHub token raises upstream rate limits (60 -> 5000 req/h).
GH_TOKEN=${GH_TOKEN_ARG}
CACHE_TTL_MS=3600000
ENV_EOF
  chmod 600 "${ENV_FILE}"
  ok "Wrote ${ENV_FILE}"
else
  # Refresh image + port in place; never touch GH_TOKEN.
  /usr/bin/sed -i '' -E "s|^MCP_ECOSYSTEM_IMAGE=.*|MCP_ECOSYSTEM_IMAGE=${IMAGE}|" "${ENV_FILE}" 2>/dev/null || true
  /usr/bin/sed -i '' -E "s|^MCP_ECOSYSTEM_PORT=.*|MCP_ECOSYSTEM_PORT=${PORT}|" "${ENV_FILE}" 2>/dev/null || true
  if [[ -n "${GH_TOKEN_ARG}" ]]; then
    /usr/bin/sed -i '' -E "s|^GH_TOKEN=.*|GH_TOKEN=${GH_TOKEN_ARG}|" "${ENV_FILE}" 2>/dev/null || true
  fi
  ok "Updated ${ENV_FILE} (image/port refreshed, GH_TOKEN preserved)"
fi

# --------------------------------------------------------------------------- #
# Wrapper scripts
# --------------------------------------------------------------------------- #
cat > "${BIN_DIR}/start.sh" <<'START_EOF'
#!/usr/bin/env bash
# Starts the user MCP Ecosystem service. Idempotent; safe to run at login.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

SERVICE_DIR="${HOME}/.local/mcp-ecosystem"
STACK_DIR="${SERVICE_DIR}/stack"
LOG_DIR="${SERVICE_DIR}/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/start.log"
ts() { date '+%Y-%m-%dT%H:%M:%S%z'; }

{
  echo "[$(ts)] Starting mcp-ecosystem user service."

  if ! command -v docker >/dev/null 2>&1; then
    echo "[$(ts)] Docker CLI not found; aborting."
    exit 0
  fi

  # Launch Docker Desktop if installed and not yet ready.
  open -a Docker >/dev/null 2>&1 || true
  ready=0
  for _ in $(seq 1 60); do
    if docker info >/dev/null 2>&1; then ready=1; break; fi
    sleep 5
  done
  if [[ "${ready}" -ne 1 ]]; then
    echo "[$(ts)] Docker did not become ready after 5 minutes; aborting."
    exit 0
  fi

  PORT="$(grep -E '^MCP_ECOSYSTEM_PORT=' "${STACK_DIR}/.env" 2>/dev/null | cut -d= -f2)"
  PORT="${PORT:-3100}"

  cd "${STACK_DIR}"
  docker compose up -d

  # Wait for health.
  for _ in $(seq 1 30); do
    if curl -fsS "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then
      echo "[$(ts)] Healthy at http://localhost:${PORT}/mcp"
      exit 0
    fi
    sleep 2
  done
  echo "[$(ts)] Started but health check did not pass yet; check 'docker logs mcp-ecosystem'."
} >> "${LOG_FILE}" 2>&1
START_EOF

cat > "${BIN_DIR}/stop.sh" <<'STOP_EOF'
#!/usr/bin/env bash
# Stops the user MCP Ecosystem container (keeps cached data volume).
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
cd "${HOME}/.local/mcp-ecosystem/stack"
docker compose down
STOP_EOF

cat > "${BIN_DIR}/status.sh" <<'STATUS_EOF'
#!/usr/bin/env bash
# Shows container + health status for the user MCP Ecosystem service.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
STACK_DIR="${HOME}/.local/mcp-ecosystem/stack"
PORT="$(grep -E '^MCP_ECOSYSTEM_PORT=' "${STACK_DIR}/.env" 2>/dev/null | cut -d= -f2)"
PORT="${PORT:-3100}"
cd "${STACK_DIR}"
docker compose ps
echo "---"
if curl -fsS "http://127.0.0.1:${PORT}/health" 2>/dev/null; then
  echo
  echo "Endpoint: http://localhost:${PORT}/mcp"
else
  echo "Health: not responding on :${PORT}"
fi
STATUS_EOF

chmod +x "${BIN_DIR}/start.sh" "${BIN_DIR}/stop.sh" "${BIN_DIR}/status.sh"
ok "Wrote wrapper scripts in ${BIN_DIR}"

# --------------------------------------------------------------------------- #
# LaunchAgent — starts the service at login and re-checks hourly (self-heal).
# --------------------------------------------------------------------------- #
cat > "${LAUNCH_AGENT_PLIST}" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LAUNCH_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${BIN_DIR}/start.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>StandardOutPath</key>
    <string>${LOG_DIR}/launchagent.out.log</string>
    <key>StandardErrorPath</key>
    <string>${LOG_DIR}/launchagent.err.log</string>
</dict>
</plist>
PLIST_EOF
ok "Wrote ${LAUNCH_AGENT_PLIST}"

# (Re)load the LaunchAgent.
GUI_DOMAIN="gui/$(id -u)"
launchctl bootout "${GUI_DOMAIN}/${LAUNCH_LABEL}" >/dev/null 2>&1 || true
launchctl bootstrap "${GUI_DOMAIN}" "${LAUNCH_AGENT_PLIST}"
launchctl enable "${GUI_DOMAIN}/${LAUNCH_LABEL}" >/dev/null 2>&1 || true
ok "LaunchAgent ${LAUNCH_LABEL} loaded (starts at login)."

# --------------------------------------------------------------------------- #
# Start now and verify health.
# --------------------------------------------------------------------------- #
log "Starting the service now..."
launchctl kickstart -k "${GUI_DOMAIN}/${LAUNCH_LABEL}" >/dev/null 2>&1 || "${BIN_DIR}/start.sh"

healthy="false"
for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then
    healthy="true"; break
  fi
  sleep 2
done

if [[ "${healthy}" == "true" ]]; then
  ok "Service healthy at http://localhost:${PORT}/mcp"
else
  warn "Service not healthy yet. Inspect: cat ${LOG_DIR}/start.log ; docker logs mcp-ecosystem"
fi

# --------------------------------------------------------------------------- #
# Register in VS Code (Insiders + stable) user mcp.json so ALL workspaces see it.
# --------------------------------------------------------------------------- #
if [[ "${REGISTER_VSCODE}" == "true" ]]; then
  register_vscode() {
    local mcp_json="$1"
    [[ -f "${mcp_json}" ]] || return 0
    MCP_JSON="${mcp_json}" MCP_URL="http://localhost:${PORT}/mcp" python3 - <<'PY'
import json, os, sys
path = os.environ["MCP_JSON"]
url = os.environ["MCP_URL"]
try:
    with open(path) as f:
        data = json.load(f)
except Exception as e:
    print(f"  skip {path}: {e}", file=sys.stderr); sys.exit(0)
servers = data.setdefault("servers", {})
servers["mcp-ecosystem"] = {"type": "http", "url": url}
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"  registered mcp-ecosystem -> {url} in {path}")
PY
  }
  register_vscode "${HOME}/Library/Application Support/Code - Insiders/User/mcp.json" || true
  register_vscode "${HOME}/Library/Application Support/Code/User/mcp.json" || true
  ok "VS Code user mcp.json updated (reload window to pick it up)."
fi

# --------------------------------------------------------------------------- #
# Summary
# --------------------------------------------------------------------------- #
cat <<SUMMARY

────────────────────────────────────────────────────────────
  MCP Ecosystem — per-user service installed
────────────────────────────────────────────────────────────
  Endpoint : http://localhost:${PORT}/mcp
  Health   : http://localhost:${PORT}/health
  Image    : ${IMAGE}
  Install  : ${INSTALL_DIR}
  LaunchAgent: ${LAUNCH_LABEL} (starts at login)

  Commands:
    ${BIN_DIR}/status.sh    # status + health
    ${BIN_DIR}/stop.sh      # stop
    ${BIN_DIR}/start.sh     # start

  Uninstall:
    scripts/uninstall-user-mcp-ecosystem.sh
────────────────────────────────────────────────────────────
SUMMARY
