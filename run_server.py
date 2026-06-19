#!/usr/bin/env python3
"""
Frontend development server.

Serves static files from frontend/ and proxies /api/, /health, /openapi.json
and /static-offline-docs/ requests to the backend API server (port 8000).
"""

import http.server
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

PORT = 5007
BACKEND = "http://localhost:8000"
FRONTEND_DIR = Path(__file__).parent / "frontend"

# Paths that should be proxied to the backend
PROXY_PREFIXES = ("/api/", "/health", "/openapi.json", "/static-offline-docs/")


class ProxyHandler(http.server.SimpleHTTPRequestHandler):
    """Serve static files, proxy API calls to the backend."""

    def do_GET(self):
        if self.path.startswith(PROXY_PREFIXES):
            self._proxy()
        else:
            super().do_GET()

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    # ---- helpers -------------------------------------------------------

    def _proxy(self):
        url = f"{BACKEND}{self.path}"
        try:
            resp = urllib.request.urlopen(url)
            self.send_response(resp.status)
            # Forward content type
            ct = resp.headers.get("Content-Type", "application/octet-stream")
            self.send_header("Content-Type", ct)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(resp.read())
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(e.read())
        except urllib.error.URLError:
            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"error":"Backend unreachable"}')

    def log_message(self, fmt, *args):
        # Prepend [PROXY] or [STATIC] for clarity
        prefix = "[PROXY]" if args[0].startswith(PROXY_PREFIXES) else "[STATIC]"
        super().log_message(f"{prefix} {fmt}", *args)


if __name__ == "__main__":
    os.chdir(str(FRONTEND_DIR))
    server = http.server.HTTPServer(("0.0.0.0", PORT), ProxyHandler)
    print(f"  Frontend : http://localhost:{PORT}")
    print(f"  Backend  : {BACKEND}")
    print(f"  Static   : {FRONTEND_DIR}")
    print("  Press Ctrl+C to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")
        server.server_close()