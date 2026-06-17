// ${{ values.jobName }} - Batch Job Entry Point
package com.ohorizons.batch;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.logging.ConsoleHandler;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.logging.SimpleFormatter;

public class Main {

    private static final Logger logger = Logger.getLogger("${{ values.jobName }}");
    private static final Path CHECKPOINT_PATH = Path.of(
            System.getenv().getOrDefault("CHECKPOINT_PATH",
                    System.getProperty("java.io.tmpdir") + "/${{ values.jobName }}_checkpoint.json"));

    // ------------------------------------------------------------------
    // Checkpoint helpers
    // ------------------------------------------------------------------

    record CheckpointState(long offset, String status) {}

    private static CheckpointState loadCheckpoint() {
        {% if values.enableCheckpointing %}
        try {
            if (Files.exists(CHECKPOINT_PATH)) {
                String json = Files.readString(CHECKPOINT_PATH);
                long offset = Long.parseLong(json.replaceAll(".*\"offset\":\\s*(\\d+).*", "$1"));
                logger.info("Resumed from checkpoint: offset=" + offset);
                return new CheckpointState(offset, "resumed");
            }
        } catch (IOException e) {
            logger.warning("Could not load checkpoint: " + e.getMessage());
        }
        {% endif %}
        return new CheckpointState(0, "new");
    }

    private static void saveCheckpoint(CheckpointState state) {
        {% if values.enableCheckpointing %}
        try {
            String json = String.format("{\"offset\":%d,\"status\":\"%s\"}", state.offset(), state.status());
            Files.writeString(CHECKPOINT_PATH, json);
            logger.info("Checkpoint saved: offset=" + state.offset());
        } catch (IOException e) {
            logger.warning("Could not save checkpoint: " + e.getMessage());
        }
        {% endif %}
    }

    // ------------------------------------------------------------------
    // Data source / target stubs
    // ------------------------------------------------------------------

    private static void connectSources() {
        {% for src in values.dataSources %}
        logger.info("Connecting to data source: {{ src }}");
        {% endfor %}
    }

    private static void connectTargets() {
        {% for tgt in values.dataTargets %}
        logger.info("Connecting to data target: {{ tgt }}");
        {% endfor %}
    }

    // ------------------------------------------------------------------
    // Batch processing
    // ------------------------------------------------------------------

    private static long processBatch(long offset, int batchSize) {
        logger.info(String.format("Processing batch at offset=%d size=%d", offset, batchSize));
        // TODO: implement batch processing logic
        return offset + batchSize;
    }

    private static void run(int batchSize) {
        CheckpointState state = loadCheckpoint();
        long offset = state.offset();
        long totalProcessed = 0;

        connectSources();
        connectTargets();

        try {
            while (true) {
                long newOffset = processBatch(offset, batchSize);
                if (newOffset == offset) {
                    logger.info("No more records to process.");
                    break;
                }
                totalProcessed += newOffset - offset;
                offset = newOffset;
                saveCheckpoint(new CheckpointState(offset, "running"));
            }
        } catch (Exception e) {
            saveCheckpoint(new CheckpointState(offset, "error"));
            throw e;
        }

        saveCheckpoint(new CheckpointState(offset, "completed"));
        logger.info("Job complete. Total records processed: " + totalProcessed);
    }

    // ------------------------------------------------------------------
    // Entry point
    // ------------------------------------------------------------------

    public static void main(String[] args) {
        ConsoleHandler handler = new ConsoleHandler();
        handler.setLevel(Level.ALL);
        handler.setFormatter(new SimpleFormatter());
        logger.addHandler(handler);
        logger.setLevel(Level.INFO);

        int batchSize = 1000;
        if (args.length > 0) {
            try {
                batchSize = Integer.parseInt(args[0]);
            } catch (NumberFormatException e) {
                logger.warning("Invalid batch size, using default: 1000");
            }
        }

        try {
            run(batchSize);
            System.exit(0);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Unhandled exception", e);
            System.exit(1);
        }
    }
}
