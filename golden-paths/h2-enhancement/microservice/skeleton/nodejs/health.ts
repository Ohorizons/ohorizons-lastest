import { Router } from "express";

const startTime = Date.now();

export const healthRouter = Router();

healthRouter.get("/health", (_req, res) => {
  res.json({ status: "healthy", service: "${{ values.serviceName }}" });
});

healthRouter.get("/ready", (_req, res) => {
  const uptimeSeconds = Math.round((Date.now() - startTime) / 1000);
  res.json({ status: "ready", uptime_seconds: uptimeSeconds });
});

healthRouter.get("/metrics", (_req, res) => {
  const uptimeSeconds = Math.round((Date.now() - startTime) / 1000);
  res.json({
    service: "${{ values.serviceName }}",
    uptime_seconds: uptimeSeconds,
  });
});
