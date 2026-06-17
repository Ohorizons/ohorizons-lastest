"""API v1 router."""
from fastapi import APIRouter

router = APIRouter()


@router.get("/")
async def root():
    """Root endpoint."""
    return {"message": "Welcome to ${{values.name}} API v1"}


@router.get("/items")
async def list_items():
    """List all items."""
    return {"items": []}


@router.get("/items/{item_id}")
async def get_item(item_id: int):
    """Get a single item."""
    return {"item_id": item_id}
