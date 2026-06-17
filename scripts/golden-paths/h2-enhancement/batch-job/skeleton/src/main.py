import logging
import time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def run_batch():
    logger.info("Starting batch job...")
    time.sleep(2)
    logger.info("Processing records...")
    logger.info("Batch job completed.")

if __name__ == "__main__":
    run_batch()
