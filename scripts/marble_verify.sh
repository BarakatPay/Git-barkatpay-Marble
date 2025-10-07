#!/usr/bin/env zsh
set -euo pipefail
: ${MARBLE_TOKEN:?MARBLE_TOKEN not set}
: ${SCENARIO_ID:?SCENARIO_ID not set}

call() {
  local body="$1"
  curl -sS -X POST "http://localhost:8080/v1/decisions" \
    -H "Authorization: Bearer $MARBLE_TOKEN" -H "Content-Type: application/json" \
    -d '{"scenario_id":"'"$SCENARIO_ID"'","trigger_object":'"$body"'}'
}

assert() {
  local name="$1" body="$2" exp_outcome="$3" exp_score="$4"
  local out outcome score
  out=$(call "$body")
  outcome=$(jq -r '.data[0].outcome' <<<"$out")
  score=$(jq -r '.data[0].score'   <<<"$out")
  if [[ "$outcome" == "$exp_outcome" && "$score" == "$exp_score" ]]; then
    printf "✅ %-22s  %-16s  %s\n" "$name" "$outcome" "$score"
  else
    printf "❌ %-22s  got: %-12s %-3s  expected: %-12s %-3s\n" \
      "$name" "$outcome" "$score" "$exp_outcome" "$exp_score"
    return 1
  fi
}

# ---------- assertions ----------
assert "baseline_ok" '{"object_id":"sweep_ok","updated_at":"2025-09-18T12:00:00Z","amount":1500,
  "velocity_spike_detected":false,"geo_mismatch":false,"night_window":false,"device_mismatch":false,
  "ctr_required":false,"reversal_abuse_detected":false,"sanctions_hit":false,"refunds_spike":false,
  "shariah_violation_flag":false,"biometric_fail_3plus":false,"qr_misuse_3plus":false,"float_usage_spike_40pct":false}' approve 0

assert "high_amount_≥100k" '{"object_id":"amt_hi","updated_at":"2025-09-18T12:10:00Z","amount":120000}' decline 80
assert "amount_50k–100k"   '{"object_id":"amt_mid","updated_at":"2025-09-18T12:15:00Z","amount":75000}' review 40
assert "velocity_spike"    '{"object_id":"velo","updated_at":"2025-09-18T12:33:00Z","amount":1500,"velocity_spike_detected":true}' review 40
assert "geo_mismatch"      '{"object_id":"geo","updated_at":"2025-09-18T12:34:00Z","amount":1500,"geo_mismatch":true}' approve 20
assert "night_window"      '{"object_id":"night","updated_at":"2025-09-18T12:35:00Z","amount":1500,"night_window":true}' approve 20
assert "device_mismatch"   '{"object_id":"device","updated_at":"2025-09-18T12:30:00Z","amount":1500,"device_mismatch":true}' approve 15
assert "ctr_required"      '{"object_id":"ctr","updated_at":"2025-09-18T12:21:00Z","amount":1500,"ctr_required":true}' block_and_review 50
assert "reversal_abuse"    '{"object_id":"rev","updated_at":"2025-09-18T12:25:00Z","amount":1500,"reversal_abuse_detected":true}' review 40
assert "sanctions_hit"     '{"object_id":"san","updated_at":"2025-09-18T12:36:00Z","amount":1500,"sanctions_hit":true}' decline 100
assert "shariah_flag"      '{"object_id":"sha","updated_at":"2025-09-18T12:26:00Z","amount":1500,"shariah_violation_flag":true}' decline 100
assert "biometric_3plus"   '{"object_id":"bio","updated_at":"2025-09-18T12:31:00Z","amount":1500,"biometric_fail_3plus":true}' approve 20
assert "float_spike_>40%"  '{"object_id":"float","updated_at":"2025-09-18T12:32:00Z","amount":1500,"float_usage_spike_40pct":true}' approve 18
assert "refunds_spike"     '{"object_id":"refunds","updated_at":"2025-09-18T12:22:00Z","amount":1500,"refunds_spike":true}' approve 20
assert "qr_misuse_3plus"   '{"object_id":"qr","updated_at":"2025-09-18T12:20:00Z","amount":1500,"qr_misuse_3plus":true}' approve 20
assert "composite_v+g+n"   '{"object_id":"comp","updated_at":"2025-09-18T23:40:00Z","amount":1500,
  "velocity_spike_detected":true,"geo_mismatch":true,"night_window":true}' decline 110

echo "----"
echo "All assertions passed."
