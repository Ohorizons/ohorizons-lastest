import { Router, Request, Response } from "express";
import { randomUUID } from "crypto";

export const itemsRouter = Router();

interface Item {
  id: string;
  name: string;
  description?: string;
}

const items = new Map<string, Item>();

itemsRouter.get("/", (_req: Request, res: Response) => {
  res.json(Array.from(items.values()));
});

itemsRouter.get("/:id", (req: Request, res: Response) => {
  const item = items.get(req.params.id);
  if (!item) {
    res.status(404).json({ error: "Item not found" });
    return;
  }
  res.json(item);
});

itemsRouter.post("/", (req: Request, res: Response) => {
  const { name, description } = req.body;
  if (!name) {
    res.status(400).json({ error: "name is required" });
    return;
  }
  const item: Item = { id: randomUUID(), name, description };
  items.set(item.id, item);
  res.status(201).json(item);
});

itemsRouter.put("/:id", (req: Request, res: Response) => {
  const item = items.get(req.params.id);
  if (!item) {
    res.status(404).json({ error: "Item not found" });
    return;
  }
  if (req.body.name !== undefined) item.name = req.body.name;
  if (req.body.description !== undefined) item.description = req.body.description;
  res.json(item);
});

itemsRouter.delete("/:id", (req: Request, res: Response) => {
  if (!items.has(req.params.id)) {
    res.status(404).json({ error: "Item not found" });
    return;
  }
  items.delete(req.params.id);
  res.status(204).send();
});
