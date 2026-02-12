.PHONY: all
all: test integration-test plugin-lint shellcheck

.PHONY: test
test:
	@docker compose run --rm test

.PHONY: integration-test
integration-test:
	@docker compose run --rm integration-test

.PHONY: e2e-test
e2e-test:
	@docker compose run --rm e2e-test

.PHONY: plugin-lint
plugin-lint:
	@docker compose run plugin-lint

.PHONY: shellcheck
shellcheck:
	@docker compose run --rm shellcheck
