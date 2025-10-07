#!/usr/bin/env bash
set -euo pipefail
queue="logs/compliance_queue.ndjson"
donef="logs/compliance_processed.ndjson"
[ -f "$queue" ] || { echo "No $queue yet"; exit 0; }

if [ -f "$donef" ]; then
  # Build a JSON object like {"id1":true,"id2":true,...} from processed NDJSON
  done_ids_json=$(jq -n 'reduce (inputs | select(type=="object") | .alert_id) as $id ({}; .[$id]=true)' "$donef")
else
  done_ids_json='{}'
fi

# Stream the queue, keep only actionable and NOT in processed set
jq -n --argjson DONE "$done_ids_json" '
  (inputs | select(type=="object"))
  | select((.outcome=="review" or .outcome=="block_and_review")
           and ($DONE[.alert_id] | not))
  | {
      at:.created_at,
      id:.alert_id,
      outcome,
      score,
      object:(.trigger_object.object_id),
      rules:(.triggered_rules|map(.name)|join(", "))
    }
' "$queue" \
| jq -s 'sort_by(.at) | reverse | .[:10] | .[]' \
| jq -r '"\(.at)  \(.outcome | ascii_upcase)  score=\(.score)  obj=\(.object)  id=\(.id)\n    rules: \(.rules)"'
