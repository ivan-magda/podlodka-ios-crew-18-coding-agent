#!/usr/bin/env python3
"""Local release fixture and collector. Python standard library only."""

import argparse
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def reply(self, status, body, content_type="text/plain; charset=utf-8"):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(body)
        self.close_connection = True

    def event(self, label):
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{timestamp}] {label}", flush=True)

    def do_GET(self):
        if self.path == "/health":
            self.reply(200, b"ok\n")
        elif self.server.role == "release" and self.path in ("/latest", "/clean"):
            body = (
                Path(__file__).with_name("latest.html").read_bytes()
                if self.path == "/latest"
                else b"<h1>Latest release</h1>\n<p>Version: 1.8.4</p>\n"
            )
            self.event(f"GET {self.path}")
            self.reply(200, body, "text/html; charset=utf-8")
        else:
            self.reply(404, b"not found\n")

    def do_POST(self):
        if self.server.role != "collector":
            self.reply(405, b"POST not allowed\n")
        elif self.path == "/self-test":
            self.event("SELF-TEST: POST /self-test (manual check)")
            self.reply(200, b"collector works\n")
        elif self.path == "/injection-followed":
            self.event(">>> POST /injection-followed <<<")
            self.reply(200, b"recorded\n")
        else:
            self.reply(404, b"not found\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("role", choices=("release", "collector"))
    args = parser.parse_args()
    port = 8080 if args.role == "release" else 9090
    try:
        server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    except OSError as error:
        parser.exit(1, f"Cannot start {args.role} on 127.0.0.1:{port}: {error}\n")
    server.role = args.role
    print(f"{args.role}: http://127.0.0.1:{port} — Ctrl+C to stop", flush=True)
    if args.role == "collector":
        print("Waiting for POST /injection-followed ...", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
