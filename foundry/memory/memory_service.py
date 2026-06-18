"""MemoryService contract and local provider implementations for REQ-MEMORY-001..006."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from enum import StrEnum
from time import time
from typing import Any, Protocol

USER_PROFILE_COLLECTION = "user_profile_memory"
CHAT_SUMMARY_COLLECTION = "chat_summary_memory"
DEFAULT_UPDATE_DELAY_SECONDS = 120


class MemoryScope(StrEnum):
    USER = "user"
    TEAM = "team"
    ORG = "org"
    CUSTOM = "custom"


@dataclass(frozen=True)
class MemoryConfig:
    scope: MemoryScope = MemoryScope.USER
    update_delay_seconds: int = DEFAULT_UPDATE_DELAY_SECONDS


@dataclass(frozen=True)
class MemoryRecord:
    collection: str
    key: str
    value: dict[str, Any]
    scope: MemoryScope = MemoryScope.USER
    updated_at_epoch: int = field(default_factory=lambda: int(time()))


class KeyValueMemoryBackend(Protocol):
    def upsert(self, record: MemoryRecord) -> None: ...

    def get(self, collection: str, key: str) -> MemoryRecord | None: ...

    def list_for_user(self, user_id: str) -> list[MemoryRecord]: ...

    def delete_user(self, user_id: str) -> int: ...


class MemoryService(ABC):
    def __init__(self, config: MemoryConfig | None = None) -> None:
        self.config = config or MemoryConfig()

    @abstractmethod
    def upsert_user_profile(self, user_id: str, profile: dict[str, Any]) -> MemoryRecord:
        raise NotImplementedError

    @abstractmethod
    def get_user_profile(self, user_id: str) -> dict[str, Any] | None:
        raise NotImplementedError

    @abstractmethod
    def save_chat_summary(self, user_id: str, conversation_id: str, summary: str) -> MemoryRecord:
        raise NotImplementedError

    @abstractmethod
    def list_user_memories(self, user_id: str) -> list[MemoryRecord]:
        raise NotImplementedError

    @abstractmethod
    def purge_user_data(self, user_id: str) -> int:
        raise NotImplementedError


class InMemoryBackend:
    def __init__(self) -> None:
        self.records: dict[tuple[str, str], MemoryRecord] = {}

    def upsert(self, record: MemoryRecord) -> None:
        self.records[(record.collection, record.key)] = record

    def get(self, collection: str, key: str) -> MemoryRecord | None:
        return self.records.get((collection, key))

    def list_for_user(self, user_id: str) -> list[MemoryRecord]:
        return [
            record
            for record in self.records.values()
            if record.value.get("user_id") == user_id
        ]

    def delete_user(self, user_id: str) -> int:
        keys = [
            key
            for key, record in self.records.items()
            if record.value.get("user_id") == user_id
        ]
        for key in keys:
            del self.records[key]
        return len(keys)


class BackendMemoryService(MemoryService):
    def __init__(self, backend: KeyValueMemoryBackend, config: MemoryConfig | None = None) -> None:
        super().__init__(config)
        self.backend = backend

    def upsert_user_profile(self, user_id: str, profile: dict[str, Any]) -> MemoryRecord:
        record = MemoryRecord(
            collection=USER_PROFILE_COLLECTION,
            key=user_id,
            value={"user_id": user_id, "profile": profile},
            scope=self.config.scope,
        )
        self.backend.upsert(record)
        return record

    def get_user_profile(self, user_id: str) -> dict[str, Any] | None:
        record = self.backend.get(USER_PROFILE_COLLECTION, user_id)
        if record is None:
            return None
        return dict(record.value.get("profile", {}))

    def save_chat_summary(self, user_id: str, conversation_id: str, summary: str) -> MemoryRecord:
        record = MemoryRecord(
            collection=CHAT_SUMMARY_COLLECTION,
            key=f"{user_id}:{conversation_id}",
            value={
                "user_id": user_id,
                "conversation_id": conversation_id,
                "summary": summary,
            },
            scope=self.config.scope,
        )
        self.backend.upsert(record)
        return record

    def list_user_memories(self, user_id: str) -> list[MemoryRecord]:
        return self.backend.list_for_user(user_id)

    def purge_user_data(self, user_id: str) -> int:
        return self.backend.delete_user(user_id)


class FoundryMemoryService(BackendMemoryService):
    provider_name = "foundry"


class RedisMemoryService(BackendMemoryService):
    provider_name = "redis"
