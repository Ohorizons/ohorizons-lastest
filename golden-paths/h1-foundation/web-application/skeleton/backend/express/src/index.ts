import express from 'express';
import cors from 'cors';

const app = express();
const port = process.env.PORT || 8000;

app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'healthy' });
});

app.get('/api/items', (_req, res) => {
  res.json({ items: [] });
});

app.listen(port, () => {
  console.log(`${{ values.appName }} backend listening on port ${port}`);
});
