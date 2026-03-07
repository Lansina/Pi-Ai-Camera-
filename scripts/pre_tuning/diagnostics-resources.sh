#!/usr/bin/env bash
set -euo pipefail

echo "Top python/uvicorn and rpicam-vid processes:"
ps -eo pid,cmd,%cpu,%mem,rss --sort=-rss | egrep "uvicorn|python|rpicam-vid" | head -n 20 || true
