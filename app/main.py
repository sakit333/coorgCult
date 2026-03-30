from fastapi import FastAPI, Request, HTTPException
import time
from app.core.logger import logger
from app.api.routes import router
from fastapi.staticfiles import StaticFiles
from app.db.database import engine
from app.modules.auth.routes import router as api_router
from app.ui.routes import router as ui_router

# Telemetry & Observability Imports
from prometheus_fastapi_instrumentator import Instrumentator
import os

# Initialize FastAPI app
app = FastAPI()

app.mount("/static", StaticFiles(directory="app/static"), name="static")

try:
    # Prometheus Metrics Setup (Exposes /metrics endpoint natively)
    Instrumentator().instrument(app).expose(app)
except Exception as e:
    logger.warning(f"Prometheus setup deferred or missing module: {e}")


@app.on_event("startup")
async def startup_event():
    try:
        async with engine.begin() as connection:
            print("✅ PostgreSQL connected successfully")
            logger.info("PostgreSQL connection established successfully")
    except Exception as e:
        print("❌ PostgreSQL connection failed:", e)
        logger.error("Failed to connect to PostgreSQL")
    logger.info("Application started from startup event")

@app.middleware("http")
async def log_request(request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    logger.info(f"Request: {request.method} {request.url} completed in {process_time:.4f} seconds")
    return response

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Application is shutting down from shutdown event")

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.exception("Unhandled exception occurred")
    raise HTTPException(status_code=500, detail="Internal Server Error")

# Include API routes
app.include_router(router, prefix="/api/v1")
app.include_router(api_router, prefix="/api/v1")
app.include_router(ui_router)