################################################################################
# Shared targets and config
################################################################################

THIS_DIR := $(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))
TEST_DIRS := test/

ifeq ($(OS),Windows_NT)
  SHELL := pwsh.exe
  THIS_DIR := $(subst /,\,$(THIS_DIR))
  PATH := $(PATH);$(THIS_DIR)\test\bin
else
  SHELL := /bin/bash
  PATH := $(PATH):$(THIS_DIR)/test/bin
endif

LINTED_SOURCE_FILES := \
  ':(top,attr:category=source language=bash)'

LINTED_TEST_FILES := \
  ':(top,attr:category=test language=bash)' \
  ':(top,attr:category=test language=bats)'

LINTED_FILES := $(LINTED_SOURCE_FILES) $(LINTED_TEST_FILES)

TEST_COMMAND_FLAGS := \
  --setup-suite-file ./test/test_suite.bash \
  --recursive

# NOTE: We cannot use --pretty in github-action runners since they cause the following error:
#   /github/workspace/vendor/test/bats/bats-core/bin/bats --setup-suite-file ./test/test_suite.bash --pretty --recursive test/
#   tput: No value for $TERM and no -T specified
#   /github/workspace/vendor/test/bats/bats-core/lib/bats-core/validator.bash: line 8: printf: write error: Broken pipe
# This is due to the runner terminal settings or lack thereof - re the $TERM -T part.
# So we only enable --pretty if the TERM env var is set.
ifneq ($(TERM),)
TEST_COMMAND_FLAGS += --pretty
endif

TEST_COMMAND := $(THIS_DIR)/vendor/test/bats/bats-core/bin/bats \
  $(TEST_COMMAND_FLAGS) \
  $(TEST_DIRS)

.DEFAULT_GOAL := guards
.PHONY: guards
guards: test lint

# NOTE: github-action runners use linux/amd64.
# So the builder image needs to also be build using this platform using buildx.
# NOTE: No scoop port of bats so need to wrap in bash call for windows
.PHONY: test
test:
ifeq ($(OS),Windows_NT)
	bash -c "$(TEST_COMMAND)"
else
	$(TEST_COMMAND)
endif

.PHONY: lint
lint:
	shellcheck $$(git ls-files -- $(LINTED_FILES))

.PHONY: linted-files
linted-files:
	git ls-files -- $(LINTED_FILES)

.PHONY: linted-source-files
linted-source-files:
	git ls-files -- $(LINTED_SOURCE_FILES)

.PHONY: linted-test-files
linted-test-files:
	git ls-files -- $(LINTED_TEST_FILES)
