#!/usr/bin/env bash
set -euo pipefail

BASE="http://127.0.0.1:8080"
META="/tmp/imx500_stream_detections.json"

echo "Polling for 60 seconds..."
echo "sec ts frame_code stream_bytes meta_size meta_delta"

PREV_META=-1
for SEC in $(seq 1 60); do
  TS=$(date +%H:%M:%S)

  FRAME_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "$BASE/camera/frame" || echo "000")

  # /stream.mjpg is a long-lived response; timeout is expected during 1s sampling.
  # Keep the poll loop alive even when curl returns timeout.
  STREAM_BYTES=$( (curl -s --max-time 1 "$BASE/stream.mjpg" || true) | wc -c | tr -d ' ' )

  if [[ -f "$META" ]]; then
    META_SIZE=$(stat -c%s "$META" 2>/dev/null || echo 0)
  else
    META_SIZE=0
  fi

  if [[ "$PREV_META" -lt 0 ]]; then
    META_DELTA=0
  else
    META_DELTA=$((META_SIZE - PREV_META))
  fi
  PREV_META=$META_SIZE

  printf "%02d %s %s %s %s %s\n" "$SEC" "$TS" "$FRAME_CODE" "$STREAM_BYTES" "$META_SIZE" "$META_DELTA"
  sleep 1
done

echo "\nInterpretation hints:"
echo "- frame_code=503 means _current_frame likely stopped updating"
echo "- stream_bytes near 0 means MJPEG endpoint not receiving fresh bytes"
echo "- meta_size flat while frames move suggests metadata pipeline stall"
