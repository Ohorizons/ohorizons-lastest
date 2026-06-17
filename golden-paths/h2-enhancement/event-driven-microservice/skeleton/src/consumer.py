import asyncio
import logging

logger = logging.getLogger(__name__)

async def consume_events():
    logger.info("Starting event consumer...")
    while True:
        logger.info("Waiting for events...")
        await asyncio.sleep(5)

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(consume_events())
