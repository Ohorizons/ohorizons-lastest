# RAG Application Infrastructure

This directory is rendered into `deploy/infrastructure` by the RAG Application Golden Path.

## Resources

The Bicep template provisions the baseline Azure resources needed by the generated application:

- Azure Storage account and private document container
- Azure AI Search service
- Azure Application Insights component

Azure OpenAI or Azure AI Foundry model deployment is expected to be provided by the platform environment and referenced through configuration.

## Deployment

```bash
az deployment group create \
  --resource-group <resource-group> \
  --template-file main.bicep \
  --parameters appName=<app-name>
```

## References

- [Azure AI Search documentation](https://learn.microsoft.com/azure/search/)
- [Azure Storage documentation](https://learn.microsoft.com/azure/storage/)
- [Azure Application Insights documentation](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)
