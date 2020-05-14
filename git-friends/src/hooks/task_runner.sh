#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/config.sh"
source "${BASH_SOURCE[0]%/*/*}/utility.sh"

function git::hooks::task_runner() {
  if (( $# == 0 )); then
    >&2 echo "ERROR: ${FUNCNAME[0]}: invalid number of arguments"
    >&2 echo "Usage: ${FUNCNAME[0]} hook_name [tasks ...]"
    return 1
  fi

  local hook_name="$1" \
    config_section="git-friends.$1" \
    log_file=/dev/null \
    skip=() \
    tasks=("${@:2}")

  git::config::is_true "${config_section}.disabled" \
    && return 0 # Disabled so exit

  if git::config::exists "${config_section}.tasks"; then
    tasks=()
    while IFS= read -r task; do
      tasks+=("${task//[[:blank:]]/}")
    done < <(git::config::get_array "${config_section}.tasks")
  fi

  while IFS= read -r task; do
    skip+=("${task//[[:blank:]]/}")
  done < <(git::config::get_array "${config_section}.skip")

  if git::config::is_true "${config_section}.log" \
    && log_file="$(git::dir)/git-friends/logs/${hook_name}.log"; then
      if [[ ! -d "${log_file%/*}" ]] \
        && ! mkdir -p "${log_file%/*}"; then
          >&2 echo "ERROR: ${FUNCNAME[0]}: cannot make log directory: '${log_file%/*}'"
          return 1
      fi
  fi

  if (( "${#tasks[@]}" == 0 )); then
    git::hooks::task_runner::log 'INFO' "no tasks to run\n" >> "${log_file}"
    return
  fi

  git::hooks::task_runner::log 'INFO' \
    "queue ${#tasks[@]} tasks:" \
    "${tasks[@]}" >> "${log_file}"

  for task in "${tasks[@]}"; do
    if git::utility::array_contains "${task}" "${skip[@]}"; then
      git::hooks::task_runner::log 'WARNING' \
        "skipped ${task}" >> "${log_file}"
      continue
    fi

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
