#!/usr/bin/env bash
# 启动本地 HTTP 服务，测试离线会议纪要
cd "$(dirname "$0")"
echo "访问 http://localhost:11900"
python3 -m http.server 11900
