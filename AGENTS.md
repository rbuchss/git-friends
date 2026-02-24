# Git Friends - AI Agent Project Instructions

See [README.md](README.md) for project structure, development commands, the module system, and the [Adding a New Module](README.md#adding-a-new-module) workflow.

## Quick Reference

- `make` - runs all checks (default target: `compose-guards`)
- `make compose-test TEST_PATH=test/foo.bats FILTER_TAGS=git::foo` - targeted tests
- All `compose-*` targets run in Docker. Tests, lint, and format **must** run via Docker (Alpine/BusyBox environment).

## git::exec Wrapper

All source files call `git::exec` instead of `git` or `command git`. This is the sole `command git` wrapper. It is stubbable in tests (unlike `command git`). Stub with:

```bash
git::exec() { ...; }; export -f git::exec
```

## Running Tests from AI Agents

The `compose-*` targets use `docker compose run` and work in non-interactive contexts like AI agent shells. Run them directly:

```bash
make compose-guards
make compose-test TEST_PATH=test/foo.bats FILTER_TAGS=git::foo
```

For interactive debugging, use `make compose-debug` which keeps the TTY for a live shell.

## Known Limitations

Tests run in a Docker Alpine/BusyBox environment. Some kcov coverage edge cases exist with BATS `setup`/`teardown` functions and dynamically sourced files.
