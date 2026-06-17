# H1 Foundation Templates

Foundation-level templates for basic infrastructure and application scaffolding.

## Available Templates

| Template | Description | Complexity |
|----------|-------------|------------|
| `basic-cicd` | Simple CI/CD pipeline for any project | Simple |
| `documentation-site` | Documentation website using MkDocs/Docusaurus | Simple |
| `infrastructure-provisioning` | Terraform module scaffolding | Medium |
| `new-microservice` | Basic microservice starter | Simple |
| `security-baseline` | Security configuration baseline | Medium |
| `web-application` | Full-stack web application | Medium |

## Template Details

### basic-cicd

Creates a basic CI/CD pipeline with:
- Build workflow
- Test workflow
- Deploy workflow
- Environment configuration

### documentation-site

Creates a documentation website with:
- MkDocs or Docusaurus setup
- GitHub Pages deployment
- Search functionality
- Custom theming

### infrastructure-provisioning

Creates a Terraform module structure with:
- Standard module layout (main.tf, variables.tf, outputs.tf)
- Testing scaffolding
- Documentation
- CI/CD for Terraform

### new-microservice

Creates a basic microservice with:
- Language-specific project structure
- Dockerfile
- Basic CI/CD
- Health endpoint

### security-baseline

Creates security configuration including:
- Network security rules
- RBAC configuration
- Secret management setup
- Compliance scanning

### web-application

Creates a full-stack web application with:
- Frontend (React/Vue/Angular)
- Backend API
- Database setup
- Complete CI/CD pipeline

## Usage

Select any template from the Backstage portal under "Create" → "Choose a Template" → "H1 Foundation".

## Related Documentation

- [Golden Paths Overview](../README.md)
- [Platform Agent](../../.github/agents/platform.agent.md)
