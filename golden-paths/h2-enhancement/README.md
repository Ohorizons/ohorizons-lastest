# H2 Enhancement Templates

Advanced application patterns and platform integration templates.

## Available Templates

| Template | Description | Complexity |
|----------|-------------|------------|
| `ado-to-github-migration` | Azure DevOps to GitHub migration | Complex |
| `api-gateway` | API Management configuration | Medium |
| `api-microservice` | RESTful API service | Medium |
| `batch-job` | Scheduled batch processing | Medium |
| `data-pipeline` | ETL pipeline with Databricks | Complex |
| `event-driven-microservice` | Event Hubs/Service Bus integration | Complex |
| `gitops-deployment` | ArgoCD application manifest | Simple |
| `microservice` | Complete microservice with all features | Complex |
| `reusable-workflows` | GitHub Actions workflow library | Medium |

## Template Details

### ado-to-github-migration

Complete Azure DevOps to GitHub migration based on [Microsoft Migration Playbook](https://devblogs.microsoft.com/all-things-azure/azure-devops-to-github-migration-playbook-unlocking-agentic-devops/):

- **6-Phase Migration Process**
  - Phase 1: Environment Configuration
  - Phase 2: Azure Pipelines App Installation
  - Phase 3: Organization Inventory
  - Phase 4: Migration Script Generation
  - Phase 5: Script Execution
  - Phase 6: Post-Migration Validation

- **Features**
  - Repository migration with full history
  - Pipeline rewiring (ADO Pipelines → GitHub source)
  - Mannequin management (user attribution)
  - GitHub teams creation
  - GHAS enablement
  - Branch protection
  - Hybrid mode support (keep Azure Boards)

- **Validation Checklist**
  - All repositories accessible
  - Branches and tags preserved
  - Pipelines functional
  - Mannequins reclaimed
  - Documentation updated

### api-gateway

Creates API Management configuration with:
- API definitions (OpenAPI)
- Rate limiting policies
- Authentication configuration
- Backend service routing

### api-microservice

Creates a RESTful API service with:
- OpenAPI specification
- Request validation
- Error handling
- Observability integration

### batch-job

Creates scheduled batch processing with:
- Kubernetes CronJob
- Job monitoring
- Failure handling
- Output persistence

### data-pipeline

Creates an ETL pipeline with:
- Databricks notebook scaffolding
- Data source connectors
- Transformation logic
- Data quality checks

### event-driven-microservice

Creates event-driven architecture with:
- Event Hubs or Service Bus integration
- Message handling patterns
- Dead letter queue
- Retry policies

### gitops-deployment

Creates ArgoCD application with:
- Application manifest
- Sync policies
- Health checks
- Environment configuration

### microservice

Creates a complete microservice with:
- API endpoints
- Database integration
- Event publishing
- Full observability
- Complete CI/CD

### reusable-workflows

Creates GitHub Actions workflow library with:
- Reusable workflow definitions
- Composite actions
- Standard pipeline patterns
- Documentation

## Usage

Select any template from the Backstage portal under "Create" → "Choose a Template" → "H2 Enhancement".

## Related Documentation

- [Golden Paths Overview](../README.md)
- [DevOps Agent](../../.github/agents/devops.agent.md)
