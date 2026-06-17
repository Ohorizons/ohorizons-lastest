# =============================================================================
# Open Horizons — Infrastructure Provisioning (Pulumi)
# =============================================================================
"""Pulumi program for Azure infrastructure provisioning."""

import pulumi
from pulumi_azure_native import containerregistry, containerservice, keyvault, resources

config = pulumi.Config()
environment = config.get("environment") or "dev"
project_name = "${{ values.projectName }}"
location = "${{ values.azureRegion }}"

tags = {
    "environment": environment,
    "project": project_name,
    "managedBy": "pulumi",
    "createdBy": "open-horizons",
}

# =============================================================================
# Resource Group
# =============================================================================
rg = resources.ResourceGroup(
    f"rg-{project_name}-{environment}",
    resource_group_name=f"rg-{project_name}-{environment}",
    location=location,
    tags=tags,
)

# =============================================================================
# Container Registry
# =============================================================================
acr = containerregistry.Registry(
    f"acr{project_name.replace('-', '')}{environment}",
    registry_name=f"acr{project_name.replace('-', '')}{environment}",
    resource_group_name=rg.name,
    location=rg.location,
    sku=containerregistry.SkuArgs(name="Basic" if environment != "prod" else "Premium"),
    admin_user_enabled=False,
    tags=tags,
)

# =============================================================================
# Key Vault
# =============================================================================
kv = keyvault.Vault(
    f"kv-{project_name}-{environment}",
    vault_name=f"kv-{project_name}-{environment}",
    resource_group_name=rg.name,
    location=rg.location,
    properties=keyvault.VaultPropertiesArgs(
        sku=keyvault.SkuArgs(family="A", name=keyvault.SkuName.STANDARD),
        tenant_id=config.require("tenantId"),
        enable_rbac_authorization=True,
        enable_soft_delete=True,
        soft_delete_retention_in_days=90,
    ),
    tags=tags,
)

# =============================================================================
# AKS Cluster
# =============================================================================
aks = containerservice.ManagedCluster(
    f"aks-{project_name}-{environment}",
    resource_name_=f"aks-{project_name}-{environment}",
    resource_group_name=rg.name,
    location=rg.location,
    dns_prefix=f"{project_name}-{environment}",
    kubernetes_version="1.29",
    identity=containerservice.ManagedClusterIdentityArgs(
        type=containerservice.ResourceIdentityType.SYSTEM_ASSIGNED,
    ),
    agent_pool_profiles=[
        containerservice.ManagedClusterAgentPoolProfileArgs(
            name="system",
            count=3 if environment == "prod" else 1,
            vm_size="Standard_D4s_v5" if environment == "prod" else "Standard_D2s_v5",
            mode=containerservice.AgentPoolMode.SYSTEM,
            os_type=containerservice.OSType.LINUX,
            enable_auto_scaling=True,
            min_count=1,
            max_count=5 if environment == "prod" else 3,
        ),
    ],
    tags=tags,
)

# =============================================================================
# Outputs
# =============================================================================
pulumi.export("aksName", aks.name)
pulumi.export("acrName", acr.name)
pulumi.export("keyVaultName", kv.name)
pulumi.export("resourceGroupName", rg.name)
