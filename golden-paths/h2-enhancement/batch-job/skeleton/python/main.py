"""${{ values.jobName }} - Batch Job Entry Point."""

import argparse
import logging
import sys
import json
import os
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s - %(message)s",
)
logger = logging.getLogger("${{ values.jobName }}")

CHECKPOINT_FILE = os.getenv("CHECKPOINT_PATH", "/tmp/${{ values.jobName }}_checkpoint.json")


def load_checkpoint() -> dict:
    """Load the last checkpoint state, if any."""
    {% if values.enableCheckpointing %}
    path = Path(CHECKPOINT_FILE)
    if path.exists():
        with open(path) as f:
            state = json.load(f)
            logger.info("Resumed from checkpoint: offset=%s", state.get("offset"))
            return state
    {% endif %}
    return {"offset": 0, "status": "new"}


def save_checkpoint(state: dict) -> None:
    """Persist checkpoint state to disk."""
    {% if values.enableCheckpointing %}
    with open(CHECKPOINT_FILE, "w") as f:
        json.dump(state, f)
    logger.info("Checkpoint saved: offset=%s", state.get("offset"))
    {% endif %}


def connect_sources():
    """Initialise connections to data sources."""
    {% for src in values.dataSources %}
    logger.info("Connecting to data source: {{ src }}")
    {% endfor %}


def connect_targets():
    """Initialise connections to data targets."""
    {% for tgt in values.dataTargets %}
    logger.info("Connecting to data target: {{ tgt }}")
    {% endfor %}


def process_batch(offset: int, batch_size: int) -> int:
    """Process a single batch starting at *offset*. Returns new offset."""
    logger.info("Processing batch at offset=%d size=%d", offset, batch_size)
    # TODO: implement batch processing logic
    return offset + batch_size


def run(args: argparse.Namespace) -> None:
    """Main execution loop."""
    state = load_checkpoint()
    offset = state.get("offset", 0)

    connect_sources()
    connect_targets()

    total_processed = 0
    try:
        while True:
            new_offset = process_batch(offset, args.batch_size)
            if new_offset == offset:
                logger.info("No more records to process.")
                break
            total_processed += new_offset - offset
            offset = new_offset
            save_checkpoint({"offset": offset, "status": "running"})
    except Exception:
        logger.exception("Fatal error during processing")
        save_checkpoint({"offset": offset, "status": "error"})
        raise

    save_checkpoint({"offset": offset, "status": "completed"})
    logger.info("Job complete. Total records processed: %d", total_processed)


def main() -> int:
    parser = argparse.ArgumentParser(description="${{ values.jobName }} batch job")
    parser.add_argument("--batch-size", type=int, default=1000, help="Records per batch")
    args = parser.parse_args()

    try:
        run(args)
        return 0
    except Exception:
        return 1


if __name__ == "__main__":
    sys.exit(main())
