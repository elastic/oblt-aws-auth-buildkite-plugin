.PHONY: all
all: test plugin-lint shellcheck

.PHONY: test
test:
	@docker compose run --rm test

.PHONY: plugin-lint
plugin-lint:
	@docker compose run plugin-lint

.PHONY: shellcheck
shellcheck:
	@docker compose run --rm shellcheck
