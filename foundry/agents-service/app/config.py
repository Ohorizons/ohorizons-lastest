"""Configuration loaded from environment."""
from __future__ import annotations

import os
from dataclasses import dataclass


def _env_bool(name: str, default: bool = False) -> bool:
    value = os.environ.get(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


@dataclass(frozen=True)
class Settings:
    azure_openai_endpoint: str
    azure_openai_deployment: str
    azure_openai_api_version: str
    azure_openai_embedding_deployment: str
    # Either api_key OR (tenant_id, client_id, client_secret) must be set
    azure_openai_api_key: str | None
    azure_tenant_id: str | None
    azure_client_id: str | None
    azure_client_secret: str | None
    service_api_key: str | None
    cosmos_memory_enabled: bool
    cosmos_endpoint: str | None
    cosmos_database_name: str
    cosmos_container_name: str
    cosmos_tenant_id: str
    log_level: str
    request_timeout_seconds: int
    # Prompt/response cache (REQ-CACHE-001..006). Disabled by default — flip
    # PROMPT_CACHE_ENABLED=true once a Redis (Azure Managed Redis) URL is wired.
    prompt_cache_enabled: bool
    redis_url: str | None
    # Application Insights connection string for the 21-field LLM-call telemetry
    # (REQ-FINOPS-001). Empty ⇒ telemetry emission is a no-op.
    app_insights_connection_string: str | None

    @property
    def auth_mode(self) -> str:
        if self.azure_openai_api_key:
            return "api-key"
        if self.azure_tenant_id and self.azure_client_id and self.azure_client_secret:
            return "aad"
        return "none"

    @classmethod
    def from_env(cls) -> "Settings":
        endpoint = os.environ.get("AZURE_OPENAI_ENDPOINT", "").rstrip("/")
        if not endpoint:
            raise RuntimeError("AZURE_OPENAI_ENDPOINT is required")

        api_key = os.environ.get("AZURE_OPENAI_API_KEY") or None
        tenant = os.environ.get("AZURE_TENANT_ID") or None
        client = os.environ.get("AZURE_CLIENT_ID") or None
        secret = os.environ.get("AZURE_CLIENT_SECRET") or None

        if not api_key and not (tenant and client and secret):
            raise RuntimeError(
                "must provide either AZURE_OPENAI_API_KEY, or AZURE_TENANT_ID + "
                "AZURE_CLIENT_ID + AZURE_CLIENT_SECRET"
            )

        return cls(
            azure_openai_endpoint=endpoint,
            azure_openai_deployment=os.environ.get(
                "AZURE_OPENAI_DEPLOYMENT", "gpt-4o"
            ),
            azure_openai_api_version=os.environ.get(
                "AZURE_OPENAI_API_VERSION", "2024-08-01-preview"
            ),
            azure_openai_embedding_deployment=os.environ.get(
                "AZURE_OPENAI_EMBEDDING_DEPLOYMENT", "text-embedding-3-large"
            ),
            azure_openai_api_key=api_key,
            azure_tenant_id=tenant,
            azure_client_id=client,
            azure_client_secret=secret,
            service_api_key=os.environ.get("SERVICE_API_KEY") or None,
            cosmos_memory_enabled=_env_bool("COSMOS_MEMORY_ENABLED"),
            cosmos_endpoint=(os.environ.get("COSMOS_ENDPOINT") or "").rstrip("/") or None,
            cosmos_database_name=os.environ.get(
                "COSMOS_DATABASE_NAME", "enterprise_memory"
            ),
            cosmos_container_name=os.environ.get(
                "COSMOS_CONTAINER_NAME", "thread-message-store"
            ),
            cosmos_tenant_id=os.environ.get("COSMOS_TENANT_ID", "dev"),
            log_level=os.environ.get("LOG_LEVEL", "INFO").upper(),
            request_timeout_seconds=int(
                os.environ.get("REQUEST_TIMEOUT_SECONDS", "60")
            ),
            prompt_cache_enabled=_env_bool("PROMPT_CACHE_ENABLED"),
            redis_url=(os.environ.get("REDIS_URL") or os.environ.get("AZURE_REDIS_URL") or "") or None,
            app_insights_connection_string=(os.environ.get("APPLICATIONINSIGHTS_CONNECTION_STRING") or "") or None,
        )
