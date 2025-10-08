# Marble Local Test Runbook

## Quick commands (repo root)
make smoke        # single healthy decision test
make sweep        # exercise each rule once
make verify       # assert outcomes/scores
make demo-review  # enqueue a sample 'review' alert
make todo         # list actionable (unprocessed) alerts
make ack-latest   # mark newest actionable alert as approved

## Notes
- Configure MARBLE_TOKEN and SCENARIO_ID in your shell (e.g. ~/.zshrc).
- Local alert files live under ./logs/ and are git-ignored.
