from fastapi import FastAPI
import logging

app = FastAPI(title="Microservice")
logger = logging.getLogger(__name__)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/")
def root():
    return {"message": "Hello from microservice"}
