.PHONY: all
all: test plugin-lint integration-test

.PHONY: test
test:
	@docker compose run --rm test

.PHONY: plugin-lint
plugin-lint:
	@docker compose run plugin-lint
