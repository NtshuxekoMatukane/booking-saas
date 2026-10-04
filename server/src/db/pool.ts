import { Pool } from "pg";

export const pool = new Pool({
  host: process.env.DATABASE_HOST,
  port: Number(process.env.DATABASE_PORT),
  database: process.env.DATABASE_NAME,
  user: process.env.DATABASE_USER,
  password: process.env.DATABASE_PASSWORD,
});

pool.on("error", (error) => {
  console.error("Unexpected PostgreSQL pool error:", error);
});