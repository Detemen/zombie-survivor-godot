#!/usr/bin/env python3
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from functools import partial
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WEB_ROOT = ROOT / "build" / "web"
HOST = "127.0.0.1"
PORT = 8060


class GodotWebHandler(SimpleHTTPRequestHandler):
    def end_headers(self) -> None:
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "cross-origin")
        super().end_headers()


def main() -> None:
    WEB_ROOT.mkdir(parents=True, exist_ok=True)
    index_path = WEB_ROOT / "index.html"
    if not index_path.is_file():
        raise SystemExit(
            "Missing build/web/index.html. Export the Web preset from Godot before running this server."
        )
    handler = partial(GodotWebHandler, directory=str(WEB_ROOT))
    server = ThreadingHTTPServer((HOST, PORT), handler)
    print(f"Serving Godot Web export at http://{HOST}:{PORT}")
    print(f"Root: {WEB_ROOT}")
    server.serve_forever()


if __name__ == "__main__":
    main()
