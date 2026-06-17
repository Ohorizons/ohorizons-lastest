#!/usr/bin/env bash
# Validate Backstage Scaffolder action schemas used in Golden Path templates.
# Usage: ./scripts/validate-scaffolder-templates.sh [templates-root]
set -euo pipefail

TEMPLATES_ROOT="${1:-golden-paths}"

if [[ ! -d "$TEMPLATES_ROOT" ]]; then
  echo "Error: directory not found: $TEMPLATES_ROOT"
  exit 1
fi

errors=0
total=0

while IFS= read -r -d '' template; do
  total=$((total + 1))

  if ! awk '
    BEGIN {
      bad = 0
      in_publish = 0
      publish_window = 0
      in_dispatch = 0
      dispatch_window = 0
    }

    /action:[[:space:]]*publish:github$/ {
      in_publish = 1
      publish_window = 0
    }

    in_publish {
      publish_window++
      if ($0 ~ /^[[:space:]]*allowedHosts:[[:space:]]*(\[[^\]]*\])?[[:space:]]*$/) {
        printf("%s:%d: invalid: remove allowedHosts from publish:github input\n", FILENAME, NR)
        bad = 1
      }
      if (publish_window > 14 || $0 ~ /^[[:space:]]*-[[:space:]]+id:[[:space:]]+/) {
        in_publish = 0
      }
    }

    /action:[[:space:]]*github:actions:dispatch$/ {
      in_dispatch = 1
      dispatch_window = 0
    }

    in_dispatch {
      dispatch_window++
      if ($0 ~ /^[[:space:]]*inputs:[[:space:]]*$/) {
        printf("%s:%d: invalid: use workflowInputs instead of inputs in github:actions:dispatch\n", FILENAME, NR)
        bad = 1
      }
      if (dispatch_window > 14 || $0 ~ /^[[:space:]]*-[[:space:]]+id:[[:space:]]+/) {
        in_dispatch = 0
      }
    }

    END { exit bad }
  ' "$template"; then
    errors=$((errors + 1))
  fi
done < <(find "$TEMPLATES_ROOT" -type f -name template.yaml -print0)

if [[ "$errors" -gt 0 ]]; then
  echo "Validation failed: $errors template(s) with schema-incompatible action inputs."
  exit 1
fi

echo "Validation passed: $total template(s) checked."
