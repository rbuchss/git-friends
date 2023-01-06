THIS_DIR := $(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))
QUIET ?= @

ifeq ($(OS),Windows_NT)
  SHELL := pwsh.exe
  THIS_DIR := $(subst /,\,$(THIS_DIR))
  PATH := $(PATH);$(THIS_DIR)\test\bin
else
  SHELL := /bin/bash
  PATH := $(PATH):$(THIS_DIR)/test/bin
endif

SHELLCHECK_IGNORE := \
  *.bats \
  *.conf \
  *.config \
  *.json \
  *.keep \
  *.md \
  *gitconfig \
  *gitignore \
  Makefile \
  home/* \
  windows-home/* \
  test/fixtures/*

SHELLCHECK_GIT_IGNORE := $(addsuffix ',$(addprefix ':!:,$(SHELLCHECK_IGNORE)))

.PHONY: guards
guards: guards-bash

.PHONY: test
test: test-bash

.PHONY: lint
lint: lint-bash

.PHONY: guards-bash
guards-bash: test-bash lint-bash

# NOTE: No scoop port of bats so need to wrap in bash call for windows
.PHONY: test-bash
test-bash:
ifeq ($(OS),Windows_NT)
	bash -c "bats --pretty --recursive test/"
else
	bats --pretty --recursive test/
endif

.PHONY: lint-bash
lint-bash:
	shellcheck $(shell git ls-files -- . $(SHELLCHECK_GIT_IGNORE))
