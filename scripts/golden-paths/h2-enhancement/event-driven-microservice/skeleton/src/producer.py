import logging

logger = logging.getLogger(__name__)

def publish_event(topic: str, message: dict):
    logger.info(f"Publishing to {topic}: {message}")
