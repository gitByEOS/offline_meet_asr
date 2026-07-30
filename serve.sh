#!/usr/bin/env bash
# 启动本地 HTTP 服务，测试离线会议纪要
cd "$(dirname "$0")"
python3 - <<'PY'
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

class LocalHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

print('访问 http://localhost:11900')
ThreadingHTTPServer(('127.0.0.1', 11900), LocalHandler).serve_forever()
PY
