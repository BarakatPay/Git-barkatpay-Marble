#!/usr/bin/env zsh
set -euo pipefail

: ${MARBLE_TOKEN:?MARBLE_TOKEN not set}
: ${SCENARIO_ID:?SCENARIO_ID not set}

curl -sS -X POST "http://localhost:8080/v1/decisions" \
  -H "Authorization: Bearer $MARBLE_TOKEN" -H "Content-Type: application/json" \
  -d '{
    "scenario_id":"'"$SCENARIO_ID"'",
    "trigger_object":{
      "object_id":"smoke_ok",
      "updated_at":"2025-09-18T12:00:00Z",
      "amount":1500,
      "velocity_spike_detected":false,
      "geo_mismatch":false,
      "night_window":false,
      "device_mismatch":false,
      "ctr_required":false,
      "reversal_abuse_detected":false,
      "sanctions_hit":false,
      "refunds_spike":false,
      "shariah_violation_flag":false,
      "biometric_fail_3plus":false,
      "qr_misuse_3plus":false,
      "float_usage_spike_40pct":false
    }
  }' | sed 's/},{/},\n{/g'
