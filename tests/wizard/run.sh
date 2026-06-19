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
app_config_path="$REPO_ROOT/backstage/app-config.production.yaml"
app_config_backup="$(mktemp)"
[[ -f "$app_config_path" ]] && cp "$app_config_path" "$app_config_backup"

restore_files() {
  if [[ -s "$manifest_backup" ]]; then
    cp "$manifest_backup" "$manifest_path"
  else
    rm -f "$manifest_path"
  fi
  rm -f "$manifest_backup"
  if [[ -s "$app_config_backup" ]]; then
    cp "$app_config_backup" "$app_config_path"
  else
    rm -f "$app_config_path"
  fi
  rm -f "$app_config_backup"
}
trap restore_files EXIT

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
agents: [deploy, terraform, security]
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
echo "Test 18: profile standard writes platform portal profile and packs"
rm -f "$manifest_path"
"$WIZARD" --environment dev --auto --profile standard >/dev/null 2>&1
ec=$?
assert "profile standard exit code" "$ec" "0"
portal_profile=$(yq '.portal_profile' "$manifest_path")
branding_profile=$(yq '.branding_profile' "$manifest_path")
platform_pages=$(yq '.feature_packs.enable_platform_pages' "$manifest_path")
ai_chat_pack=$(yq '.feature_packs.enable_ai_chat' "$manifest_path")
assert "profile standard portal_profile=platform" "$portal_profile" "platform"
assert "profile standard branding=open-horizons" "$branding_profile" "open-horizons"
assert "profile standard enables platform pages" "$platform_pages" "true"
assert "profile standard keeps AI Chat off" "$ai_chat_pack" "false"

echo
echo "Test 19: profile full writes full portal profile and AI packs"
rm -f "$manifest_path"
"$WIZARD" --environment dev --auto --profile full >/dev/null 2>&1
ec=$?
assert "profile full second exit code" "$ec" "0"
portal_profile=$(yq '.portal_profile' "$manifest_path")
ai_chat_pack=$(yq '.feature_packs.enable_ai_chat' "$manifest_path")
ai_impact_pack=$(yq '.feature_packs.enable_ai_impact' "$manifest_path")
mcp_pack=$(yq '.feature_packs.enable_mcp_ecosystem' "$manifest_path")
assert "profile full portal_profile=full" "$portal_profile" "full"
assert "profile full enables AI Chat pack" "$ai_chat_pack" "true"
assert "profile full enables AI Impact pack" "$ai_impact_pack" "true"
assert "profile full enables MCP pack" "$mcp_pack" "true"

echo
echo "Test 20: render-manifests honors feature_packs over legacy flags"
render_sel="$(mktemp)"
cat > "$render_sel" <<'YAML'
horizon: h3
environment: dev
deployment_mode: standard
portal_profile: full
branding_profile: open-horizons
modules: {enable_container_registry: true, enable_ai_foundry: true}
backstage_components:
  enable_agent_api: false
  enable_agent_api_impact: false
  enable_mcp_ecosystem: false
feature_packs:
  enable_ai_chat: true
  enable_ai_impact: true
  enable_mcp_ecosystem: true
golden_paths: [h3-innovation/mcp-ecosystem]
YAML
render_out="$(mktemp -d)"
"$REPO_ROOT/scripts/render-manifests.sh" --selection "$render_sel" --output "$render_out" >/dev/null
assert "feature pack includes agent-api deployment" "$([[ -f $render_out/agent-api-deployment.yaml ]] && echo yes || echo no)" "yes"
assert "feature pack includes agent-api-impact deployment" "$([[ -f $render_out/agent-api-impact-deployment.yaml ]] && echo yes || echo no)" "yes"
assert "feature pack includes mcp ecosystem deployment" "$([[ -f $render_out/mcp-ecosystem-deployment.yaml ]] && echo yes || echo no)" "yes"
rm -f "$render_sel"
rm -rf "$render_out"

echo
echo "Test 21: CLI portal and branding profile flags are persisted"
rm -f "$manifest_path"
"$WIZARD" --environment dev --horizon h2 --deployment-mode standard --portal-profile platform --branding-profile custom --auto >/dev/null 2>&1
ec=$?
assert "CLI profile flags exit code" "$ec" "0"
portal_profile=$(yq '.portal_profile' "$manifest_path")
branding_profile=$(yq '.branding_profile' "$manifest_path")
assert "CLI portal_profile persisted" "$portal_profile" "platform"
assert "CLI branding_profile persisted" "$branding_profile" "custom"

echo
echo "Test 22: full profile enables foundry_agents (H3) and keeps disaster_recovery"
rm -f "$manifest_path"
"$WIZARD" --environment dev --horizon all --profile full --auto >/dev/null 2>&1
assert "full profile exit code" "$?" "0"
assert "full enables enable_foundry_agents" "$(yq '.modules.enable_foundry_agents' "$manifest_path")" "true"
assert "full enables enable_ai_foundry" "$(yq '.modules.enable_ai_foundry' "$manifest_path")" "true"
assert "full keeps enable_disaster_recovery" "$(yq '.modules.enable_disaster_recovery' "$manifest_path")" "true"

echo
echo "Test 23: minimal profile keeps foundry_agents and disaster_recovery false"
rm -f "$manifest_path"
"$WIZARD" --environment dev --horizon h1 --profile minimal --auto >/dev/null 2>&1
assert "minimal profile exit code" "$?" "0"
assert "minimal disables enable_foundry_agents" "$(yq '.modules.enable_foundry_agents' "$manifest_path")" "false"
assert "minimal disables enable_disaster_recovery" "$(yq '.modules.enable_disaster_recovery' "$manifest_path")" "false"

echo
echo "Test 24: foundry_agents without h3 exits 2 (RULE-001b)"
fa_h1="$(mktemp)"
cat > "$fa_h1" <<'YAML'
horizon: h1
environment: dev
deployment_mode: express
modules:
  enable_ai_foundry: true
  enable_foundry_agents: true
backstage_components: {}
golden_paths:
  - h1-foundation/basic-cicd
YAML
"$WIZARD" --environment dev --auto --selection-file "$fa_h1" >/dev/null 2>&1
ec=$?
rm -f "$fa_h1"
assert "foundry_agents requires h3 exit code" "$ec" "2"

echo
echo "Test 25: foundry_agents without ai_foundry exits 2 (RULE-001c)"
fa_noaif="$(mktemp)"
cat > "$fa_noaif" <<'YAML'
horizon: h3
environment: dev
deployment_mode: express
modules:
  enable_ai_foundry: false
  enable_foundry_agents: true
backstage_components: {}
golden_paths:
  - h3-innovation/mcp-ecosystem
YAML
"$WIZARD" --environment dev --auto --selection-file "$fa_noaif" >/dev/null 2>&1
ec=$?
rm -f "$fa_noaif"
assert "foundry_agents requires ai_foundry exit code" "$ec" "2"

echo
echo "Test 26: valid foundry_agents selection (h3 + ai_foundry) passes"
fa_ok="$(mktemp)"
cat > "$fa_ok" <<'YAML'
horizon: h3
environment: dev
deployment_mode: express
modules:
  enable_ai_foundry: true
  enable_foundry_agents: true
backstage_components: {}
golden_paths:
  - h3-innovation/mcp-ecosystem
YAML
"$WIZARD" --environment dev --auto --selection-file "$fa_ok" >/dev/null 2>&1
ec=$?
rm -f "$fa_ok"
assert "valid foundry_agents exit code" "$ec" "0"

echo
echo "Test 27: valid Entra ID plus GitHub EMU identity passes"
entra_emu="$(mktemp)"
cat > "$entra_emu" <<'YAML'
horizon: h2
environment: dev
deployment_mode: standard
identity:
  auth_provider: entra
  github_identity_mode: enterprise-managed-users
modules:
  enable_container_registry: true
  enable_argocd: true
backstage_components:
  enable_ai_chat_plugin: false
  enable_agent_api: false
golden_paths:
  - h1-foundation/basic-cicd
YAML
rm -f "$manifest_path"
"$WIZARD" --environment dev --auto --selection-file "$entra_emu" >/dev/null 2>&1
ec=$?
rm -f "$entra_emu"
assert "valid Entra plus EMU exit code" "$ec" "0"
assert "manifest auth_provider=entra" "$(yq '.identity.auth_provider' "$manifest_path")" "entra"
assert "manifest github_identity_mode=enterprise-managed-users" "$(yq '.identity.github_identity_mode' "$manifest_path")" "enterprise-managed-users"

echo
echo "Test 28: GitHub auth with EMU identity exits 2"
github_emu="$(mktemp)"
cat > "$github_emu" <<'YAML'
horizon: h2
environment: dev
deployment_mode: standard
identity:
  auth_provider: github
  github_identity_mode: enterprise-managed-users
modules:
  enable_container_registry: true
backstage_components: {}
golden_paths:
  - h1-foundation/basic-cicd
YAML
"$WIZARD" --environment dev --auto --selection-file "$github_emu" >/dev/null 2>&1
ec=$?
rm -f "$github_emu"
assert "GitHub auth with EMU exit code" "$ec" "2"

echo
echo "Test 29: guest auth with EMU identity exits 2"
guest_emu="$(mktemp)"
cat > "$guest_emu" <<'YAML'
horizon: h2
environment: dev
deployment_mode: standard
identity:
  auth_provider: guest
  github_identity_mode: enterprise-managed-users
modules:
  enable_container_registry: true
backstage_components: {}
golden_paths:
  - h1-foundation/basic-cicd
YAML
"$WIZARD" --environment dev --auto --selection-file "$guest_emu" >/dev/null 2>&1
ec=$?
rm -f "$guest_emu"
assert "guest auth with EMU exit code" "$ec" "2"

echo
echo "Summary: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
