#!/usr/bin/env bash
# =============================================================================
# Smoke tests for scripts/install-wizard.sh
# Run: bash tests/wizard/run.sh
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WIZARD="$REPO_ROOT/scripts/install-wizard.sh"

PASS=0
FAIL=0

assert() {
  local desc="$1" actual="$2" expected="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "  PASS  $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $desc (expected '$expected', got '$actual')"
    FAIL=$((FAIL + 1))
  fi
}

manifest_path="$REPO_ROOT/.openhorizons-selection.yaml"
manifest_backup="$(mktemp)"
[[ -f "$manifest_path" ]] && cp "$manifest_path" "$manifest_backup"

restore_manifest() {
  if [[ -s "$manifest_backup" ]]; then
    cp "$manifest_backup" "$manifest_path"
  else
    rm -f "$manifest_path"
  fi
  rm -f "$manifest_backup"
}
trap restore_manifest EXIT

echo "Test 1: --help exits 0"
"$WIZARD" --help >/dev/null
assert "help exit code" "$?" "0"

echo
echo "Test 2: --dry-run does not create files"
rm -f "$manifest_path"
"$WIZARD" --environment dev --horizon all --auto --dry-run >/dev/null 2>&1
ec=$?
assert "dry-run exit code" "$ec" "0"
assert "manifest not created in dry-run" "$([[ -f $manifest_path ]] && echo yes || echo no)" "no"

echo
echo "Test 3: --auto run writes manifest"
"$WIZARD" --environment dev --horizon all --auto >/dev/null 2>&1
ec=$?
assert "auto run exit code" "$ec" "0"
assert "manifest exists after run" "$([[ -f $manifest_path ]] && echo yes || echo no)" "yes"

echo
echo "Test 4: re-run is idempotent (exit 0, no diff)"
"$WIZARD" --environment dev --horizon all --auto >/dev/null 2>&1
assert "rerun exit code" "$?" "0"

echo
echo "Test 5: rule violation exits 2"
violate="$(mktemp)"
cat > "$violate" <<'YAML'
horizon: all
environment: dev
deployment_mode: express
modules:
  enable_container_registry: true
backstage_components:
  enable_ai_chat_plugin: true
  enable_agent_api: false
golden_paths:
  - h1-foundation/basic-cicd
YAML
"$WIZARD" --environment dev --auto --selection-file "$violate" >/dev/null 2>&1
ec=$?
rm -f "$violate"
assert "rule violation exit code" "$ec" "2"

echo
echo "Test 6: secrets rejected from manifest"
secret="$(mktemp)"
cat > "$secret" <<'YAML'
horizon: all
environment: dev
deployment_mode: express
secret_token: ghp_should_be_rejected
modules:
  enable_container_registry: true
backstage_components:
  enable_ai_chat_plugin: true
  enable_agent_api: true
YAML
output="$("$WIZARD" --environment dev --auto --selection-file "$secret" 2>&1 || true)"
rm -f "$secret"
if echo "$output" | grep -q "ghp_should_be_rejected"; then
  echo "  FAIL  manifest leaked secret value"
  FAIL=$((FAIL + 1))
else
  echo "  PASS  manifest does not leak secret value"
  PASS=$((PASS + 1))
fi

echo
echo "Test 7: render-manifests includes core and excludes disabled components"
render_sel="$(mktemp)"
cat > "$render_sel" <<'YAML'
horizon: h1
environment: dev
deployment_mode: express
backstage_components:
  enable_agent_api: false
  enable_agent_api_impact: false
  enable_mcp_ecosystem: false
golden_paths:
  - h1-foundation/basic-cicd
YAML
render_out="$(mktemp -d)"
"$REPO_ROOT/scripts/render-manifests.sh" --selection "$render_sel" --output "$render_out" >/dev/null
assert "namespace.yaml is always included" "$([[ -f $render_out/namespace.yaml ]] && echo yes || echo no)" "yes"
assert "agent-api-deployment is excluded" "$([[ -f $render_out/agent-api-deployment.yaml ]] && echo yes || echo no)" "no"
assert "mcp-ecosystem is excluded" "$([[ -f $render_out/mcp-ecosystem-deployment.yaml ]] && echo yes || echo no)" "no"
assert "kustomization.yaml exists" "$([[ -f $render_out/kustomization.yaml ]] && echo yes || echo no)" "yes"
rm -f "$render_sel"
rm -rf "$render_out"

echo
echo "Test 8: render-manifests --dry-run writes nothing"
render_sel="$(mktemp)"
cat > "$render_sel" <<'YAML'
horizon: all
environment: dev
deployment_mode: express
backstage_components:
  enable_agent_api: true
golden_paths:
  - h1-foundation/basic-cicd
YAML
render_out="$(mktemp -d)"
rmdir "$render_out"
"$REPO_ROOT/scripts/render-manifests.sh" --selection "$render_sel" --output "$render_out" --dry-run >/dev/null
assert "dry-run did not create output dir" "$([[ -d $render_out ]] && echo yes || echo no)" "no"
rm -f "$render_sel"
rm -rf "$render_out"

echo
echo "Test 9: profile minimal selects only h1 modules"
rm -f "$manifest_path"
"$WIZARD" --environment dev --auto --profile minimal >/dev/null 2>&1
assert "profile minimal exit code" "$?" "0"
horizon=$(grep "^horizon:" "$manifest_path" | awk '{print $2}')
assert "profile minimal horizon=h1" "$horizon" "h1"
ai_chat=$(yq '.backstage_components.enable_ai_chat_plugin' "$manifest_path")
assert "profile minimal disables AI Chat" "$ai_chat" "false"

echo
echo "Test 10: profile full enables AI Foundry and MCP ecosystem"
rm -f "$manifest_path"
"$WIZARD" --environment dev --auto --profile full >/dev/null 2>&1
assert "profile full exit code" "$?" "0"
ai_foundry=$(yq '.modules.enable_ai_foundry' "$manifest_path")
mcp=$(yq '.backstage_components.enable_mcp_ecosystem' "$manifest_path")
assert "profile full enables AI Foundry" "$ai_foundry" "true"
assert "profile full enables MCP ecosystem" "$mcp" "true"

echo
echo "Test 11: schema rejects invalid horizon"
bad="$(mktemp)"
cat > "$bad" <<'YAML'
horizon: h99
environment: dev
deployment_mode: express
modules: {enable_container_registry: true}
backstage_components: {enable_ai_chat_plugin: true, enable_agent_api: true}
golden_paths: [h1-foundation/basic-cicd]
YAML
"$WIZARD" --environment dev --auto --selection-file "$bad" >/dev/null 2>&1
ec=$?
rm -f "$bad"
assert "schema rejection exit code" "$ec" "2"

echo
echo "Test 12: schema rejects unknown top-level key"
bad="$(mktemp)"
cat > "$bad" <<'YAML'
horizon: all
environment: dev
deployment_mode: express
unexpected_key: value
modules: {enable_container_registry: true}
backstage_components: {enable_ai_chat_plugin: true, enable_agent_api: true}
golden_paths: [h1-foundation/basic-cicd]
YAML
"$WIZARD" --environment dev --auto --selection-file "$bad" >/dev/null 2>&1
ec=$?
rm -f "$bad"
assert "schema rejects unknown key" "$ec" "2"

echo
echo "Test 13: agents allowlist filters rendered output"
narrow="$(mktemp)"
cat > "$narrow" <<'YAML'
horizon: h1
environment: dev
deployment_mode: express
modules: {enable_container_registry: true}
backstage_components: {enable_ai_chat_plugin: true, enable_agent_api: true}
golden_paths: [h1-foundation/basic-cicd]
agents: [pipeline, sentinel, compass]
YAML
rm -rf "$REPO_ROOT/golden-paths/common/agents/.rendered"
rm -f "$manifest_path"
"$WIZARD" --environment dev --auto --selection-file "$narrow" >/dev/null 2>&1
ec=$?
rm -f "$narrow"
assert "agents allowlist exit code" "$ec" "0"
agent_count=$(ls "$REPO_ROOT/golden-paths/common/agents/.rendered/.github/agents" 2>/dev/null | wc -l | tr -d ' ')
assert "agents allowlist count = 3" "$agent_count" "3"

echo
echo "Test 14: skills allowlist filters rendered output"
narrow="$(mktemp)"
cat > "$narrow" <<'YAML'
horizon: h1
environment: dev
deployment_mode: express
modules: {enable_container_registry: true}
backstage_components: {enable_ai_chat_plugin: true, enable_agent_api: true}
golden_paths: [h1-foundation/basic-cicd]
skills: [kubectl-cli, terraform-cli]
YAML
rm -rf "$REPO_ROOT/golden-paths/common/agents/.rendered"
rm -f "$manifest_path"
"$WIZARD" --environment dev --auto --selection-file "$narrow" >/dev/null 2>&1
rm -f "$narrow"
skill_count=$(ls "$REPO_ROOT/golden-paths/common/agents/.rendered/.github/skills" 2>/dev/null | wc -l | tr -d ' ')
assert "skills allowlist count = 2" "$skill_count" "2"

echo
echo "Test 15: prompts allowlist filters rendered output"
narrow="$(mktemp)"
cat > "$narrow" <<'YAML'
horizon: h1
environment: dev
deployment_mode: express
modules: {enable_container_registry: true}
backstage_components: {enable_ai_chat_plugin: true, enable_agent_api: true}
golden_paths: [h1-foundation/basic-cicd]
prompts: [deploy-platform]
YAML
rm -rf "$REPO_ROOT/golden-paths/common/agents/.rendered"
rm -f "$manifest_path"
"$WIZARD" --environment dev --auto --selection-file "$narrow" >/dev/null 2>&1
rm -f "$narrow"
prompt_count=$(ls "$REPO_ROOT/golden-paths/common/agents/.rendered/.github/prompts" 2>/dev/null | wc -l | tr -d ' ')
assert "prompts allowlist count = 1" "$prompt_count" "1"

echo
echo "Test 16: unknown primitive id exits 2"
bad="$(mktemp)"
cat > "$bad" <<'YAML'
horizon: h1
environment: dev
deployment_mode: express
modules: {enable_container_registry: true}
backstage_components: {enable_ai_chat_plugin: true, enable_agent_api: true}
golden_paths: [h1-foundation/basic-cicd]
agents: [bogus-agent]
YAML
"$WIZARD" --environment dev --auto --selection-file "$bad" >/dev/null 2>&1
ec=$?
rm -f "$bad"
assert "unknown agent id exit code" "$ec" "2"

echo
echo "Test 17: AI Chat plugin off filters /agent-api proxy from app-config"
app_config="$REPO_ROOT/backstage/app-config.production.yaml"
app_backup="$(mktemp)"
cp "$app_config" "$app_backup"
narrow="$(mktemp)"
cat > "$narrow" <<'YAML'
horizon: h1
environment: dev
deployment_mode: express
modules: {enable_container_registry: true}
backstage_components: {enable_ai_chat_plugin: false, enable_agent_api: false}
golden_paths: [h1-foundation/basic-cicd]
YAML
rm -f "$manifest_path"
"$WIZARD" --environment dev --auto --selection-file "$narrow" >/dev/null 2>&1
if grep -q "'/agent-api'" "$app_config"; then
  echo "  FAIL  /agent-api proxy still present after disabling AI Chat"
  FAIL=$((FAIL + 1))
else
  echo "  PASS  /agent-api proxy removed when AI Chat is off"
  PASS=$((PASS + 1))
fi
cp "$app_backup" "$app_config"
rm -f "$app_backup" "$narrow"

echo
echo "Summary: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
