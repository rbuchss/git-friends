#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"

git::__module__::load || return 0

# Core git command invoker.
# All internal functions use this instead of calling git directly,
# so the user-facing `git` alias (git::invoke) is never triggered
# internally, and tests can stub this function for isolation.
#
# The set +e/set -e guard ensures correct behavior in bash 3.2 where
# set -e (errexit) triggers inside functions called from conditionals
# (e.g., `if git::exec show-ref --quiet ...; then`). Without this,
# a non-zero exit from `command git` aborts the function before the
# caller's `if` can handle the exit code.
function git::exec {
  local rc errexit_was_set=0
  [[ $- == *e* ]] && errexit_was_set=1
  set +e
  command git "$@"
  rc=$?
  ((errexit_was_set)) && set -e
  return "${rc}"
}

function git::exec::__export__ {
  export -f git::exec
}

function git::exec::__recall__ {
  export -fn git::exec
}

git::__module__::export
