# syntax=docker/dockerfile:1.6
FROM python:3.11-slim AS base

USER 0
WORKDIR /opt/app

COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY app ./app

# Run as non-root (UBI Python image uses uid 1001 by default)
USER 1001

ENV PORT=8080 \
    LOG_LEVEL=INFO

EXPOSE 8080

# uvicorn with single worker; scale via replicas
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "1"]
