---
applyTo: "**/*.py,**/python/**"
description: "Python coding standards — FastAPI, Pydantic, structlog, PEP 8, and project structure conventions."
---

# Python Coding Standards

## Project Structure

```
project/
├── src/
│   └── package_name/
│       ├── __init__.py
│       ├── main.py
│       └── utils/
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   └── test_main.py
├── pyproject.toml
├── requirements.txt
├── Dockerfile
└── README.md
```

## Code Style

### Formatting
- Use `ruff` or `black` for formatting
- Line length: 88 characters (black default)
- Use double quotes for strings
- Use trailing commas in multi-line structures

### Imports
```python
# Standard library
import os
import sys
from pathlib import Path

# Third-party
import requests
from fastapi import FastAPI

# Local
from .utils import helper
from .models import User
```

### Type Hints
```python
from typing import Optional, List, Dict

def process_data(
    items: List[str],
    config: Optional[Dict[str, str]] = None,
) -> Dict[str, int]:
    """Process a list of items and return counts."""
    result: Dict[str, int] = {}
    # implementation
    return result
```

## FastAPI Standards

```python
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel, Field
import structlog

logger = structlog.get_logger()

app = FastAPI(
    title="Service Name",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

class HealthResponse(BaseModel):
    status: str = Field(..., example="healthy")
    version: str = Field(..., example="1.0.0")

@app.get("/healthz", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """Health check endpoint."""
    return HealthResponse(status="healthy", version="1.0.0")

@app.get("/ready")
async def readiness_check() -> dict:
    """Readiness check endpoint."""
    # Check dependencies
    return {"status": "ready"}
```

## Error Handling

```python
from fastapi import HTTPException
import structlog

logger = structlog.get_logger()

class ServiceError(Exception):
    """Base exception for service errors."""
    def __init__(self, message: str, code: str):
        self.message = message
        self.code = code
        super().__init__(message)

async def handle_request():
    try:
        # operation
        pass
    except ServiceError as e:
        logger.error("service_error", code=e.code, message=e.message)
        raise HTTPException(status_code=400, detail=e.message)
    except Exception as e:
        logger.exception("unexpected_error")
        raise HTTPException(status_code=500, detail="Internal server error")
```

## Logging

```python
import structlog

structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),
    ],
    logger_factory=structlog.stdlib.LoggerFactory(),
)

logger = structlog.get_logger()

# Usage
logger.info("processing_request", request_id=request_id, user_id=user_id)
logger.error("operation_failed", error=str(e), context=context)
```

## Testing

```python
import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch

@pytest.fixture
def client():
    from main import app
    return TestClient(app)

def test_health_check(client):
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

@pytest.mark.asyncio
async def test_async_function():
    result = await async_function()
    assert result is not None
```

## Security Requirements

- NEVER hardcode secrets
- Use environment variables for configuration
- Validate all input with Pydantic
- Use parameterized queries for databases
- Sanitize log output (no PII, no secrets)
- Use secrets managers (Azure Key Vault)

## Dependencies

```toml
# pyproject.toml
[project]
name = "service-name"
version = "1.0.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.109.0",
    "uvicorn>=0.27.0",
    "pydantic>=2.5.0",
    "structlog>=24.1.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "ruff>=0.2.0",
    "mypy>=1.8.0",
]
```
