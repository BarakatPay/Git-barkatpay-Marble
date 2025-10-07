.PHONY: smoke sweep verify

smoke:
	./scripts/marble_smoke.sh

sweep:
	./scripts/marble_rule_sweep.sh

verify:
	./scripts/marble_verify.sh
