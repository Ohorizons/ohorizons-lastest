"""Azure OpenAI client wrapper.

Translates between OpenAI-compatible payloads (chat.completions) and
Azure OpenAI's deployment-scoped API. Supports two auth modes:

- ``api-key``  → header ``api-key: <key>`` (when local auth is enabled)
- ``aad``      → header ``Authorization: Bearer <token>`` using a
                 client-credentials flow against
                 ``https://cognitiveservices.azure.com/.default``

Tokens are cached in-memory and refreshed when within 5 minutes of expiry.
"""
from __future__ import annotations

import logging
import threading
import time
from dataclasses import dataclass
from typing import Any, AsyncIterator

import httpx

logger = logging.getLogger(__name__)

_AAD_SCOPE = "https://cognitiveservices.azure.com/.default"
_TOKEN_REFRESH_BUFFER_SECONDS = 5 * 60


@dataclass
class AadCredentials:
    tenant_id: str
    client_id: str
    client_secret: str


class AzureOpenAIClient:
    """Async client for Azure OpenAI Chat Completions."""

    def __init__(
        self,
        endpoint: str,
        deployment: str,
        api_version: str,
        *,
        api_key: str | None = None,
        aad_credentials: AadCredentials | None = None,
        timeout_seconds: int = 60,
    ) -> None:
        if not api_key and not aad_credentials:
            raise ValueError("either api_key or aad_credentials must be provided")
        self._endpoint = endpoint.rstrip("/")
        self._api_key = api_key
        self._aad = aad_credentials
        self._deployment = deployment
        self._api_version = api_version
        self._timeout = httpx.Timeout(timeout_seconds)
        self._cached_token: str | None = None
        self._cached_token_expires_at: float = 0.0
        self._token_lock = threading.Lock()

    # ── auth ─────────────────────────────────────────────
    def _build_auth_headers(self) -> dict[str, str]:
        if self._api_key:
            return {"api-key": self._api_key}
        token = self._get_aad_token()
        return {"Authorization": f"Bearer {token}"}

    def _get_aad_token(self) -> str:
        now = time.time()
        if (
            self._cached_token
            and now < self._cached_token_expires_at - _TOKEN_REFRESH_BUFFER_SECONDS
        ):
            return self._cached_token

        with self._token_lock:
            if (
                self._cached_token
                and time.time()
                < self._cached_token_expires_at - _TOKEN_REFRESH_BUFFER_SECONDS
            ):
                return self._cached_token

            assert self._aad is not None
            url = (
                f"https://login.microsoftonline.com/{self._aad.tenant_id}"
                "/oauth2/v2.0/token"
            )
            data = {
                "grant_type": "client_credentials",
                "client_id": self._aad.client_id,
                "client_secret": self._aad.client_secret,
                "scope": _AAD_SCOPE,
            }
            resp = httpx.post(url, data=data, timeout=15.0)
            resp.raise_for_status()
            payload = resp.json()
            self._cached_token = payload["access_token"]
            self._cached_token_expires_at = time.time() + int(
                payload.get("expires_in", 3600)
            )
            logger.info(
                "acquired AAD token for cognitiveservices (expires_in=%s)",
                payload.get("expires_in"),
            )
            return self._cached_token  # type: ignore[return-value]

    # ── url ──────────────────────────────────────────────
    def _chat_url(self, deployment: str | None = None) -> str:
        dep = deployment or self._deployment
        return (
            f"{self._endpoint}/openai/deployments/{dep}/chat/completions"
            f"?api-version={self._api_version}"
        )

    # ── public API ───────────────────────────────────────
    async def chat_completion(
        self,
        messages: list[dict[str, Any]],
        *,
        model: str | None = None,
        temperature: float | None = None,
        max_tokens: int | None = None,
        tools: list[dict[str, Any]] | None = None,
        tool_choice: Any | None = None,
        extra: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        payload: dict[str, Any] = {"messages": messages}
        if temperature is not None:
            payload["temperature"] = temperature
        if max_tokens is not None:
            payload["max_tokens"] = max_tokens
        if tools:
            payload["tools"] = tools
        if tool_choice is not None:
            payload["tool_choice"] = tool_choice
        if extra:
            payload.update(extra)

        deployment = model or self._deployment
        url = self._chat_url(deployment)
        headers = {**self._build_auth_headers(), "Content-Type": "application/json"}

        async with httpx.AsyncClient(timeout=self._timeout) as client:
            resp = await client.post(url, headers=headers, json=payload)
            if resp.status_code >= 400:
                logger.error(
                    "Azure OpenAI error %s: %s", resp.status_code, resp.text[:500]
                )
                resp.raise_for_status()
            return resp.json()

    async def chat_completion_stream(
        self,
        messages: list[dict[str, Any]],
        *,
        model: str | None = None,
        temperature: float | None = None,
        max_tokens: int | None = None,
        tools: list[dict[str, Any]] | None = None,
        tool_choice: Any | None = None,
        extra: dict[str, Any] | None = None,
    ) -> AsyncIterator[bytes]:
        payload: dict[str, Any] = {"messages": messages, "stream": True}
        if temperature is not None:
            payload["temperature"] = temperature
        if max_tokens is not None:
            payload["max_tokens"] = max_tokens
        if tools:
            payload["tools"] = tools
        if tool_choice is not None:
            payload["tool_choice"] = tool_choice
        if extra:
            payload.update(extra)

        deployment = model or self._deployment
        url = self._chat_url(deployment)
        headers = {**self._build_auth_headers(), "Content-Type": "application/json"}

        async with httpx.AsyncClient(timeout=self._timeout) as client:
            async with client.stream(
                "POST", url, headers=headers, json=payload
            ) as resp:
                if resp.status_code >= 400:
                    body = await resp.aread()
                    logger.error(
                        "Azure OpenAI stream error %s: %s",
                        resp.status_code,
                        body[:500],
                    )
                    resp.raise_for_status()
                async for chunk in resp.aiter_bytes():
                    if chunk:
                        yield chunk
