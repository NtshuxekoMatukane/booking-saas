import "dotenv/config";
import { readdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { pool } from "./pool.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const migrationsDirectory = path.join(__dirname, "migrations");

async function migrate() {
  const client = await pool.connect();

  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        id SERIAL PRIMARY KEY,
        filename TEXT NOT NULL UNIQUE,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    const files = (await readdir(migrationsDirectory))
      .filter((file) => file.endsWith(".sql"))
      .sort();

    const appliedResult = await client.query<{ filename: string }>(
      "SELECT filename FROM schema_migrations ORDER BY filename"
    );

    const appliedMigrations = new Set(
      appliedResult.rows.map((row) => row.filename)
    );

    for (const filename of files) {
      if (appliedMigrations.has(filename)) {
        console.log(`Skipping ${filename} — already applied.`);
        continue;
      }

      const filePath = path.join(migrationsDirectory, filename);
      const sql = await import("node:fs/promises").then((fs) =>
        fs.readFile(filePath, "utf8")
      );

      console.log(`Applying ${filename}...`);

      await client.query("BEGIN");

      try {
        await client.query(sql);
        await client.query(
          "INSERT INTO schema_migrations (filename) VALUES ($1)",
          [filename]
        );

        await client.query("COMMIT");

        console.log(`Applied ${filename}.`);
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      }
    }

    console.log("Migrations complete.");
  } catch (error) {
    console.error("Migration failed:", error);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

migrate();