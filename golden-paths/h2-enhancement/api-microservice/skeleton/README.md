# ${{values.name}}

${{values.description}}

## Overview

This API microservice was created using the Open Horizons Platform - H2 Enhancement template.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |
| Language | ${{values.language}} |
| Framework | FastAPI |

## Features

- OpenAPI 3.0 specification
- JWT authentication
- PostgreSQL database integration
- Redis caching
- Prometheus metrics
- Health check endpoints
- Structured logging
- Request validation

## Getting Started

### Prerequisites

- Python 3.11+
- PostgreSQL
- Redis
- Docker

### Environment Variables

```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/db

# Redis
REDIS_URL=redis://localhost:6379

# Authentication
JWT_SECRET=your-secret-key
JWT_ALGORITHM=HS256

# Application
LOG_LEVEL=INFO
DEBUG=false
```

### Local Development

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run migrations
alembic upgrade head

# Run development server
uvicorn src.main:app --reload

# Run tests
pytest
```

### Docker

```bash
# Build
docker build -t ${{values.name}}:local .

# Run
docker run -p 8000:8000 --env-file .env ${{values.name}}:local
```

## API Documentation

- OpenAPI UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
- OpenAPI JSON: http://localhost:8000/openapi.json

## Project Structure

```
src/
├── main.py           # Application entry point
├── api/
│   ├── v1/           # API v1 routes
│   └── deps.py       # Dependencies
├── core/
│   ├── config.py     # Configuration
│   └── security.py   # Auth utilities
├── models/           # SQLAlchemy models
├── schemas/          # Pydantic schemas
├── services/         # Business logic
└── repositories/     # Data access
```

## Testing

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test
pytest tests/test_api.py -v
```

## Links

- [Open Horizons Documentation](https://github.com/${{values.repoUrl | parseRepoUrl | pick('owner') }}/agentic-devops-platform)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
