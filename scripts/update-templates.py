#!/usr/bin/env python3
"""Update all template.yaml files with correct owners, environment selection, and Azure params."""
import os
import yaml

BASE = "/tmp/golden-paths-push"

# Template -> owner group mapping
OWNERS = {
    # H1
    "h1-foundation/basic-cicd": "group:devops-engineering",
    "h1-foundation/documentation-site": "group:documentation-team",
    "h1-foundation/infrastructure-provisioning": "group:platform-engineering",
    "h1-foundation/security-baseline": "group:platform-engineering",
    "h1-foundation/web-application": "group:frontend-engineering",
    # H2
    "h2-enhancement/ado-to-github-migration": "group:devops-engineering",
    "h2-enhancement/api-gateway": "group:backend-engineering",
    "h2-enhancement/api-microservice": None,  # Already updated
    "h2-enhancement/batch-job": "group:backend-engineering",
    "h2-enhancement/data-pipeline": "group:data-engineering",
    "h2-enhancement/event-driven-microservice": "group:backend-engineering",
    "h2-enhancement/gitops-deployment": "group:devops-engineering",
    "h2-enhancement/microservice": "group:backend-engineering",
    "h2-enhancement/reusable-workflows": "group:devops-engineering",
}

# Environment + Azure params to add
ENV_PARAMS = {
    "title": "Environment & Deployment",
    "required": ["environment"],
    "properties": {
        "environment": {
            "title": "Target Environment",
            "type": "string",
            "description": "Which environment to deploy to",
            "enum": ["dev", "qa", "prod"],
            "enumNames": ["Development", "QA / Staging", "Production"],
            "default": "dev",
        },
        "azureSubscription": {
            "title": "Azure Subscription ID",
            "type": "string",
            "description": "Required for infrastructure provisioning (leave empty for local)",
        },
        "azureRegion": {
            "title": "Azure Region",
            "type": "string",
            "enum": ["centralus", "eastus"],
            "enumNames": ["Central US", "East US"],
            "default": "centralus",
        },
    },
}

# Codespaces output link
CODESPACES_LINK = {
    "title": "Open in Codespaces",
    "url": "${{ steps.publish.output.remoteUrl }}/codespaces/new",
    "icon": "code",
}

for tpl_path, owner in OWNERS.items():
    if owner is None:
        continue

    yaml_path = os.path.join(BASE, tpl_path, "template.yaml")
    if not os.path.exists(yaml_path):
        print(f"  SKIP {tpl_path}: no template.yaml")
        continue

    with open(yaml_path) as f:
        content = f.read()

    # Parse YAML
    try:
        doc = yaml.safe_load(content)
    except Exception as e:
        print(f"  ERROR {tpl_path}: {e}")
        continue

    # Update owner
    if "spec" in doc:
        doc["spec"]["owner"] = owner

        # Add environment params if not already present
        params = doc["spec"].get("parameters", [])
        has_env = any(
            isinstance(p, dict) and "environment" in p.get("properties", {})
            for p in params
        )
        if not has_env:
            params.append(ENV_PARAMS)
            doc["spec"]["parameters"] = params

        # Add RepoUrlPicker if not present
        has_repo = any(
            isinstance(p, dict) and "repoUrl" in p.get("properties", {})
            for p in params
        )
        if not has_repo:
            params.append({
                "title": "Repository Settings",
                "required": ["repoUrl"],
                "properties": {
                    "repoUrl": {
                        "title": "Repository Location",
                        "type": "string",
                        "ui:field": "RepoUrlPicker",
                        "ui:options": {"allowedHosts": ["github.com"]},
                    }
                },
            })

        # Update publish step to use repoUrl
        steps = doc["spec"].get("steps", [])
        for step in steps:
            if step.get("action") == "publish:github":
                step["input"]["repoUrl"] = "${{ parameters.repoUrl }}"
                step["input"]["defaultBranch"] = "main"
                step["input"]["repoVisibility"] = "private"
                # Remove old allowedHosts if repoUrl is set
                if "allowedHosts" in step["input"]:
                    del step["input"]["allowedHosts"]
                if "description" not in step["input"]:
                    step["input"]["description"] = "${{ parameters.name }}"

        # Add Codespaces link to output
        output = doc["spec"].get("output", {})
        links = output.get("links", [])
        has_cs = any(l.get("title") == "Open in Codespaces" for l in links)
        if not has_cs:
            links.append(CODESPACES_LINK)
            output["links"] = links
            doc["spec"]["output"] = output

    # Write back
    with open(yaml_path, "w") as f:
        yaml.dump(doc, f, default_flow_style=False, sort_keys=False, allow_unicode=True)

    print(f"  {tpl_path}: owner={owner} + env params + Codespaces link")

print("Done")
