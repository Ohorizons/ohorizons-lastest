// ${{ values.jobName }} - Batch Job Entry Point
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
)

var checkpointPath = getEnv("CHECKPOINT_PATH", "/tmp/${{ values.jobName }}_checkpoint.json")

type CheckpointState struct {
	Offset int64  `json:"offset"`
	Status string `json:"status"`
}

func getEnv(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok {
		return v
	}
	return fallback
}

// ---------------------------------------------------------------------------
// Checkpoint helpers
// ---------------------------------------------------------------------------

func loadCheckpoint() CheckpointState {
	{% raw %}{%{% endraw %} if values.enableCheckpointing {% raw %}%}{% endraw %}
	data, err := os.ReadFile(checkpointPath)
	if err == nil {
		var state CheckpointState
		if json.Unmarshal(data, &state) == nil {
			log.Printf("Resumed from checkpoint: offset=%d", state.Offset)
			return state
		}
	}
	{% raw %}{%{% endraw %} endif {% raw %}%}{% endraw %}
	return CheckpointState{Offset: 0, Status: "new"}
}

func saveCheckpoint(state CheckpointState) {
	{% raw %}{%{% endraw %} if values.enableCheckpointing {% raw %}%}{% endraw %}
	data, _ := json.Marshal(state)
	if err := os.WriteFile(checkpointPath, data, 0644); err != nil {
		log.Printf("WARNING: failed to save checkpoint: %v", err)
		return
	}
	log.Printf("Checkpoint saved: offset=%d", state.Offset)
	{% raw %}{%{% endraw %} endif {% raw %}%}{% endraw %}
}

// ---------------------------------------------------------------------------
// Data source / target stubs
// ---------------------------------------------------------------------------

func connectSources() {
	{% raw %}{%{% endraw %} for src in values.dataSources {% raw %}%}{% endraw %}
	log.Println("Connecting to data source: {{ src }}")
	{% raw %}{%{% endraw %} endfor {% raw %}%}{% endraw %}
}

func connectTargets() {
	{% raw %}{%{% endraw %} for tgt in values.dataTargets {% raw %}%}{% endraw %}
	log.Println("Connecting to data target: {{ tgt }}")
	{% raw %}{%{% endraw %} endfor {% raw %}%}{% endraw %}
}

// ---------------------------------------------------------------------------
// Batch processing
// ---------------------------------------------------------------------------

func processBatch(offset int64, batchSize int) int64 {
	log.Printf("Processing batch at offset=%d size=%d", offset, batchSize)
	// TODO: implement batch processing logic
	return offset + int64(batchSize)
}

func run(ctx context.Context, batchSize int) error {
	state := loadCheckpoint()
	offset := state.Offset

	connectSources()
	connectTargets()

	var totalProcessed int64

	for {
		select {
		case <-ctx.Done():
			log.Println("Received shutdown signal, saving checkpoint...")
			saveCheckpoint(CheckpointState{Offset: offset, Status: "interrupted"})
			return fmt.Errorf("interrupted by signal")
		default:
		}

		newOffset := processBatch(offset, batchSize)
		if newOffset == offset {
			log.Println("No more records to process.")
			break
		}
		totalProcessed += newOffset - offset
		offset = newOffset
		saveCheckpoint(CheckpointState{Offset: offset, Status: "running"})
	}

	saveCheckpoint(CheckpointState{Offset: offset, Status: "completed"})
	log.Printf("Job complete. Total records processed: %d", totalProcessed)
	return nil
}

func main() {
	batchSize := flag.Int("batch-size", 1000, "Records per batch")
	flag.Parse()

	log.SetFlags(log.Ldate | log.Ltime | log.Lmsgprefix)
	log.SetPrefix("[${{ values.jobName }}] ")

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	if err := run(ctx, *batchSize); err != nil {
		log.Fatalf("Job failed: %v", err)
	}
	os.Exit(0)
}
