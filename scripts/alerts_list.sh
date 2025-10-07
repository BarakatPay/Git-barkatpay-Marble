#!/usr/bin/env bash
set -euo pipefail

file="logs/compliance_queue.ndjson"
[ -f "$file" ] || { echo "No $file yet"; exit 0; }

echo "== Counts by outcome =="
jq -r '.outcome' "$file" | sort | uniq -c | awk '{printf "  %-18s %d\n", $2, $1}'

echo
echo "== Latest 5 alerts =="
jq -s '.[-5:] // [] | .[] | {at:.created_at, outcome, score, obj:(.trigger_object.object_id), rules:(.triggered_rules|map(.name)|join(", "))}' "$file" \
| jq -r '"  \(.at)  [\(.outcome), score=\(.score)]  obj=\(.obj)  rules=\(.rules)"'
