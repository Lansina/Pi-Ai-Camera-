#!/usr/bin/env bash
set -euo pipefail

CONFIG="$HOME/Desktop/Pi-Ai-Camera-/config/imx500_person_detection.json"
META="/tmp/imx500_test_meta.json"
OUT="/tmp/imx500_test_stream.mjpg"

echo "== rpicam-vid baseline =="
echo "CONFIG=$CONFIG"
echo "META=$META"
echo "OUT=$OUT"

if ! command -v rpicam-vid >/dev/null 2>&1; then
  echo "ERROR: rpicam-vid not found on PATH"
  exit 1
fi

if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: config missing: $CONFIG"
  exit 1
fi

rm -f "$META" "$OUT"

echo "Starting baseline capture for 30s..."
set +e
timeout 30s rpicam-vid \
  --post-process-file "$CONFIG" \
  --width 640 \
  --height 480 \
  --framerate 15 \
  --nopreview \
  --codec mjpeg \
  --metadata "$META" \
  --metadata-format json \
  -t 0 \
  -o "$OUT"
RC=$?
set -e

if [[ "$RC" -ne 0 && "$RC" -ne 124 ]]; then
  echo "rpicam-vid exited unexpectedly (rc=$RC)"
fi

echo "\n== Results =="
if [[ -f "$META" ]]; then
  META_SIZE=$(stat -c%s "$META" 2>/dev/null || echo 0)
  echo "META exists: yes"
  echo "META bytes: $META_SIZE"
  echo "META tail:"
  tail -n 5 "$META" || true
else
  echo "META exists: no"
fi

if [[ -f "$OUT" ]]; then
  OUT_SIZE=$(stat -c%s "$OUT" 2>/dev/null || echo 0)
  echo "OUT exists: yes"
  echo "OUT bytes: $OUT_SIZE"
else
  echo "OUT exists: no"
fi

echo "\nPaste back:"
echo "1) full script output"
echo "2) whether META bytes are > 0"
echo "3) whether OUT bytes are > 0"
