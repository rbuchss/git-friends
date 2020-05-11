#!/bin/bash

function git::hooks::pre_commit() {
  local exit_status=0

  if git diff --cached --quiet --exit-code; then
    # Nothing to commit so exit
    return "${exit_status}"
  fi

  local rules=(.git/hooks/pre-commit-test-*)

  # No rules exist so exit
  (( "${#rules[@]}" == 0 )) && return "${exit_status}"

  echo 'Running pre-commit tests:'

  # TODO enable config to disable rules/set props like project type, etc
  for rule in "${rules[@]}"; do
    "${rule}" || exit_status=$?
  done

  return "${exit_status}"
}
