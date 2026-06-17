import express from "express";
import rateLimit from "express-rate-limit";

const app = express();
const limiter = rateLimit({ windowMs: 60000, max: 100 });
app.use(limiter);
app.use(express.json());

app.get("/health", (_, res) => res.json({ status: "ok" }));
app.all("/api/*", (req, res) => {
  res.json({ message: "Gateway routing", path: req.path, method: req.method });
});

app.listen(3000, () => console.log("API Gateway on port 3000"));
