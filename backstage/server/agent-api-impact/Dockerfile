FROM python:3.12-slim

WORKDIR /app

RUN groupadd --system app && useradd --system --gid app --home-dir /app --shell /usr/sbin/nologin app && \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN mkdir -p /app/data && chown -R app:app /app

USER app

EXPOSE 8011

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8011"]
