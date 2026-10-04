import "dotenv/config";
import express from "express";
import cors from "cors";

const app = express();
const PORT = 5000;

app.use(cors());
app.use(express.json());

app.get("/api/health", (_req, res) => {
  res.json({
    status: "ok",
    message: "Booking SaaS API is running",
  });
});

app.listen(PORT, () => {
  console.log(`API running on http://localhost:${PORT}`);
});