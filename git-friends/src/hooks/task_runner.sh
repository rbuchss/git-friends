#!/bin/bash

function git::hooks::task_runner() {
  if (( $# == 0 )); then
    >&2 echo "ERROR: ${FUNCNAME[0]}: invalid number of arguments"
    >&2 echo "Usage: ${FUNCNAME[0]} hook_name [tasks ...]"
    return 1
  fi

  local hook_name="$1" \
    config_section="git-friends.$1" \
    disabled \
    log_enabled \
    log_file=/dev/null \
    git_dir \
    tasks=("${@:2}")

  if disabled="$(git config --get "${config_section}.disabled")" \
    && [[ "${disabled}" == 'true' ]]; then
      # Disabled so exit
      return 0
  fi

  if log_enabled="$(git config --get "${config_section}.log")" \
    && [[ "${log_enabled}" == 'true' ]] \
    && git_dir="$(git rev-parse --git-dir)"; then
      log_file="${git_dir}/git-friends/logs/${hook_name}.log"

      if [[ ! -d "${log_file%/*}" ]] \
        && ! mkdir -p "${log_file%/*}"; then
          >&2 echo "ERROR: ${FUNCNAME[0]}: cannot make log directory: '${log_file%/*}'"
          return 1
      fi
  fi

  # TODO add skip and task configs?

  if (( "${#tasks[@]}" == 0 )); then
    git::hooks::task_runner::log 'INFO' "no tasks to run\n" >> "${log_file}"
    return
  fi

  git::hooks::task_runner::log 'INFO' \
    "running ${#tasks[@]} tasks: (${tasks[*]})" >> "${log_file}"

  for task in "${tasks[@]}"; do
    (
      if ! declare -F "${task}" > /dev/null 2>&1 \
        && ! command -v "${task}" > /dev/null 2>&1; then
          level='ERROR'
          response="command/function: '${task}' not found"
      elif response="$("${task}" 2>&1)"; then
        level='INFO'
      else
        level='ERROR'
      fi

      git::hooks::task_runner::log "${level}" \
        'task:' \
        "${task}\n${response}\n"
    ) >> "${log_file}" 2>&1 &
  done
}

function git::hooks::task_runner::log() {
  local level="$1" \
    message=("${@:2}")

  printf '%s, [%s #%d] %s -- %s: %b\n' \
    "${level:0:1}" \
    "$(date +%Y-%m-%dT%H:%M:%S%z)" \
    "$$" \
    "${level}" \
    "${FUNCNAME[2]}" \
    "${message[*]}"
}
