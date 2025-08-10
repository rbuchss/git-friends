#!/bin/bash

# Bash source guard - prevents sourcing this file multiple times
[[ -n "${GIT_FRIENDS_MODULE_LOGGER_LOADED}" ]] && return; export GIT_FRIENDS_MODULE_LOGGER_LOADED=1

readonly GIT_FRIENDS_LOG_SEVERITY_TRACE=0
readonly GIT_FRIENDS_LOG_SEVERITY_DEBUG=1
readonly GIT_FRIENDS_LOG_SEVERITY_INFO=2
readonly GIT_FRIENDS_LOG_SEVERITY_WARNING=3
readonly GIT_FRIENDS_LOG_SEVERITY_ERROR=4
readonly GIT_FRIENDS_LOG_SEVERITY_FATAL=5

readonly GIT_FRIENDS_LOG_INVALID_STATUS=255

function git::logger::trace {
  git::logger::log \
    -l trace \
    -c 1 \
    "$@"
}

function git::logger::debug {
  git::logger::log \
    -l debug \
    -c 1 \
    "$@"
}

function git::logger::info {
  git::logger::log \
    -l info \
    -c 1 \
    "$@"
}

function git::logger::warning {
  git::logger::log \
    -l warning \
    -c 1 \
    "$@"
}

function git::logger::error {
  git::logger::log \
    -l error \
    -c 1 \
    "$@"
}

function git::logger::fatal {
  git::logger::log \
    -l fatal \
    -c 1 \
    "$@"
}

function git::logger::log {
  git::logger::is_silenced && return

  local \
    event_level \
    caller_level=0 \
    output \
    event_severity \
    logger_severity \
    arguments=()

  git::logger::level_default event_level
  git::logger::output_default output

  while (( $# != 0 )); do
    case "$1" in
      -h | --help)
        >&2 git::logger::log::usage
        return "${GIT_FRIENDS_LOG_INVALID_STATUS}"
        ;;
      -l | --level)
        shift
        event_level="$1"
        ;;
      -c | --caller-level)
        shift
        caller_level="$1"
        ;;
      -o | --output)
        shift
        output="$1"
        ;;
      # Stop processing options and treat all remaining as arguments.
      # This is consistent with POSIX standards.
      --)
        shift
        arguments+=("$@")
        break
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        >&2 git::logger::log::usage
        return "${GIT_FRIENDS_LOG_INVALID_STATUS}"
        ;;
      *)
        arguments+=("$1")
        ;;
    esac
    shift
  done

  [[ "${output}" == '/dev/null' ]] && return

  git::logger::severity_from_level "${event_level}" event_severity
  git::logger::severity logger_severity

  if [[ -z "${event_severity}" ]]; then
    >&2 echo "ERROR: ${FUNCNAME[0]} event_severity is null and invalid"
    return "${GIT_FRIENDS_LOG_INVALID_STATUS}"
  fi

  if [[ -z "${logger_severity}" ]]; then
    >&2 echo "ERROR: ${FUNCNAME[0]} logger_severity is null and invalid"
    return "${GIT_FRIENDS_LOG_INVALID_STATUS}"
  fi

  (( event_severity < logger_severity )) && return

  local \
    datetime \
    progname \
    caller_info

  datetime="$(git::logger::datetime)"
  progname="${FUNCNAME[${caller_level}+1]}"

  case "${event_severity}" in
    "${GIT_FRIENDS_LOG_SEVERITY_TRACE}") event_level='TRACE' ;;
    "${GIT_FRIENDS_LOG_SEVERITY_DEBUG}") event_level='DEBUG' ;;
    "${GIT_FRIENDS_LOG_SEVERITY_INFO}") event_level='INFO' ;;
    "${GIT_FRIENDS_LOG_SEVERITY_WARNING}") event_level='WARNING' ;;
    "${GIT_FRIENDS_LOG_SEVERITY_ERROR}") event_level='ERROR' ;;
    *)
      event_level='FATAL'
      git::logger::stacktrace "${caller_level}" caller_info
      ;;
  esac

  for message in "${arguments[@]}"; do
    printf '%s, [%s #%d] %7s -- %s: %b\n%b' \
      "${event_level:0:1}" \
      "${datetime}" \
      "$$" \
      "${event_level}" \
      "${progname}" \
      "${message}" \
      "${caller_info}" \
      >> "${output}"
  done
}

function git::logger::log::usage {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]} [OPTIONS] # prints log message

  -c, --caller-level    Caller level
                        Default: 1

  -l, --level           Level
                        Default: $(git::logger::level_default)

  -o, --output          Output stream
                        Default: $(git::logger::output_default)

  -h, --help            Display this help message
USAGE_TEXT
}

function git::logger::datetime {
  local \
    found_command=0 \
    date_command \
    date_commands=(
      'date'
      '/bin/date'
    )

  for date_command in "${date_commands[@]}"; do
    if command -v "${date_command}" > /dev/null 2>&1; then
      found_command=1
      "${date_command}" '+%Y-%m-%dT%H:%M:%S%z'
      break
    fi
  done

  if (( found_command == 0 )); then
    echo ' NO-DATE-COMMAND-FOUND! '
  fi
}

function git::logger::severity {
  local \
    ___output_var___logger__severity="$1" \
    ___level___logger__severity

  git::logger::level ___level___logger__severity

  if [[ -n "${___output_var___logger__severity}" ]]; then
    git::logger::severity_from_level \
      "${___level___logger__severity}" \
      "${___output_var___logger__severity}"
  else
    git::logger::severity_from_level \
      "${___level___logger__severity}"
  fi
}

function git::logger::severity_from_level {
  local \
    ___level___logger__severity_from_level="$1" \
    ___output_var___logger__severity_from_level="$2" \
    ___severity___logger__severity_from_level

  case "${___level___logger__severity_from_level}" in
    [Tt][Rr][Aa][Cc][Ee])
      ___severity___logger__severity_from_level="${GIT_FRIENDS_LOG_SEVERITY_TRACE}"
      ;;
    [Dd][Ee][Bb][Uu][Gg])
      ___severity___logger__severity_from_level="${GIT_FRIENDS_LOG_SEVERITY_DEBUG}"
      ;;
    [Ii][Nn][Ff][Oo])
      ___severity___logger__severity_from_level="${GIT_FRIENDS_LOG_SEVERITY_INFO}"
      ;;
    [Ww][Aa][Rr][Nn][Ii][Nn][Gg])
      ___severity___logger__severity_from_level="${GIT_FRIENDS_LOG_SEVERITY_WARNING}"
      ;;
    [Ee][Rr][Rr][Oo][Rr])
      ___severity___logger__severity_from_level="${GIT_FRIENDS_LOG_SEVERITY_ERROR}"
      ;;
    *)
      ___severity___logger__severity_from_level="${GIT_FRIENDS_LOG_SEVERITY_FATAL}"
      ;;
  esac

  if [[ -n "${___output_var___logger__severity_from_level}" ]]; then
    printf \
      -v "${___output_var___logger__severity_from_level}" \
      '%s' \
      "${___severity___logger__severity_from_level}"
  else
    echo "${___severity___logger__severity_from_level}"
  fi
}

function git::logger::level {
  local \
    ___output_var___logger__level="$1" \
    ___ref___logger__level \
    ___default___logger__level

  git::logger::level::variable ___ref___logger__level
  git::logger::level_default ___default___logger__level

  if [[ -n "${___output_var___logger__level}" ]]; then
    printf \
      -v "${___output_var___logger__level}" \
      '%s' \
      "${!___ref___logger__level:-${___default___logger__level}}"
  else
    echo "${!___ref___logger__level:-${___default___logger__level}}"
  fi
}

function git::logger::level::variable {
  local \
    ___output_var___logger__level__variable="$1" \
    ___ref___logger__level__variable='GIT_FRIENDS_LOG_LEVEL_VARIABLE' \
    ___default___logger__level__variable='GIT_FRIENDS_LOG_LEVEL'

  if [[ -n "${___output_var___logger__level__variable}" ]]; then
    printf \
      -v "${___output_var___logger__level__variable}" \
      '%s' \
      "${!___ref___logger__level__variable:-${___default___logger__level__variable}}"
  else
    echo "${!___ref___logger__level__variable:-${___default___logger__level__variable}}"
  fi
}

function git::logger::level::set_variable {
  export GIT_FRIENDS_LOG_LEVEL_VARIABLE="$1"
}

function git::logger::level::unset_variable {
  unset GIT_FRIENDS_LOG_LEVEL_VARIABLE
}

function git::logger::level_default {
  local \
    ___output_var___logger__level_default="$1" \
    ___ref___logger__level_default \
    ___default___logger__level_default='info'

  git::logger::level_default::variable ___ref___logger__level_default

  if [[ -n "${___output_var___logger__level_default}" ]]; then
    printf \
      -v "${___output_var___logger__level_default}" \
      '%s' \
      "${!___ref___logger__level_default:-${___default___logger__level_default}}"
  else
    echo "${!___ref___logger__level_default:-${___default___logger__level_default}}"
  fi
}

function git::logger::level_default::variable {
  local \
    ___output_var___logger__level_default__variable="$1" \
    ___ref___logger__level_default__variable='GIT_FRIENDS_LOG_LEVEL_DEFAULT_VARIABLE' \
    ___default___logger__level_default__variable='GIT_FRIENDS_LOG_LEVEL_DEFAULT'

  if [[ -n "${___output_var___logger__level_default__variable}" ]]; then
    printf \
      -v "${___output_var___logger__level_default__variable}" \
      '%s' \
      "${!___ref___logger__level_default__variable:-${___default___logger__level_default__variable}}"
  else
    echo "${!___ref___logger__level_default__variable:-${___default___logger__level_default__variable}}"
  fi
}

function git::logger::level_default::set_variable {
  export GIT_FRIENDS_LOG_LEVEL_DEFAULT_VARIABLE="$1"
}

function git::logger::level_default::unset_variable {
  unset GIT_FRIENDS_LOG_LEVEL_DEFAULT_VARIABLE
}

function git::logger::output_default {
  local \
    ___output_var___logger__output_default="$1" \
    ___ref___logger__output_default \
    ___default___logger__output_default='/dev/stderr'

  git::logger::output_default::variable ___ref___logger__output_default

  if [[ -n "${___output_var___logger__output_default}" ]]; then
    printf \
      -v "${___output_var___logger__output_default}" \
      '%s' \
      "${!___ref___logger__output_default:-${___default___logger__output_default}}"
  else
    echo "${!___ref___logger__output_default:-${___default___logger__output_default}}"
  fi
}

function git::logger::output_default::variable {
  local \
    ___output_var___logger__output_default__variable="$1" \
    ___ref___logger__output_default__variable='GIT_FRIENDS_LOG_OUTPUT_DEFAULT_VARIABLE' \
    ___default___logger__output_default__variable='GIT_FRIENDS_LOG_OUTPUT_DEFAULT'

  if [[ -n "${___output_var___logger__output_default__variable}" ]]; then
    printf \
      -v "${___output_var___logger__output_default__variable}" \
      '%s' \
      "${!___ref___logger__output_default__variable:-${___default___logger__output_default__variable}}"
  else
    echo "${!___ref___logger__output_default__variable:-${___default___logger__output_default__variable}}"
  fi
}

function git::logger::output_default::set_variable {
  export GIT_FRIENDS_LOG_OUTPUT_DEFAULT_VARIABLE="$1"
}

function git::logger::output_default::unset_variable {
  unset GIT_FRIENDS_LOG_OUTPUT_DEFAULT_VARIABLE
}

function git::logger::is_silenced {
  local ___silence___logger__is_silenced

  git::logger::silence ___silence___logger__is_silenced

  case "${___silence___logger__is_silenced}" in
    0) ;;
    [Tt][Rr][Uu][Ee]|[Yy][Ee][Ss]|[1-9]|[1-9][0-9]*)
      ___silence___logger__is_silenced=1
      ;;
    *)
      ___silence___logger__is_silenced=0
      ;;
  esac

  (( ___silence___logger__is_silenced == 1 ))
}

function git::logger::silence {
  local \
    ___output_var___logger__silence="$1" \
    ___ref___logger__silence \
    ___default___logger__silence=0

  git::logger::silence::variable ___ref___logger__silence

  if [[ -n "${___output_var___logger__silence}" ]]; then
    printf \
      -v "${___output_var___logger__silence}" \
      '%s' \
      "${!___ref___logger__silence:-${___default___logger__silence}}"
  else
    echo "${!___ref___logger__silence:-${___default___logger__silence}}"
  fi
}

function git::logger::silence::variable {
  local \
    ___output_var___logger__silence__variable="$1" \
    ___ref___logger__silence__variable='GIT_FRIENDS_LOG_SILENCE_VARIABLE' \
    ___default___logger__silence__variable='GIT_FRIENDS_LOG_SILENCE'

  if [[ -n "${___output_var___logger__silence__variable}" ]]; then
    printf \
      -v "${___output_var___logger__silence__variable}" \
      '%s' \
      "${!___ref___logger__silence__variable:-${___default___logger__silence__variable}}"
  else
    echo "${!___ref___logger__silence__variable:-${___default___logger__silence__variable}}"
  fi
}

function git::logger::silence::set_variable {
  export GIT_FRIENDS_LOG_SILENCE_VARIABLE="$1"
}

function git::logger::silence::unset_variable {
  unset GIT_FRIENDS_LOG_SILENCE_VARIABLE
}

function git::logger::stacktrace {
  local \
    ___caller_level___logger__stacktrace="${1:-0}" \
    ___output_var___logger__stacktrace="$2" \
    ___caller_info___logger__stacktrace \
    ___message___logger__stacktrace \
    ___frame___logger__stacktrace \
    ___stack___logger__stacktrace=()

  # Add extra +1 to account for this function
  (( ___caller_level___logger__stacktrace++ ))

  while true; do
    if ! ___caller_info___logger__stacktrace="$(caller "${___caller_level___logger__stacktrace}")"; then
      break
    fi

    git::logger::caller_formatter \
      "${___caller_info___logger__stacktrace}" \
      ___frame___logger__stacktrace

    ___stack___logger__stacktrace+=("${___frame___logger__stacktrace}")

    (( ___caller_level___logger__stacktrace++ ))
  done

  if (( ${#___stack___logger__stacktrace[@]} > 0 )); then
    printf \
      -v ___message___logger__stacktrace \
      '%s\n' \
      "${___stack___logger__stacktrace[@]}"
    printf \
      -v ___message___logger__stacktrace \
      ' -> Traceback (most recent call last):\n%s' \
      "${___message___logger__stacktrace}"
  else
    printf \
      -v ___message___logger__stacktrace \
      ' -> No Traceback (stack info not available!)\n'
  fi

  if [[ -n "${___output_var___logger__stacktrace}" ]]; then
    printf \
      -v "${___output_var___logger__stacktrace}" \
      '%s' \
      "${___message___logger__stacktrace}"
  else
    echo "${___message___logger__stacktrace}"
  fi
}

function git::logger::caller_formatter {
  local \
    ___caller_info___logger__caller_formatter="$1" \
    ___output_var___logger__caller_formatter="$2" \
    ___line___logger__caller_formatter \
    ___func___logger__caller_formatter \
    ___file___logger__caller_formatter \
    ___message___logger__caller_formatter

  read -r \
    ___line___logger__caller_formatter \
    ___func___logger__caller_formatter \
    ___file___logger__caller_formatter \
    <<< "${___caller_info___logger__caller_formatter}"

  if [[ -z "${___func___logger__caller_formatter}" ]]; then
    ___func___logger__caller_formatter='(top level)'
  fi

  if [[ -z "${___file___logger__caller_formatter}" ]]; then
    ___file___logger__caller_formatter='(no file)'
  fi

  printf \
    -v ___message___logger__caller_formatter \
    '  %s\n    %s' \
    "${___func___logger__caller_formatter}" \
    "${___file___logger__caller_formatter}"

  # Note that the default, super old, version of bash that ships with macOS has
  # a bug where the caller/BASH_SOURCE[@] call stack gets corrupted and does
  # not report valid line numbers. So we check if the bash version is greater
  # than this version before including line numbers.
  #
  # BASH_VERSINFO[@] includes this version info - e.g. for macOS:
  #
  #   echo ${BASH_VERSINFO[@]}
  #   3 2 57 1 release arm64-apple-darwin24
  #
  # Here to keep things simple we just check if the version is greater than
  # 3 vs 3.2.57.
  #
  if (( ${BASH_VERSINFO[0]:-0} > 3 )) \
    && (( ${___line___logger__caller_formatter:-0} > 0 )); then
      printf \
        -v ___message___logger__caller_formatter \
        '%s:%s' \
        "${___message___logger__caller_formatter}" \
        "${___line___logger__caller_formatter}"
  fi

  if [[ -n "${___output_var___logger__caller_formatter}" ]]; then
    printf \
      -v "${___output_var___logger__caller_formatter}" \
      '%s' \
      "${___message___logger__caller_formatter}"
  else
    echo "${___message___logger__caller_formatter}"
  fi
}

function git::logger::__export__ {
  # We need to export the log functions for them to be accessible via xargs
  #
  # Helper script:
  # command rg --no-line-number 'function git::logger' git/src/logger.sh \
  #   | command rg -v 'git::logger::__' \
  #   | sed -E 's/function (.+)\(\) [{(]/export -f \1/' >> git/src/logger.sh
  #
  # NOTE: calling any exported function within git::__module__::load does not
  # play nice with tmux. Due to invalid function references across bash login shells.
  # To avoid this issue we need to either:
  #   - Not call any of these functions within tmux/git::__module__::load
  #   - Remove exports or unset these functions prior to calling tmux/git::__module__::load
  export -f git::logger::trace
  export -f git::logger::debug
  export -f git::logger::info
  export -f git::logger::warning
  export -f git::logger::error
  export -f git::logger::fatal
  export -f git::logger::log
  export -f git::logger::log::usage
  export -f git::logger::datetime
  export -f git::logger::severity
  export -f git::logger::severity_from_level
  export -f git::logger::level
  export -f git::logger::level::variable
  export -f git::logger::level::set_variable
  export -f git::logger::level::unset_variable
  export -f git::logger::level_default
  export -f git::logger::level_default::variable
  export -f git::logger::level_default::set_variable
  export -f git::logger::level_default::unset_variable
  export -f git::logger::output_default
  export -f git::logger::output_default::variable
  export -f git::logger::output_default::set_variable
  export -f git::logger::output_default::unset_variable
  export -f git::logger::is_silenced
  export -f git::logger::silence
  export -f git::logger::silence::variable
  export -f git::logger::silence::set_variable
  export -f git::logger::silence::unset_variable
  export -f git::logger::stacktrace
  export -f git::logger::caller_formatter

  # NOTE: we need to export the severity vars as well to avoid undefined vars in child shells.
  export GIT_FRIENDS_LOG_SEVERITY_TRACE
  export GIT_FRIENDS_LOG_SEVERITY_DEBUG
  export GIT_FRIENDS_LOG_SEVERITY_INFO
  export GIT_FRIENDS_LOG_SEVERITY_WARNING
  export GIT_FRIENDS_LOG_SEVERITY_ERROR
  export GIT_FRIENDS_LOG_SEVERITY_FATAL
  export GIT_FRIENDS_LOG_INVALID_STATUS
}

function git::logger::__recall__ {
  unset GIT_FRIENDS_MODULE_LOGGER_LOADED

  # We need to remove these exported functions otherwise tmux will not
  # properly load the .bash_profile if any of them are called during
  # the bash --login process.
  #
  # Calling any will cause a corruption of the bash call stack based
  # on bash 3.2.57. This appears to be due corrupted function references
  # from the parent inherited env.
  #
  # To use these within tmux we must first remove these exported function
  # references and then re-init them just like we would with a new
  # bash --login session.
  export -fn git::logger::trace
  export -fn git::logger::debug
  export -fn git::logger::info
  export -fn git::logger::warning
  export -fn git::logger::error
  export -fn git::logger::fatal
  export -fn git::logger::log
  export -fn git::logger::log::usage
  export -fn git::logger::datetime
  export -fn git::logger::severity
  export -fn git::logger::severity_from_level
  export -fn git::logger::level
  export -fn git::logger::level::variable
  export -fn git::logger::level::set_variable
  export -fn git::logger::level::unset_variable
  export -fn git::logger::level_default
  export -fn git::logger::level_default::variable
  export -fn git::logger::level_default::set_variable
  export -fn git::logger::level_default::unset_variable
  export -fn git::logger::output_default
  export -fn git::logger::output_default::variable
  export -fn git::logger::output_default::set_variable
  export -fn git::logger::output_default::unset_variable
  export -fn git::logger::is_silenced
  export -fn git::logger::silence
  export -fn git::logger::silence::variable
  export -fn git::logger::silence::set_variable
  export -fn git::logger::silence::unset_variable
  export -fn git::logger::stacktrace
  export -fn git::logger::caller_formatter

  export -n GIT_FRIENDS_LOG_SEVERITY_TRACE
  export -n GIT_FRIENDS_LOG_SEVERITY_DEBUG
  export -n GIT_FRIENDS_LOG_SEVERITY_INFO
  export -n GIT_FRIENDS_LOG_SEVERITY_WARNING
  export -n GIT_FRIENDS_LOG_SEVERITY_ERROR
  export -n GIT_FRIENDS_LOG_SEVERITY_FATAL
  export -n GIT_FRIENDS_LOG_INVALID_STATUS
}

git::logger::__export__
