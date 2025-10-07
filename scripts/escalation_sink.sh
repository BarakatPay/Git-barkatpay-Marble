#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/escalation_sink.sh '{"object_id":"ctr_demo","amount":1500,"ctr_required":true}'
#
# Writes an alert line to logs/compliance_queue.ndjson if outcome ∈ {review, block_and_review, decline}

body="${1:?pass trigger_object JSON as first arg}"

resp=$(curl -sS -X POST "http://localhost:8080/v1/decisions" \
  -H "Authorization: Bearer $MARBLE_TOKEN" -H "Content-Type: application/json" \
  -d '{"scenario_id":"'"$SCENARIO_ID"'","trigger_object":'"$body"'}')

outcome=$(jq -r '.data[0].outcome' <<<"$resp")
score=$(jq -r '.data[0].score' <<<"$resp")
id=$(jq -r '.data[0].id' <<<"$resp")
ts=$(jq -r '.data[0].created_at' <<<"$resp")
rules=$(jq -c '.data[0].rules | map(select(.outcome=="hit") | {name,score_modifier})' <<<"$resp")

echo "decision: $outcome (score=$score)"

case "$outcome" in
  review|block_and_review|decline)
    jq -c -n --arg id "$id" \
          --arg ts "$ts" \
          --arg outcome "$outcome" \
          --argjson score "$score" \
          --argjson rules "$rules" \
          --argjson trig "$body" \
      '{alert_id:$id, created_at:$ts, outcome:$outcome, score:$score, triggered_rules:$rules, trigger_object:$trig}' \
      >> logs/compliance_queue.ndjson
    echo "→ wrote alert to logs/compliance_queue.ndjson"
    ;;
  *)
    echo "no escalation — nothing written"
    ;;
esac
