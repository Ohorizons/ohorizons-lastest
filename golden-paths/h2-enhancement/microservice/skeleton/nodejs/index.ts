import express from "express";
import { healthRouter } from "./health";
import { itemsRouter } from "./routes";

const app = express();
const PORT = parseInt(process.env.PORT || "${{ values.httpPort }}", 10);

app.use(express.json());

app.use("/", healthRouter);
app.use("/api/items", itemsRouter);

app.listen(PORT, "0.0.0.0", () => {
  console.log(`${{ values.serviceName }} listening on port ${PORT}`);
});

export default app;
