"""Cosmos DB memory probe for BFF and agent thread storage."""

from __future__ import annotations

from dataclasses import dataclass
from importlib import import_module
from time import time
from typing import Any

from .config import Settings


class CosmosMemoryUnavailable(RuntimeError):
    """Raised when Cosmos memory is disabled or cannot be reached."""


@dataclass(frozen=True)
class CosmosMemoryProbeResult:
    status: str
    database: str
    container: str
    tenant_id: str
    document_id: str


class CosmosMemoryClient:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.enabled = settings.cosmos_memory_enabled

    @classmethod
    def from_settings(cls, settings: Settings) -> "CosmosMemoryClient":
        return cls(settings)

    def probe(self) -> CosmosMemoryProbeResult:
        if not self.enabled:
            raise CosmosMemoryUnavailable("Cosmos memory is disabled")
        if not self.settings.cosmos_endpoint:
            raise CosmosMemoryUnavailable("COSMOS_ENDPOINT is required")

        container = self._container()
        document = {
            "id": "spec001-dev-memory-probe",
            "tenant_id": self.settings.cosmos_tenant_id,
            "type": "memory-probe",
            "updated_at_epoch": int(time()),
            "source": "foundry-agents",
        }
        container.upsert_item(document)
        persisted = container.read_item(
            item=document["id"],
            partition_key=document["tenant_id"],
        )
        return CosmosMemoryProbeResult(
            status="ok",
            database=self.settings.cosmos_database_name,
            container=self.settings.cosmos_container_name,
            tenant_id=str(persisted["tenant_id"]),
            document_id=str(persisted["id"]),
        )

    def _container(self) -> Any:
        credential = self._credential()
        cosmos_module = import_module("azure.cosmos")

        client = cosmos_module.CosmosClient(
            self.settings.cosmos_endpoint,
            credential=credential,
        )
        database = client.get_database_client(self.settings.cosmos_database_name)
        return database.get_container_client(self.settings.cosmos_container_name)

    def _credential(self) -> Any:
        if (
            self.settings.azure_tenant_id
            and self.settings.azure_client_id
            and self.settings.azure_client_secret
        ):
            identity_module = import_module("azure.identity")

            return identity_module.ClientSecretCredential(
                tenant_id=self.settings.azure_tenant_id,
                client_id=self.settings.azure_client_id,
                client_secret=self.settings.azure_client_secret,
            )

        identity_module = import_module("azure.identity")

        return identity_module.DefaultAzureCredential(
            exclude_interactive_browser_credential=True,
        )