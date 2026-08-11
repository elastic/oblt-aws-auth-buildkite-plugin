# Contributing

## Development

Run these Makefile targets locally before opening a PR:

- `make test` - runs the BATS unit tests
- `make plugin-lint` - validates `plugin.yml` and the README usage examples
- `make shellcheck` - lints the hook scripts
- `make e2e-test` - runs the plugin against real AWS credentials (requires `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`)

`make all` runs everything above.

## CI

`.buildkite/pipeline.yml` runs `test`, `plugin-lint`, and `shellcheck` on every push.
