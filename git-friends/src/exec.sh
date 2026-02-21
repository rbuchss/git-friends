#!/bin/bash

# Core git command invoker.
# All internal functions use this instead of calling git directly,
# so the user-facing `git` alias (git::invoke) is never triggered
# internally, and tests can stub this function for isolation.
#
# The set +e/set -e guard ensures correct behavior in bash 3.2 where
# set -e (errexit) triggers inside functions called from conditionals
# (e.g., `if git::__exec__ show-ref --quiet ...; then`). Without this,
# a non-zero exit from `command git` aborts the function before the
# caller's `if` can handle the exit code.
function git::__exec__ {
  local rc errexit_was_set=0
  [[ $- == *e* ]] && errexit_was_set=1
  set +e
  command git "$@"
  rc=$?
  ((errexit_was_set)) && set -e
  return "${rc}"
}

function git::__exec__::__export__ {
  export -f git::__exec__
}

function git::__exec__::__recall__ {
  export -fn git::__exec__
}

git::__exec__::__export__
