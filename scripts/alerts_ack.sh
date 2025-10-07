#!/usr/bin/env bash
# Usage:
#   scripts/alerts_ack.sh <ALERT_ID> <decision> [note...]
# decision ∈ approved | declined | escalated
set -euo pipefail

file="logs/compliance_queue.ndjson"
proc="logs/compliance_processed.ndjson"
id="${1:?pass ALERT_ID}"; decision="${2:?approved|declined|escalated}"
note="${3:-}"

# pull the matching alert from the queue
obj=$(jq -s --arg id "$id" 'map(select(.alert_id==$id)) | .[0]' "$file")
[ "$obj" != "null" ] || { echo "No alert with id=$id"; exit 1; }

# guard: already processed?
if [ -f "$proc" ] && jq -e --arg id "$id" -s 'map(select(.alert_id==$id)) | length>0' "$proc" >/dev/null; then
  echo "⚠ already processed id=$id — skipping"
  exit 0
fi

# append a processed record
jq -c --arg decision "$decision" --arg note "$note" --arg now "$(date -u +%FT%TZ)" '
  . + {resolved_at:$now, resolution:$decision, reviewer_note:$note}
' <<<"$obj" >> "$proc"

echo "✔ recorded: id=$id decision=$decision"
