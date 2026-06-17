/**
 * ${{ values.jobName }} - Batch Job Entry Point
 */

import * as fs from "fs";
import * as path from "path";

const CHECKPOINT_PATH =
  process.env.CHECKPOINT_PATH ?? `/tmp/${{ values.jobName }}_checkpoint.json`;

interface CheckpointState {
  offset: number;
  status: "new" | "running" | "error" | "completed";
}

// ---------------------------------------------------------------------------
// Logging
// ---------------------------------------------------------------------------
function log(level: string, message: string): void {
  const ts = new Date().toISOString();
  console.log(`${ts} [${level}] ${{ values.jobName }} - ${message}`);
}

// ---------------------------------------------------------------------------
// Checkpoint helpers
// ---------------------------------------------------------------------------
function loadCheckpoint(): CheckpointState {
  {%- if values.enableCheckpointing %}
  if (fs.existsSync(CHECKPOINT_PATH)) {
    const raw = fs.readFileSync(CHECKPOINT_PATH, "utf-8");
    const state: CheckpointState = JSON.parse(raw);
    log("INFO", `Resumed from checkpoint: offset=${state.offset}`);
    return state;
  }
  {%- endif %}
  return { offset: 0, status: "new" };
}

function saveCheckpoint(state: CheckpointState): void {
  {%- if values.enableCheckpointing %}
  fs.writeFileSync(CHECKPOINT_PATH, JSON.stringify(state));
  log("INFO", `Checkpoint saved: offset=${state.offset}`);
  {%- endif %}
}

// ---------------------------------------------------------------------------
// Data source / target stubs
// ---------------------------------------------------------------------------
function connectSources(): void {
  {%- for src in values.dataSources %}
  log("INFO", "Connecting to data source: {{ src }}");
  {%- endfor %}
}

function connectTargets(): void {
  {%- for tgt in values.dataTargets %}
  log("INFO", "Connecting to data target: {{ tgt }}");
  {%- endfor %}
}

// ---------------------------------------------------------------------------
// Batch processing
// ---------------------------------------------------------------------------
function processBatch(offset: number, batchSize: number): number {
  log("INFO", `Processing batch at offset=${offset} size=${batchSize}`);
  // TODO: implement batch processing logic
  return offset + batchSize;
}

async function run(): Promise<void> {
  const batchSize = parseInt(process.env.BATCH_SIZE ?? "1000", 10);
  const state = loadCheckpoint();
  let { offset } = state;

  connectSources();
  connectTargets();

  let totalProcessed = 0;

  try {
    while (true) {
      const newOffset = processBatch(offset, batchSize);
      if (newOffset === offset) {
        log("INFO", "No more records to process.");
        break;
      }
      totalProcessed += newOffset - offset;
      offset = newOffset;
      saveCheckpoint({ offset, status: "running" });
    }
  } catch (err) {
    log("ERROR", `Fatal error during processing: ${err}`);
    saveCheckpoint({ offset, status: "error" });
    throw err;
  }

  saveCheckpoint({ offset, status: "completed" });
  log("INFO", `Job complete. Total records processed: ${totalProcessed}`);
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------
run()
  .then(() => process.exit(0))
  .catch((err) => {
    log("ERROR", `Unhandled error: ${err}`);
    process.exit(1);
  });
