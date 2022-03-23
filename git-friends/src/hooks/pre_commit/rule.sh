#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/task_runner.sh"

function git::hooks::pre_commit::rule() {
  local name \
    fix \
    key \
    skip=0 \
    block= \
    arguments=()

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        git::hooks::pre_commit::rule::usage
        return 0
        ;;
      -N | --name)
        shift
        name="$1"
        ;;
      -f | --fix)
        shift
        fix="$1"
        ;;
      -k | --key)
        shift
        key="$1"
        ;;
      -b | --block)
        shift
        block="$1"
        ;;
      -n | --skip)
        skip=1
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        git::hooks::pre_commit::rule::usage >&2
        return 1
        ;;
      *)
        arguments+=("$1")
        ;;
    esac
    shift
  done

  # TODO is this required???
  if [[ -z "${name}" ]]; then
    name="${arguments[0]}"
    unset 'arguments[0]'
  fi

  local tasks=("${arguments[@]}")

  # TODO validate inputs / remove tasks
  git::hooks::pre_commit::rule::run \
    "${name}" \
    "${fix}" \
    "${key}" \
    "${skip}" \
    "${block}" \
    "${tasks[@]}"
}

# TODO fix this to match above
function git::hooks::pre_commit::rule::usage() {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS] [<name>] <tasks>

  -N, --name    Name of relevant git config subsection: git-friends.<name>
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

function git::hooks::pre_commit::rule::run() {
  local name="$1" \
    fix="$2" \
    key="$3" \
    skip="$4" \
    block="$5" \
    result \
    violations=()

  if (( skip == 1 )); then
    result='skipped'
  else
    result='failed'
    echo "TODO run: ${block}"
  fi

  git::hooks::pre_commit::rule::report \
    "${name}" \
    "${result}" \
    "${fix}" \
    "${violations[@]}"

  # TODO return status code
}

function git::hooks::pre_commit::rule::report() {
  local name="$1" \
    result="$2" \
    fix="$3" \
    violations="${@:4}" \
    summary_message \
    details_message \
    fix_message

  git::hooks::pre_commit::rule::report::summary \
    "${name}" \
    "${result}" \
    summary_message

  if [[ "${result}" == 'failed' ]]; then
    git::hooks::pre_commit::rule::report::details \
      details_message
    # git::hooks::pre_commit::rule::report::fix \
      # "${name}" \
      # "${fix}" \
      # details_message
  fi

  # case "$#" in
    # 4)
      # printf  -v "$4" "%s\n%s" \
        # "${summary}" \
        # "${details}"
      # ;;
    # *)
      # printf "%s\n%s" \
        # "${summary}" \
        # "${details}"
      # ;;
  # esac
  # return
  printf "%s\n%s%s" \
    "${summary_message}" \
    "${details_message}" \
    "${fix_message}"
}

function git::hooks::pre_commit::rule::report::summary() {
  local name="$1" \
    result="$2" \
    message_color \
    off_color \
    grade

  git::color::off_bare off_color

  case "${result}" in
    skipped)
      git::styles::warning_color message_color
      grade=' Skipped'
      ;;
    passed)
      git::styles::info_color message_color
      grade=' Passed'
      ;;
    *)
      git::styles::error_color message_color
      grade=' Failed'
      ;;
  esac

  case "$#" in
    3)
      printf -v "$3" '%s %s%s%s%s' \
        "${name}" \
        "${message_color}" \
        " ... " \
        "${grade}" \
        "${off_color}"
      ;;
    *)
      printf '%s %s%s%s%s' \
        "${name}" \
        "${message_color}" \
        " ... " \
        "${grade}" \
        "${off_color}"
      ;;
  esac
  return
}

function git::hooks::pre_commit::rule::report::details() {
  local error_color \
    violation_color \
    off_color \
    violations_word='violations' \
    violations=()

  git::color::off_bare off_color
  git::styles::error_color error_color
  git::styles::violation_color violation_color

  if [[ "${#violations[@]}" -eq 1 ]]; then 
    violations_word='violation'
  fi

  # case "$#" in
    # 3)
      # printf  -v "$3" "%s%s %s found:%s\n%s" \
        # "${error_color}" \
        # "${#violations[@]}" \
        # "${violations_word}" \
        # "${off_color}" \
        # "${violation_color}"
      # ;;
    # *)
      # printf '%s %s%s%s%s' \
        # "${name}" \
        # "${message_color}" \
        # " ... " \
        # "${grade}" \
        # "${off_color}"
      # ;;
  # esac
      printf "%s%s %s found:%s\n%s" \
        "${error_color}" \
        "${#violations[@]}" \
        "${violations_word}" \
        "${off_color}" \
        "${violation_color}"
  return
}

# function git::hooks::pre_commit::rule::result() {
  # local skip="$1" \
    # block="$2" \
    # status=0 \
    # violations=()

  # # if not skip
  # # run block

  # return "${status}"
# }

################################################################################
function git::color::code() {
  case "$#" in
    2) printf -v "$2" '\[\x1b[%s\]' "$1" ;;
    1) printf '\[\x1b[%s\]' "$1" ;;
    *) >&2 echo 'ERROR: invalid # of args' ;;
  esac
}

function git::color::code_bare() {
  case "$#" in
    2) printf -v "$2" '\x1b[%s' "$1" ;;
    1) printf '\x1b[%s' "$1" ;;
    *) >&2 echo 'ERROR: invalid # of args' ;;
  esac
}

function git::color::off() {
  git::color::code '0m' "$@"
}

# shellcheck disable=SC2120
function git::color::off_bare() {
  git::color::code_bare '0m' "$@"
}

################################################################################
function git::styles::coalesce() {
  local cmd="$1"
  local environment_value="$2"
  local environment_code="$3"
  local default="$4"

  if [[ -n "${environment_value}" ]]; then
    case "$#" in
      5) read -r "$5" <<< "${environment_value}" ;;
      *) echo "${environment_value}" ;;
    esac
    return
  fi

  local code="${environment_code:-$default}"

  case "$#" in
    5) "${cmd}" "${code}" "$5" ;;
    *) "${cmd}" "${code}" ;;
  esac
}

function git::styles::color_coalesce() {
  git::styles::coalesce 'git::color::code_bare' "$@"
}

function git::styles::error_color() {
  git::styles::color_coalesce \
    "${GIT_STYLES_ERROR_COLOR}" \
    "${GIT_STYLES_ERROR_COLOR_CODE}" \
    '0;91m' \
    "$@"
}

function git::styles::warning_color() {
  git::styles::color_coalesce \
    "${GIT_STYLES_WARNING_COLOR}" \
    "${GIT_STYLES_WARNING_COLOR_CODE}" \
    '0;93m' \
    "$@"
}

function git::styles::info_color() {
  git::styles::color_coalesce \
    "${GIT_STYLES_INFO_COLOR}" \
    "${GIT_STYLES_INFO_COLOR_CODE}" \
    '0;92m' \
    "$@"
}

function git::styles::violation_color() {
  git::styles::color_coalesce \
    "${GIT_STYLES_VIOLATION_COLOR}" \
    "${GIT_STYLES_VIOLATION_COLOR_CODE}" \
    '0;31m' \
    "$@"
}

