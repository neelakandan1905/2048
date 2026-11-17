#!/usr/bin/env python3
"""Serve build/web to phones on the local network, with caching disabled.

Also accepts POST /__log from web/feedback.js (open the page with ?debug=1)
and prints each diagnostic line, so phone behaviour can be read on the Mac.

Usage: python3 tools/serve_web.py [port]
"""
import json
import sys
import time
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "build" / "web"


class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, max-age=0")
        super().end_headers()

    def do_POST(self):
        if self.path != "/__log":
            self.send_error(404)
            return
        length = min(int(self.headers.get("Content-Length", 0)), 16_384)
        raw = self.rfile.read(length)
        try:
            entry = json.loads(raw)
        except ValueError:
            entry = {"raw": raw.decode("utf-8", "replace")}
        stamp = time.strftime("%H:%M:%S")
        print(f"[phone {stamp} {self.client_address[0]}] {json.dumps(entry)}", flush=True)
        self.send_response(204)
        self.end_headers()

    def log_message(self, fmt, *args):
        if "/__log" not in (str(args[0]) if args else ""):
            sys.stderr.write("%s - %s\n" % (self.client_address[0], fmt % args))


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8090
    server = ThreadingHTTPServer(("0.0.0.0", port), partial(Handler, directory=str(ROOT)))
    print(f"Serving {ROOT} on port {port} (no-cache, phone logs enabled)", flush=True)
    server.serve_forever()
