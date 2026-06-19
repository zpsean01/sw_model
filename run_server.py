#!/usr/bin/env python3
"""
Run the full application (API + frontend) on a single port (5007).

The FastAPI app serves API endpoints under /api/v1/... and the frontend
static files from frontend/ as the default route.

Usage:
    python run_server.py
"""

import logging
from pathlib import Path

import uvicorn
from fastapi.staticfiles import StaticFiles

from api.main import app

PORT = 5007
FRONTEND_DIR = Path(__file__).parent / "frontend"

# Mount frontend static files — catch-all for non-API routes
app.mount("/", StaticFiles(directory=str(FRONTEND_DIR), html=True), name="frontend")

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    print(f"  Server  : http://localhost:{PORT}")
    print(f"  Static  : {FRONTEND_DIR}")
    print("  Press Ctrl+C to stop.")
    uvicorn.run("run_server:app", host="0.0.0.0", port=PORT)