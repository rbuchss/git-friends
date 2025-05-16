#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/task_runner.sh"

function git::hooks::pre_commit() {
  # Nothing to commit or disabled so exit
  git diff --cached --quiet --exit-code \
    && return

  local rules
  rules=("$(git::dir)"/hooks/pre-commit-test-*)

  if (( ${#rules[@]} > 0 )); then
    echo 'No pre-commit rules found. Skipping tests.'
    return 0
  fi

  echo 'Running pre-commit tests:'

  git::hooks::task_runner \
    --name 'pre-commit' \
    --block 'git::hooks::pre_commit::block' \
    "${rules[@]}"
}

function git::hooks::pre_commit::block() {
  local rule="$1" \
    logfile="$2" \
    skip=("${@:3}") \
    regexp='^.*pre-commit-test-([^\.]+).*$' \
    flags=()

  if [[ "${rule}" =~ $regexp ]]; then
    git::utility::array_contains "${BASH_REMATCH[1]}" "${skip[@]}" \
      && flags+=('-n')
  fi

  git::logger::info \
    --caller-level 4 \
    "run: ${rule} ${flags[*]}\n" \
    >> "${logfile}"

  "${rule}" "${flags[@]}"
}
