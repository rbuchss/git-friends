#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/config.sh"
source "${BASH_SOURCE[0]%/*/*}/logger.sh"
source "${BASH_SOURCE[0]%/*/*}/utility.sh"

function git::hooks::task_runner() {
  local name \
    block='git::hooks::task_runner::background_block' \
    arguments=()

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        git::hooks::task_runner::usage
        return 0
        ;;
      -n | --name)
        shift
        name="$1"
        ;;
      -b | --block)
        shift
        block="$1"
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        git::hooks::task_runner::usage >&2
        return 1
        ;;
      *)
        arguments+=("$1")
        ;;
    esac
    shift
  done

  if [[ -z "${name}" ]]; then
    name="${arguments[0]}"
    unset 'arguments[0]'
  fi

  local tasks=("${arguments[@]}")

  git::hooks::task_runner::body \
    "${name}" \
    "${block}" \
    "${tasks[@]}"
}

function git::hooks::task_runner::usage() {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS] [<name>] <tasks>

  -n, --name    Name of relevant git config subsection: git-friends.<name>
                Used to determine:
                  - If all tasks are disabled (key: disabled, value: bool)
                  - Additional tasks to run (key: task, value: string, multiple)
                  - Tasks to skip (key: skip, value: string, multiple)
                  - If logging is enabled (key: log, value: bool)
                    Outputs to <git-dir>/git-friends/logs/<name>.log

                If flag is not used name will be the value of the first non-flag argument

  -b, --block   Function, command or script used to run and process each task.
                Block must take the following arguments:
                  <block> <task> [<logfile> [<tasks_to_skip>]]

                Default: git::hooks::task_runner::background_block

  -h, --help    Display this help message

  <tasks>       Functions, commands, and/or scripts to run
USAGE_TEXT
}

function git::hooks::task_runner::body() {
  local hook_name="$1" \
    config_section="git-friends.$1" \
    block="$2" \
    tasks=("${@:3}") \
    exit_status=0 \
    logfile=/dev/null \
    skip=()

  # Disabled so exit
  git::config::is_true "${config_section}.disabled" \
    && return

  while IFS= read -r task; do
    tasks+=("${task}")
  done < <(git::config::get_all "${config_section}.task")

  while IFS= read -r task; do
    skip+=("${task}")
  done < <(git::config::get_all "${config_section}.skip")

  if git::config::is_true "${config_section}.log" \
    && logfile="$(git::dir "git-friends/logs/${hook_name}.log")"; then
      if [[ ! -d "${logfile%/*}" ]] \
        && ! mkdir -p "${logfile%/*}"; then
          >&2 echo "ERROR: ${FUNCNAME[0]}: cannot make log directory: '${logfile%/*}'"
          return 1
      fi
  fi

  if git::utility::is_not_executable "${block}"; then
    git::logger::error \
      --caller-level 3 \
      "NO command or function name: '${block}' found" \
      >> "${logfile}"
    return 1
  fi

  if (( "${#tasks[@]}" == 0 )); then
    git::logger::info \
      --caller-level 3 \
      "no tasks to run\n" \
      >> "${logfile}"
    return
  fi

  git::logger::info \
    --caller-level 3 \
    "queue ${#tasks[*]} tasks: ${tasks[*]}" \
    >> "${logfile}"

  for task in "${tasks[@]}"; do
    if git::utility::is_not_executable "${task}"; then
      git::logger::error \
        --caller-level 3 \
        "NO command or function named: '${task}' found" \
        >> "${logfile}"
      exit_status=1
      continue
    fi

    "${block}" "${task}" "${logfile}" "${skip[@]}" || exit_status=$?
  done

  return "${exit_status}"
}

function git::hooks::task_runner::background_block() {
  local task="$1" \
    logfile="$2" \
    skip=("${@:3}") \
    level='ERROR'

  if git::utility::array_contains "${task}" "${skip[@]}"; then
    git::logger::warning \
      --caller-level 4 \
      "skipped ${task}" \
      >> "${logfile}"
    return
  fi

  (
    if response="$("${task}" 2>&1)"; then
      level='INFO'
    fi

    git::logger::log \
      --level "${level}" \
      --caller-level 4 \
      "task: ${task}\n${response}\n" \
  ) >> "${logfile}" 2>&1 &
}
