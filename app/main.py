from fastapi import FastAPI
import time
import math
import os

app = FastAPI()

@app.get("/")
def root():
    return {"message": "kind sre lab"}

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/api/error")
def error():
    return {"message": "intentional error"}, 500

@app.get("/api/slow")
def slow():
    time.sleep(5)
    return {"message": "slow response"}

@app.get("/api/cpu-load")
def cpu_load():
    end = time.time() + 10
    result = 0
    while time.time() < end:
        result += math.sqrt(12345)
    return {"message": "cpu load generated", "result": result}

@app.get("/api/env")
def env():
    value = os.getenv("APP_ENV")
    if value is None:
        raise RuntimeError("APP_ENV is missing")
    return {"APP_ENV": value}
