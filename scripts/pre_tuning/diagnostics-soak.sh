#!/usr/bin/env bash
set -euo pipefail

# One-command soak runner for app-level stream health checks.
# Usage:
#   bash scripts/pre_tuning/diagnostics-soak.sh [minutes] [base_url]
# Example:
#   bash scripts/pre_tuning/diagnostics-soak.sh 30 http://127.0.0.1:8080

MINUTES="${1:-10}"
BASE="${2:-http://127.0.0.1:8080}"
META="/tmp/imx500_stream_detections.json"

if ! [[ "$MINUTES" =~ ^[0-9]+$ ]] || [[ "$MINUTES" -lt 1 ]]; then
  echo "ERROR: minutes must be a positive integer"
  exit 2
fi

TOTAL_SECONDS=$((MINUTES * 60))
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/tmp/app-soak-${MINUTES}min-${STAMP}.log"

MAX_CONSEC_FLAT_STREAM=${MAX_CONSEC_FLAT_STREAM:-15}
MAX_CONSEC_FLAT_META=${MAX_CONSEC_FLAT_META:-15}

echo "Starting ${MINUTES}-minute soak test..."
echo "BASE=${BASE} META=${META}"
echo "Log: ${LOG_FILE}"
echo ""

echo "sec ts frame_code stream_bytes meta_size meta_delta" | tee -a "$LOG_FILE"

PREV_META=-1
PREV_STREAM=-1
FIRST_META=-1
LAST_META=-1

BAD_FRAME_COUNT=0
ZERO_STREAM_COUNT=0
CONSEC_FLAT_STREAM=0
CONSEC_FLAT_META=0
MAX_SEEN_FLAT_STREAM=0
MAX_SEEN_FLAT_META=0

for SEC in $(seq 1 "$TOTAL_SECONDS"); do
  TS=$(date +%H:%M:%S)

  FRAME_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "$BASE/camera/frame" || echo "000")

  # /stream.mjpg is long-lived; timeout during short sample is expected.
  STREAM_BYTES=$( (curl -s --max-time 1 "$BASE/stream.mjpg" || true) | wc -c | tr -d ' ' )

  if [[ -f "$META" ]]; then
    META_SIZE=$(stat -c%s "$META" 2>/dev/null || echo 0)
  else
    META_SIZE=0
  fi

  if [[ "$PREV_META" -lt 0 ]]; then
    META_DELTA=0
    FIRST_META=$META_SIZE
  else
    META_DELTA=$((META_SIZE - PREV_META))
  fi

  if [[ "$FRAME_CODE" != "200" ]]; then
    BAD_FRAME_COUNT=$((BAD_FRAME_COUNT + 1))
  fi

  if [[ "$STREAM_BYTES" -eq 0 ]]; then
    ZERO_STREAM_COUNT=$((ZERO_STREAM_COUNT + 1))
  fi

  if [[ "$PREV_STREAM" -ge 0 ]] && [[ "$STREAM_BYTES" -eq "$PREV_STREAM" ]]; then
    CONSEC_FLAT_STREAM=$((CONSEC_FLAT_STREAM + 1))
  else
    CONSEC_FLAT_STREAM=0
  fi

  if [[ "$META_DELTA" -eq 0 ]]; then
    CONSEC_FLAT_META=$((CONSEC_FLAT_META + 1))
  else
    CONSEC_FLAT_META=0
  fi

  if [[ "$CONSEC_FLAT_STREAM" -gt "$MAX_SEEN_FLAT_STREAM" ]]; then
    MAX_SEEN_FLAT_STREAM=$CONSEC_FLAT_STREAM
  fi
  if [[ "$CONSEC_FLAT_META" -gt "$MAX_SEEN_FLAT_META" ]]; then
    MAX_SEEN_FLAT_META=$CONSEC_FLAT_META
  fi

  PREV_STREAM=$STREAM_BYTES
  PREV_META=$META_SIZE
  LAST_META=$META_SIZE

  printf "%04d %s %s %s %s %s\n" "$SEC" "$TS" "$FRAME_CODE" "$STREAM_BYTES" "$META_SIZE" "$META_DELTA" | tee -a "$LOG_FILE"

  sleep 1
done

META_GROWTH=$((LAST_META - FIRST_META))

echo "" | tee -a "$LOG_FILE"
echo "Summary:" | tee -a "$LOG_FILE"
echo "- bad_frame_count=${BAD_FRAME_COUNT}" | tee -a "$LOG_FILE"
echo "- zero_stream_count=${ZERO_STREAM_COUNT}" | tee -a "$LOG_FILE"
echo "- max_consecutive_flat_stream=${MAX_SEEN_FLAT_STREAM}" | tee -a "$LOG_FILE"
echo "- max_consecutive_flat_meta=${MAX_SEEN_FLAT_META}" | tee -a "$LOG_FILE"
echo "- meta_growth_bytes=${META_GROWTH}" | tee -a "$LOG_FILE"

PASS=true
if [[ "$BAD_FRAME_COUNT" -gt 0 ]]; then PASS=false; fi
if [[ "$MAX_SEEN_FLAT_STREAM" -ge "$MAX_CONSEC_FLAT_STREAM" ]]; then PASS=false; fi
if [[ "$MAX_SEEN_FLAT_META" -ge "$MAX_CONSEC_FLAT_META" ]]; then PASS=false; fi
if [[ "$META_GROWTH" -le 0 ]]; then PASS=false; fi

if [[ "$PASS" == "true" ]]; then
  echo "PASS: Soak test met stream/metadata continuity gates." | tee -a "$LOG_FILE"
  echo "Log saved to ${LOG_FILE}"
  exit 0
else
  echo "FAIL: Soak test detected continuity issues." | tee -a "$LOG_FILE"
  echo "Thresholds: MAX_CONSEC_FLAT_STREAM=${MAX_CONSEC_FLAT_STREAM} MAX_CONSEC_FLAT_META=${MAX_CONSEC_FLAT_META}" | tee -a "$LOG_FILE"
  echo "Log saved to ${LOG_FILE}"
  exit 1
fi
