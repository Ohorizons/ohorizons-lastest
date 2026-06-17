#!/usr/bin/env python3
"""Generate complete skeleton files for all H1 and H2 Golden Path templates."""
import os
import json

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GP = os.path.join(BASE, "golden-paths")


def w(path, content):
    full = os.path.join(GP, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w") as f:
        f.write(content)


def dc(name, image, features=None, post_cmd=None, ports=None):
    obj = {"name": name, "image": image}
    if features:
        obj["features"] = features
    if post_cmd:
        obj["postCreateCommand"] = post_cmd
    if ports:
        obj["forwardPorts"] = ports
    return json.dumps(obj, indent=2)


# =========================================================================
# H1: web-application
# =========================================================================
w("h1-foundation/web-application/skeleton/src/App.tsx",
  'import React from "react";\n\nexport default function App() {\n  return (\n    <div className="app">\n      <h1>Welcome</h1>\n      <p>Your web application is ready.</p>\n    </div>\n  );\n}\n')
w("h1-foundation/web-application/skeleton/src/index.tsx",
  'import React from "react";\nimport ReactDOM from "react-dom/client";\nimport App from "./App";\n\nconst root = ReactDOM.createRoot(document.getElementById("root")!);\nroot.render(<React.StrictMode><App /></React.StrictMode>);\n')
w("h1-foundation/web-application/skeleton/src/index.css",
  "body { margin: 0; font-family: -apple-system, sans-serif; }\n.app { max-width: 800px; margin: 0 auto; padding: 2rem; }\n")
w("h1-foundation/web-application/skeleton/tsconfig.json",
  json.dumps({"compilerOptions": {"target": "ES2020", "module": "ESNext", "jsx": "react-jsx", "strict": True, "outDir": "dist"}, "include": ["src"]}, indent=2))
w("h1-foundation/web-application/skeleton/vite.config.ts",
  'import { defineConfig } from "vite";\nimport react from "@vitejs/plugin-react";\n\nexport default defineConfig({\n  plugins: [react()],\n  server: { port: 3000 },\n});\n')
w("h1-foundation/web-application/skeleton/.github/workflows/ci.yaml",
  "name: CI\non:\n  push:\n    branches: [main]\n  pull_request:\n    branches: [main]\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - uses: actions/setup-node@v4\n        with:\n          node-version: '20'\n      - run: npm ci\n      - run: npm run build\n")
w("h1-foundation/web-application/skeleton/.devcontainer/devcontainer.json",
  dc("Web App", "mcr.microsoft.com/devcontainers/javascript-node:20",
     features={"ghcr.io/devcontainers/features/azure-cli:1": {}, "ghcr.io/devcontainers/features/github-cli:1": {}},
     post_cmd="npm ci", ports=[3000]))
print("  H1 web-application: OK")

# =========================================================================
# H1: security-baseline
# =========================================================================
w("h1-foundation/security-baseline/skeleton/terraform/main.tf",
  'resource "azurerm_key_vault" "main" {\n  name                      = "kv-security"\n  location                  = var.location\n  resource_group_name       = var.resource_group\n  tenant_id                 = data.azurerm_client_config.current.tenant_id\n  sku_name                  = "standard"\n  purge_protection_enabled  = true\n  enable_rbac_authorization = true\n}\n\ndata "azurerm_client_config" "current" {}\n')
w("h1-foundation/security-baseline/skeleton/terraform/variables.tf",
  'variable "location" {\n  type    = string\n  default = "centralus"\n}\n\nvariable "resource_group" {\n  type = string\n}\n')
w("h1-foundation/security-baseline/skeleton/terraform/providers.tf",
  'terraform {\n  required_version = ">= 1.5"\n  required_providers {\n    azurerm = {\n      source  = "hashicorp/azurerm"\n      version = "~> 3.85"\n    }\n  }\n}\n\nprovider "azurerm" {\n  features {}\n}\n')
w("h1-foundation/security-baseline/skeleton/policies/require-tags.rego",
  'package kubernetes.admission\n\ndeny[msg] {\n  input.request.kind.kind == "Deployment"\n  not input.request.object.metadata.labels.app\n  msg := "Deployments must have an app label"\n}\n')
w("h1-foundation/security-baseline/skeleton/.github/workflows/security-scan.yaml",
  "name: Security Scan\non: [push, pull_request]\njobs:\n  tfsec:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - uses: aquasecurity/tfsec-action@v1.0.3\n        with:\n          working_directory: terraform\n")
w("h1-foundation/security-baseline/skeleton/.devcontainer/devcontainer.json",
  dc("Security", "mcr.microsoft.com/devcontainers/base:ubuntu",
     features={"ghcr.io/devcontainers/features/terraform:1": {"version": "1.7"}, "ghcr.io/devcontainers/features/azure-cli:1": {}}))
print("  H1 security-baseline: OK")

# =========================================================================
# H1: basic-cicd
# =========================================================================
w("h1-foundation/basic-cicd/skeleton/Makefile",
  ".PHONY: build test lint\n\nbuild:\n\tdocker build -t app:latest .\n\ntest:\n\techo 'Running tests...'\n\nlint:\n\techo 'Running linter...'\n")
w("h1-foundation/basic-cicd/skeleton/Dockerfile",
  "FROM alpine:3.19\nWORKDIR /app\nCOPY . .\nCMD [\"echo\", \"Hello from CI/CD template\"]\n")
w("h1-foundation/basic-cicd/skeleton/.devcontainer/devcontainer.json",
  dc("CI/CD", "mcr.microsoft.com/devcontainers/base:ubuntu",
     features={"ghcr.io/devcontainers/features/docker-in-docker:2": {}, "ghcr.io/devcontainers/features/github-cli:1": {}}))
print("  H1 basic-cicd: OK")

# =========================================================================
# H1: documentation-site
# =========================================================================
w("h1-foundation/documentation-site/skeleton/.github/workflows/techdocs.yaml",
  "name: TechDocs\non:\n  push:\n    branches: [main]\n    paths: ['docs/**', 'mkdocs.yml']\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - uses: actions/setup-python@v5\n        with:\n          python-version: '3.11'\n      - run: pip install mkdocs-techdocs-core\n      - run: mkdocs build\n")
w("h1-foundation/documentation-site/skeleton/.devcontainer/devcontainer.json",
  dc("Docs", "mcr.microsoft.com/devcontainers/python:3.11",
     post_cmd="pip install mkdocs-techdocs-core", ports=[8000]))
print("  H1 documentation-site: OK")

# =========================================================================
# H1: infrastructure-provisioning
# =========================================================================
w("h1-foundation/infrastructure-provisioning/skeleton/terraform/variables.tf",
  'variable "environment" {\n  type    = string\n  default = "dev"\n}\n\nvariable "location" {\n  type    = string\n  default = "centralus"\n\n  validation {\n    condition     = contains(["centralus", "eastus"], var.location)\n    error_message = "Only Central US and East US."\n  }\n}\n\nvariable "project_name" {\n  type = string\n}\n')
w("h1-foundation/infrastructure-provisioning/skeleton/terraform/outputs.tf",
  'output "resource_group_name" {\n  value = azurerm_resource_group.main.name\n}\n\noutput "location" {\n  value = azurerm_resource_group.main.location\n}\n')
w("h1-foundation/infrastructure-provisioning/skeleton/terraform/providers.tf",
  'terraform {\n  required_version = ">= 1.5"\n  required_providers {\n    azurerm = {\n      source  = "hashicorp/azurerm"\n      version = "~> 3.85"\n    }\n  }\n}\n\nprovider "azurerm" {\n  features {}\n}\n')
w("h1-foundation/infrastructure-provisioning/skeleton/.github/workflows/terraform.yaml",
  "name: Terraform\non:\n  push:\n    branches: [main]\n  pull_request:\njobs:\n  plan:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - uses: hashicorp/setup-terraform@v3\n      - run: cd terraform && terraform init\n      - run: cd terraform && terraform plan\n")
w("h1-foundation/infrastructure-provisioning/skeleton/.devcontainer/devcontainer.json",
  dc("Infra", "mcr.microsoft.com/devcontainers/base:ubuntu",
     features={"ghcr.io/devcontainers/features/terraform:1": {"version": "1.7"}, "ghcr.io/devcontainers/features/azure-cli:1": {}}))
print("  H1 infrastructure-provisioning: OK")

# =========================================================================
# H2: ado-to-github-migration
# =========================================================================
w("h2-enhancement/ado-to-github-migration/skeleton/scripts/migrate-repos.sh",
  '#!/bin/bash\nset -euo pipefail\necho "Migrating repos from ADO to GitHub..."\necho "ADO Org: $ADO_ORG"\necho "GitHub Org: $GITHUB_ORG"\n')
w("h2-enhancement/ado-to-github-migration/skeleton/scripts/migrate-pipelines.sh",
  '#!/bin/bash\nset -euo pipefail\necho "Converting Azure Pipelines to GitHub Actions..."\n')
w("h2-enhancement/ado-to-github-migration/skeleton/scripts/migrate-boards.sh",
  '#!/bin/bash\nset -euo pipefail\necho "Migrating Azure Boards work items to GitHub Issues..."\n')
w("h2-enhancement/ado-to-github-migration/skeleton/config/migration.yaml",
  "source:\n  type: azure-devops\n  organization: ''\n  project: ''\ntarget:\n  type: github\n  organization: ''\nscope:\n  repos: true\n  pipelines: true\n  boards: false\n  artifacts: false\n")
w("h2-enhancement/ado-to-github-migration/skeleton/.github/workflows/migration.yaml",
  "name: Migration\non:\n  workflow_dispatch:\njobs:\n  migrate:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - run: chmod +x scripts/*.sh\n      - run: ./scripts/migrate-repos.sh\n")
w("h2-enhancement/ado-to-github-migration/skeleton/.devcontainer/devcontainer.json",
  dc("Migration", "mcr.microsoft.com/devcontainers/base:ubuntu",
     features={"ghcr.io/devcontainers/features/azure-cli:1": {}, "ghcr.io/devcontainers/features/github-cli:1": {}, "ghcr.io/devcontainers/features/node:1": {"version": "20"}}))
print("  H2 ado-to-github-migration: OK")

# =========================================================================
# H2: api-gateway
# =========================================================================
w("h2-enhancement/api-gateway/skeleton/src/server.ts",
  'import express from "express";\nimport rateLimit from "express-rate-limit";\n\nconst app = express();\nconst limiter = rateLimit({ windowMs: 60000, max: 100 });\napp.use(limiter);\napp.use(express.json());\n\napp.get("/health", (_, res) => res.json({ status: "ok" }));\napp.all("/api/*", (req, res) => {\n  res.json({ message: "Gateway routing", path: req.path, method: req.method });\n});\n\napp.listen(3000, () => console.log("API Gateway on port 3000"));\n')
w("h2-enhancement/api-gateway/skeleton/package.json",
  json.dumps({"name": "api-gateway", "version": "1.0.0", "scripts": {"start": "ts-node src/server.ts", "build": "tsc", "test": "jest"}, "dependencies": {"express": "^4.18.0", "express-rate-limit": "^7.0.0"}, "devDependencies": {"@types/express": "^4.17.0", "ts-node": "^10.9.0", "typescript": "^5.0.0"}}, indent=2))
w("h2-enhancement/api-gateway/skeleton/tsconfig.json",
  json.dumps({"compilerOptions": {"target": "ES2020", "module": "commonjs", "outDir": "dist", "strict": True}, "include": ["src"]}, indent=2))
w("h2-enhancement/api-gateway/skeleton/Dockerfile",
  "FROM node:20-alpine\nWORKDIR /app\nCOPY package*.json ./\nRUN npm ci --production\nCOPY dist/ ./dist/\nUSER node\nEXPOSE 3000\nCMD [\"node\", \"dist/server.js\"]\n")
w("h2-enhancement/api-gateway/skeleton/.github/workflows/ci.yaml",
  "name: CI\non: [push, pull_request]\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - uses: actions/setup-node@v4\n        with:\n          node-version: '20'\n      - run: npm ci\n      - run: npm run build\n")
w("h2-enhancement/api-gateway/skeleton/.devcontainer/devcontainer.json",
  dc("API Gateway", "mcr.microsoft.com/devcontainers/javascript-node:20",
     features={"ghcr.io/devcontainers/features/docker-in-docker:2": {}},
     post_cmd="npm ci", ports=[3000]))
print("  H2 api-gateway: OK")

# =========================================================================
# H2: batch-job
# =========================================================================
w("h2-enhancement/batch-job/skeleton/src/main.py",
  'import logging\nimport time\n\nlogging.basicConfig(level=logging.INFO)\nlogger = logging.getLogger(__name__)\n\ndef run_batch():\n    logger.info("Starting batch job...")\n    time.sleep(2)\n    logger.info("Processing records...")\n    logger.info("Batch job completed.")\n\nif __name__ == "__main__":\n    run_batch()\n')
w("h2-enhancement/batch-job/skeleton/requirements.txt", "structlog>=23.0\npydantic>=2.0\n")
w("h2-enhancement/batch-job/skeleton/Dockerfile",
  "FROM python:3.11-slim\nWORKDIR /app\nCOPY requirements.txt .\nRUN pip install --no-cache-dir -r requirements.txt\nCOPY src/ ./src/\nUSER 1001\nCMD [\"python\", \"src/main.py\"]\n")
w("h2-enhancement/batch-job/skeleton/deploy/cronjob.yaml",
  "apiVersion: batch/v1\nkind: CronJob\nmetadata:\n  name: batch-job\nspec:\n  schedule: '0 2 * * *'\n  jobTemplate:\n    spec:\n      template:\n        spec:\n          containers:\n            - name: batch\n              image: batch-job:latest\n          restartPolicy: OnFailure\n")
w("h2-enhancement/batch-job/skeleton/.github/workflows/ci.yaml",
  "name: CI\non: [push, pull_request]\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - uses: actions/setup-python@v5\n        with:\n          python-version: '3.11'\n      - run: pip install -r requirements.txt\n      - run: python -m pytest tests/ -v || true\n")
w("h2-enhancement/batch-job/skeleton/.devcontainer/devcontainer.json",
  dc("Batch Job", "mcr.microsoft.com/devcontainers/python:3.11",
     post_cmd="pip install -r requirements.txt"))
print("  H2 batch-job: OK")

# =========================================================================
# H2: data-pipeline
# =========================================================================
w("h2-enhancement/data-pipeline/skeleton/src/pipeline.py",
  'import logging\n\nlogger = logging.getLogger(__name__)\n\ndef extract(source: str):\n    logger.info(f"Extracting data from {source}")\n    return [{"id": 1, "value": "sample"}]\n\ndef transform(data: list):\n    logger.info(f"Transforming {len(data)} records")\n    return [{"id": r["id"], "value": r["value"].upper()} for r in data]\n\ndef load(data: list, target: str):\n    logger.info(f"Loading {len(data)} records to {target}")\n\ndef run():\n    data = extract("azure-blob")\n    transformed = transform(data)\n    load(transformed, "azure-sql")\n    logger.info("Pipeline complete")\n\nif __name__ == "__main__":\n    logging.basicConfig(level=logging.INFO)\n    run()\n')
w("h2-enhancement/data-pipeline/skeleton/requirements.txt", "azure-storage-blob>=12.0\nazure-identity>=1.14\npydantic>=2.0\nstructlog>=23.0\n")
w("h2-enhancement/data-pipeline/skeleton/Dockerfile",
  "FROM python:3.11-slim\nWORKDIR /app\nCOPY requirements.txt .\nRUN pip install --no-cache-dir -r requirements.txt\nCOPY src/ ./src/\nUSER 1001\nCMD [\"python\", \"src/pipeline.py\"]\n")
w("h2-enhancement/data-pipeline/skeleton/.github/workflows/ci.yaml",
  "name: CI\non: [push, pull_request]\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - uses: actions/setup-python@v5\n        with:\n          python-version: '3.11'\n      - run: pip install -r requirements.txt\n      - run: python -m pytest tests/ -v || true\n")
w("h2-enhancement/data-pipeline/skeleton/.devcontainer/devcontainer.json",
  dc("Data Pipeline", "mcr.microsoft.com/devcontainers/python:3.11",
     features={"ghcr.io/devcontainers/features/azure-cli:1": {}},
     post_cmd="pip install -r requirements.txt", ports=[8080]))
print("  H2 data-pipeline: OK")

# =========================================================================
# H2: event-driven-microservice
# =========================================================================
w("h2-enhancement/event-driven-microservice/skeleton/src/consumer.py",
  'import asyncio\nimport logging\n\nlogger = logging.getLogger(__name__)\n\nasync def consume_events():\n    logger.info("Starting event consumer...")\n    while True:\n        logger.info("Waiting for events...")\n        await asyncio.sleep(5)\n\nif __name__ == "__main__":\n    logging.basicConfig(level=logging.INFO)\n    asyncio.run(consume_events())\n')
w("h2-enhancement/event-driven-microservice/skeleton/src/producer.py",
  'import logging\n\nlogger = logging.getLogger(__name__)\n\ndef publish_event(topic: str, message: dict):\n    logger.info(f"Publishing to {topic}: {message}")\n')
w("h2-enhancement/event-driven-microservice/skeleton/requirements.txt", "aiokafka>=0.9\nfastapi>=0.104\nuvicorn>=0.24\npydantic>=2.0\n")
w("h2-enhancement/event-driven-microservice/skeleton/Dockerfile",
  "FROM python:3.11-slim\nWORKDIR /app\nCOPY requirements.txt .\nRUN pip install --no-cache-dir -r requirements.txt\nCOPY src/ ./src/\nUSER 1001\nEXPOSE 8000\nCMD [\"python\", \"src/consumer.py\"]\n")
w("h2-enhancement/event-driven-microservice/skeleton/.github/workflows/ci.yaml",
  "name: CI\non: [push, pull_request]\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - uses: actions/setup-python@v5\n        with:\n          python-version: '3.11'\n      - run: pip install -r requirements.txt\n      - run: python -m pytest tests/ -v || true\n")
w("h2-enhancement/event-driven-microservice/skeleton/.devcontainer/devcontainer.json",
  dc("Event Service", "mcr.microsoft.com/devcontainers/python:3.11",
     features={"ghcr.io/devcontainers/features/docker-in-docker:2": {}},
     post_cmd="pip install -r requirements.txt", ports=[8000]))
print("  H2 event-driven-microservice: OK")

# =========================================================================
# H2: gitops-deployment
# =========================================================================
w("h2-enhancement/gitops-deployment/skeleton/base/kustomization.yaml",
  "apiVersion: kustomize.config.k8s.io/v1beta1\nkind: Kustomization\nresources:\n  - deployment.yaml\n  - service.yaml\n")
w("h2-enhancement/gitops-deployment/skeleton/base/deployment.yaml",
  "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: app\nspec:\n  replicas: 2\n  selector:\n    matchLabels:\n      app: app\n  template:\n    metadata:\n      labels:\n        app: app\n    spec:\n      containers:\n        - name: app\n          image: app:latest\n          ports:\n            - containerPort: 8080\n          resources:\n            requests:\n              cpu: 100m\n              memory: 128Mi\n            limits:\n              cpu: 500m\n              memory: 512Mi\n")
w("h2-enhancement/gitops-deployment/skeleton/base/service.yaml",
  "apiVersion: v1\nkind: Service\nmetadata:\n  name: app\nspec:\n  selector:\n    app: app\n  ports:\n    - port: 80\n      targetPort: 8080\n")
w("h2-enhancement/gitops-deployment/skeleton/overlays/dev/kustomization.yaml",
  "apiVersion: kustomize.config.k8s.io/v1beta1\nkind: Kustomization\nresources:\n  - ../../base\npatchesStrategicMerge:\n  - patch.yaml\n")
w("h2-enhancement/gitops-deployment/skeleton/overlays/dev/patch.yaml",
  "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: app\nspec:\n  replicas: 1\n")
w("h2-enhancement/gitops-deployment/skeleton/overlays/prod/kustomization.yaml",
  "apiVersion: kustomize.config.k8s.io/v1beta1\nkind: Kustomization\nresources:\n  - ../../base\npatchesStrategicMerge:\n  - patch.yaml\n")
w("h2-enhancement/gitops-deployment/skeleton/overlays/prod/patch.yaml",
  "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: app\nspec:\n  replicas: 3\n")
w("h2-enhancement/gitops-deployment/skeleton/argocd-app.yaml",
  "apiVersion: argoproj.io/v1alpha1\nkind: Application\nmetadata:\n  name: app\n  namespace: argocd\nspec:\n  project: default\n  source:\n    repoURL: ''\n    path: overlays/dev\n    targetRevision: main\n  destination:\n    server: https://kubernetes.default.svc\n    namespace: apps\n  syncPolicy:\n    automated:\n      prune: true\n      selfHeal: true\n")
w("h2-enhancement/gitops-deployment/skeleton/.devcontainer/devcontainer.json",
  dc("GitOps", "mcr.microsoft.com/devcontainers/base:ubuntu",
     features={"ghcr.io/devcontainers/features/kubectl-helm-minikube:1": {}, "ghcr.io/devcontainers/features/github-cli:1": {}}))
print("  H2 gitops-deployment: OK")

# =========================================================================
# H2: microservice
# =========================================================================
w("h2-enhancement/microservice/skeleton/src/main.py",
  'from fastapi import FastAPI\nimport logging\n\napp = FastAPI(title="Microservice")\nlogger = logging.getLogger(__name__)\n\n@app.get("/health")\ndef health():\n    return {"status": "ok"}\n\n@app.get("/")\ndef root():\n    return {"message": "Hello from microservice"}\n')
w("h2-enhancement/microservice/skeleton/requirements.txt", "fastapi>=0.104\nuvicorn>=0.24\nstructlog>=23.0\nprometheus-client>=0.19\n")
w("h2-enhancement/microservice/skeleton/Dockerfile",
  "FROM python:3.11-slim\nWORKDIR /app\nCOPY requirements.txt .\nRUN pip install --no-cache-dir -r requirements.txt\nCOPY src/ ./src/\nUSER 1001\nEXPOSE 8000\nCMD [\"uvicorn\", \"src.main:app\", \"--host\", \"0.0.0.0\", \"--port\", \"8000\"]\n")
w("h2-enhancement/microservice/skeleton/deploy/deployment.yaml",
  "apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: microservice\nspec:\n  replicas: 2\n  selector:\n    matchLabels:\n      app: microservice\n  template:\n    metadata:\n      labels:\n        app: microservice\n    spec:\n      containers:\n        - name: app\n          image: microservice:latest\n          ports:\n            - containerPort: 8000\n          livenessProbe:\n            httpGet:\n              path: /health\n              port: 8000\n          readinessProbe:\n            httpGet:\n              path: /health\n              port: 8000\n")
w("h2-enhancement/microservice/skeleton/.github/workflows/ci.yaml",
  "name: CI\non: [push, pull_request]\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - uses: actions/setup-python@v5\n        with:\n          python-version: '3.11'\n      - run: pip install -r requirements.txt\n      - run: python -m pytest tests/ -v || true\n")
w("h2-enhancement/microservice/skeleton/.devcontainer/devcontainer.json",
  dc("Microservice", "mcr.microsoft.com/devcontainers/python:3.11",
     features={"ghcr.io/devcontainers/features/docker-in-docker:2": {}},
     post_cmd="pip install -r requirements.txt", ports=[8000]))
print("  H2 microservice: OK")

# =========================================================================
# H2: reusable-workflows
# =========================================================================
w("h2-enhancement/reusable-workflows/skeleton/.github/workflows/build.yaml",
  "name: Reusable Build\non:\n  workflow_call:\n    inputs:\n      language:\n        required: true\n        type: string\n      node-version:\n        required: false\n        type: string\n        default: '20'\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - if: inputs.language == 'node'\n        uses: actions/setup-node@v4\n        with:\n          node-version: ${{ inputs.node-version }}\n      - if: inputs.language == 'python'\n        uses: actions/setup-python@v5\n      - run: echo 'Build step for ${{ inputs.language }}'\n")
w("h2-enhancement/reusable-workflows/skeleton/.github/workflows/security-scan.yaml",
  "name: Reusable Security Scan\non:\n  workflow_call:\njobs:\n  scan:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v4\n      - uses: github/codeql-action/init@v3\n      - uses: github/codeql-action/autobuild@v3\n      - uses: github/codeql-action/analyze@v3\n")
w("h2-enhancement/reusable-workflows/skeleton/.github/workflows/deploy.yaml",
  "name: Reusable Deploy\non:\n  workflow_call:\n    inputs:\n      environment:\n        required: true\n        type: string\n    secrets:\n      AZURE_CREDENTIALS:\n        required: true\njobs:\n  deploy:\n    runs-on: ubuntu-latest\n    environment: ${{ inputs.environment }}\n    steps:\n      - uses: actions/checkout@v4\n      - run: echo 'Deploying to ${{ inputs.environment }}'\n")
w("h2-enhancement/reusable-workflows/skeleton/.devcontainer/devcontainer.json",
  dc("Workflows", "mcr.microsoft.com/devcontainers/base:ubuntu",
     features={"ghcr.io/devcontainers/features/github-cli:1": {}}))
print("  H2 reusable-workflows: OK")

# =========================================================================
# Summary
# =========================================================================
print("\n=== ALL H1 + H2 SKELETONS COMPLETE ===")
total = 0
for horizon in ["h1-foundation", "h2-enhancement"]:
    for template in sorted(os.listdir(os.path.join(GP, horizon))):
        skel = os.path.join(GP, horizon, template, "skeleton")
        if os.path.isdir(skel):
            count = sum(1 for _, _, files in os.walk(skel) for _ in files)
            total += count
            print(f"  {horizon}/{template}: {count} files")
print(f"\nTotal: {total} skeleton files")
