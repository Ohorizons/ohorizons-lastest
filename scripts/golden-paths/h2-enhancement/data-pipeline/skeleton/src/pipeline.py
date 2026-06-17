import logging

logger = logging.getLogger(__name__)

def extract(source: str):
    logger.info(f"Extracting data from {source}")
    return [{"id": 1, "value": "sample"}]

def transform(data: list):
    logger.info(f"Transforming {len(data)} records")
    return [{"id": r["id"], "value": r["value"].upper()} for r in data]

def load(data: list, target: str):
    logger.info(f"Loading {len(data)} records to {target}")

def run():
    data = extract("azure-blob")
    transformed = transform(data)
    load(transformed, "azure-sql")
    logger.info("Pipeline complete")

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    run()
