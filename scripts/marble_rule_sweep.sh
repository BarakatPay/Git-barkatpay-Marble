#!/usr/bin/env zsh
set -euo pipefail
: ${MARBLE_TOKEN:?MARBLE_TOKEN not set}
: ${SCENARIO_ID:?SCENARIO_ID not set}

call() {
  local name="$1" body="$2"
  local out
  out=$(curl -sS -X POST "http://localhost:8080/v1/decisions" \
      -H "Authorization: Bearer $MARBLE_TOKEN" -H "Content-Type: application/json" \
      -d '{"scenario_id":"'"$SCENARIO_ID"'","trigger_object":'"$body"'}')
  local outcome score
  outcome=$(jq -r '.data[0].outcome' <<<"$out")
  score=$(jq -r '.data[0].score'   <<<"$out")
  printf "%-24s  %-16s  %s\n" "$name" "$outcome" "$score"
}

printf "%-24s  %-16s  %s\n" "test" "outcome" "score"
printf "%-24s  %-16s  %s\n" "----" "-------" "-----"

# baseline
call "baseline_ok" '{"object_id":"sweep_ok","updated_at":"2025-09-18T12:00:00Z","amount":1500,
  "velocity_spike_detected":false,"geo_mismatch":false,"night_window":false,"device_mismatch":false,
  "ctr_required":false,"reversal_abuse_detected":false,"sanctions_hit":false,"refunds_spike":false,
  "shariah_violation_flag":false,"biometric_fail_3plus":false,"qr_misuse_3plus":false,"float_usage_spike_40pct":false}'

# single-factor hits
call "high_amount_≥100k" '{"object_id":"amt_hi","updated_at":"2025-09-18T12:10:00Z","amount":120000}'
call "amount_50k–100k"   '{"object_id":"amt_mid","updated_at":"2025-09-18T12:15:00Z","amount":75000}'
call "velocity_spike"    '{"object_id":"velo","updated_at":"2025-09-18T12:33:00Z","amount":1500,"velocity_spike_detected":true}'
call "geo_mismatch"      '{"object_id":"geo","updated_at":"2025-09-18T12:34:00Z","amount":1500,"geo_mismatch":true}'
call "night_window"      '{"object_id":"night","updated_at":"2025-09-18T12:35:00Z","amount":1500,"night_window":true}'
call "device_mismatch"   '{"object_id":"device","updated_at":"2025-09-18T12:30:00Z","amount":1500,"device_mismatch":true}'
call "ctr_required"      '{"object_id":"ctr","updated_at":"2025-09-18T12:21:00Z","amount":1500,"ctr_required":true}'
call "reversal_abuse"    '{"object_id":"rev","updated_at":"2025-09-18T12:25:00Z","amount":1500,"reversal_abuse_detected":true}'
call "sanctions_hit"     '{"object_id":"san","updated_at":"2025-09-18T12:36:00Z","amount":1500,"sanctions_hit":true}'
call "shariah_flag"      '{"object_id":"sha","updated_at":"2025-09-18T12:26:00Z","amount":1500,"shariah_violation_flag":true}'
call "biometric_3plus"   '{"object_id":"bio","updated_at":"2025-09-18T12:31:00Z","amount":1500,"biometric_fail_3plus":true}'
call "float_spike_>40%"  '{"object_id":"float","updated_at":"2025-09-18T12:32:00Z","amount":1500,"float_usage_spike_40pct":true}'
call "refunds_spike"     '{"object_id":"refunds","updated_at":"2025-09-18T12:22:00Z","amount":1500,"refunds_spike":true}'
call "qr_misuse_3plus"   '{"object_id":"qr","updated_at":"2025-09-18T12:20:00Z","amount":1500,"qr_misuse_3plus":true}'

# composite combo
call "composite_v+g+n"   '{"object_id":"comp","updated_at":"2025-09-18T23:40:00Z","amount":1500,
  "velocity_spike_detected":true,"geo_mismatch":true,"night_window":true}'
