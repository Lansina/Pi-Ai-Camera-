#!/usr/bin/env bash
set -euo pipefail

PID=$(pgrep -f "rpicam-vid" | head -n1 || true)
echo "rpicam-vid PID=$PID"

if [[ -z "$PID" ]]; then
  echo "No running rpicam-vid process found."
  exit 0
fi

FD2="/proc/$PID/fd/2"
FDINFO="/proc/$PID/fdinfo/2"

if [[ -e "$FD2" ]]; then
  TARGET=$(readlink "$FD2" || true)
  echo "stderr fd target: $TARGET"
  if [[ "$TARGET" == pipe:* ]]; then
    echo "stderr is a pipe"
  else
    echo "stderr is not a pipe"
  fi
else
  echo "stderr fd path missing: $FD2"
fi

if [[ -r "$FDINFO" ]]; then
  echo "stderr fdinfo:"
  cat "$FDINFO"
fi

echo "If stderr is a pipe and never drained, it can eventually stall producer output."
