.PHONY: smoke sweep verify

smoke:
	./scripts/marble_smoke.sh

sweep:
	./scripts/marble_rule_sweep.sh

verify:
	./scripts/marble_verify.sh

.PHONY: todo

todo:
	./scripts/alerts_todo.sh

.PHONY: demo-review

demo-review:
	./scripts/escalation_sink.sh '{"object_id":"demo_review_now","updated_at":"2025-09-18T12:33:30Z","amount":1500,"velocity_spike_detected":true}'
	$(MAKE) -s todo

.PHONY: ack-latest

ack-latest:
	@id=$$(jq -r -s 'reverse | map(select(.outcome=="review" or .outcome=="block_and_review")) | .[0].alert_id' logs/compliance_queue.ndjson); \
	[ -n "$$id" ] || { echo "No actionable alerts."; exit 0; }; \
	./scripts/alerts_ack.sh $$id approved "ok to proceed"; \
	echo "Latest actionable alert acked: $$id"; \
	[ -f logs/compliance_processed.ndjson ] && tail -n 1 logs/compliance_processed.ndjson | jq . || true
