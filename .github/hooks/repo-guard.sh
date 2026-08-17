#!/usr/bin/env bash
set -euo pipefail

payload="$(cat || true)"
context="$payload ${COPILOT_TOOL_NAME:-} ${COPILOT_TOOL_ARGS:-} ${COMMAND:-}"
context_one_line="$(printf '%s' "$context" | tr '\n' ' ')"
context_lower="$(printf '%s' "$context_one_line" | tr '[:upper:]' '[:lower:]')"

allow() {
  printf '{"permissionDecision":"allow"}\n'
}

block() {
  local message="$1"
  printf '{"permissionDecision":"block","message":"%s"}\n' "$message"
}

contains_regex() {
  printf '%s' "$context_lower" | grep -Eq -- "$1"
}

if contains_regex '(^|[^a-z0-9_-])terraform[[:space:]]+destroy([^a-z0-9_-]|$)'; then
  block "Blocked terraform destroy. Open Horizons infrastructure destruction must be reviewed and run outside Copilot automation."
  exit 0
fi

if contains_regex '(^|[^a-z0-9_-])terraform[[:space:]]+apply([^a-z0-9_-]|$)'; then
  if ! contains_regex 'terraform[[:space:]]+apply([[:space:]]+[^[:space:]";]+)*(^|[[:space:]])[^[:space:]";]+(\.tfplan|\.plan|tfplan)([[:space:]";]|$)'; then
    block "Blocked terraform apply without a saved plan file. Run terraform plan -out=<file>.tfplan first, then apply that file."
    exit 0
  fi
fi

if contains_regex '(^|[^a-z0-9_-])kubectl[[:space:]]+delete([^a-z0-9_-]|$)'; then
  if ! contains_regex '--context[=[:space:]][^[:space:]";]*(dev|local|kind|minikube)'; then
    block "Blocked kubectl delete without an explicit dev/local/kind/minikube context."
    exit 0
  fi
fi

if contains_regex '(^|[^a-z0-9_-])az[[:space:]]+group[[:space:]]+delete([^a-z0-9_-]|$)'; then
  block "Blocked az group delete. Resource group deletion is destructive and must be performed manually."
  exit 0
fi

if contains_regex '(^|[^a-z0-9_-])rm[[:space:]]+-[^[:space:]]*r[^[:space:]]*f|(^|[^a-z0-9_-])rm[[:space:]]+-[^[:space:]]*f[^[:space:]]*r'; then
  block "Blocked rm -rf destructive deletion."
  exit 0
fi

if contains_regex '(^|[^a-z0-9_-])git[[:space:]]+push([^;|&"]*)--force|--force-with-lease'; then
  block "Blocked force push. Do not rewrite shared repository history from Copilot."
  exit 0
fi

if contains_regex '(^|[^a-z0-9_-])(cat|less|more|head|tail|sed|awk|grep|rg|open|view|read)[[:space:]]' \
  && contains_regex '(^|[[:space:]/"])\.env($|[[:space:]"])'; then
  block "Blocked reading .env. Use .env.example or documented variable names, never secret values."
  exit 0
fi

if contains_regex '(^|[^a-z0-9_-])(cat|less|more|head|tail|sed|awk|grep|rg|open|view|read)[[:space:]][^;|&"]*\.tfstate(\.[^[:space:]";]+)?([[:space:]";]|$)'; then
  block "Blocked reading Terraform state. State can contain secrets and cloud identifiers."
  exit 0
fi

if contains_regex '(^|[^a-z0-9_-])(cat|less|more|head|tail|sed|awk|grep|rg|open|view|read)[[:space:]][^;|&"]*(^|[[:space:]/"])(\.kube/config|kubeconfig|[^[:space:]";]*\.kubeconfig)([[:space:]";]|$)'; then
  block "Blocked reading kubeconfig. Use kubectl commands without exposing credential files."
  exit 0
fi

if contains_regex '(^|[^a-z0-9_-])git[[:space:]]+commit([^;|&"]*)--no-verify|(^|[^a-z0-9_-])git[[:space:]]+push([^;|&"]*)--no-verify'; then
  block "Blocked --no-verify. Repository validation hooks must not be bypassed."
  exit 0
fi

allow
