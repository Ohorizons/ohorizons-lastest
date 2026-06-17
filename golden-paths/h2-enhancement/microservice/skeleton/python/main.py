"""${{ values.serviceName }} - FastAPI Microservice."""

import os
import time
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
from uuid import uuid4

app = FastAPI(
    title="${{ values.serviceName }}",
    version="1.0.0",
)

START_TIME = time.time()
items: dict[str, dict] = {}


class ItemCreate(BaseModel):
    name: str
    description: Optional[str] = None


class ItemUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None


@app.get("/health")
def health():
    return {"status": "healthy", "service": "${{ values.serviceName }}"}


@app.get("/ready")
def ready():
    return {"status": "ready", "uptime_seconds": round(time.time() - START_TIME, 2)}


@app.get("/metrics")
def metrics():
    return {
        "service": "${{ values.serviceName }}",
        "uptime_seconds": round(time.time() - START_TIME, 2),
        "items_count": len(items),
    }


@app.get("/api/items")
def list_items():
    return list(items.values())


@app.get("/api/items/{item_id}")
def get_item(item_id: str):
    if item_id not in items:
        raise HTTPException(status_code=404, detail="Item not found")
    return items[item_id]


@app.post("/api/items", status_code=201)
def create_item(item: ItemCreate):
    item_id = str(uuid4())
    record = {"id": item_id, **item.model_dump()}
    items[item_id] = record
    return record


@app.put("/api/items/{item_id}")
def update_item(item_id: str, item: ItemUpdate):
    if item_id not in items:
        raise HTTPException(status_code=404, detail="Item not found")
    existing = items[item_id]
    update_data = item.model_dump(exclude_unset=True)
    existing.update(update_data)
    return existing


@app.delete("/api/items/{item_id}", status_code=204)
def delete_item(item_id: str):
    if item_id not in items:
        raise HTTPException(status_code=404, detail="Item not found")
    del items[item_id]


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", "${{ values.httpPort }}"))
    uvicorn.run(app, host="0.0.0.0", port=port)
