#!/bin/bash

function git::logger::trace {
  git::logger::log -l trace "$@"
}

function git::logger::debug {
  git::logger::log -l debug "$@"
}

function git::logger::info {
  git::logger::log -l info "$@"
}

function git::logger::warning {
  git::logger::log -l warning "$@"
}

function git::logger::error {
  git::logger::log -l error "$@"
}

function git::logger::log {
  git::logger::is_silenced && return

  local level \
    caller_level=1 \
    output=/dev/stderr \
    severity \
    arguments=()

  level="$(git::logger::level_default)"

  while (( $# != 0 )); do
    case "$1" in
      -l | --level)
        shift
        level="$1"
        ;;
      -c | --caller-level)
        shift
        caller_level="$1"
        ;;
      -o | --output)
        shift
        output="$1"
        ;;
      -*)
        git::logger::log::usage >&2
        return 1
        ;;
      *)
        arguments+=("$1")
        ;;
    esac
    shift
  done

  [[ "${output}" == '/dev/null' ]] && return

  severity="$(git::logger::severity "${level}")"

  (( severity < $(git::logger::level) )) && return

  local datetime progname caller_info
  datetime="$(git::logger::datetime)"
  progname="${FUNCNAME[${caller_level}+1]}"

  case "${level}" in
    [Tt][Rr][Aa][Cc][Ee]) level='TRACE' ;;
    [Dd][Ee][Bb][Uu][Gg]) level='DEBUG' ;;
    [Ii][Nn][Ff][Oo]) level='INFO' ;;
    [Ww][Aa][Rr][Nn][Ii][Nn][Gg]) level='WARNING' ;;
    *)
      level='ERROR'
      caller_info=" -> from: $(git::logger::caller_formatter \
        "$(caller "${caller_level}")")\n"
      ;;
  esac

  for message in "${arguments[@]}"; do
    printf '%s, [%s #%d] %7s -- %s: %b\n%b' \
      "${level:0:1}" \
      "${datetime}" \
      "$$" \
      "${level}" \
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
                          Default: /dev/stderr
USAGE_TEXT
}

function git::logger::datetime {
  local found_command=0 \
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
  local severity
  case "$1" in
    [Tt][Rr][Aa][Cc][Ee]) severity=0 ;;
    [Dd][Ee][Bb][Uu][Gg]) severity=1 ;;
    [Ii][Nn][Ff][Oo]) severity=2 ;;
    [Ww][Aa][Rr][Nn][Ii][Nn][Gg]) severity=3 ;;
    *) severity=4 ;;
  esac

  echo "${severity}"
}

function git::logger::level {
  local variable default
  variable="$(git::logger::level::variable)"
  default="$(git::logger::level_default)"
  git::logger::severity "${!variable:-${default}}"
}

function git::logger::level_default {
  local variable
  variable="$(git::logger::level_default::variable)"
  echo "${!variable:-info}"
}

function git::logger::level::variable {
  echo "${GIT_FRIENDS_LOG_LEVEL_VARIABLE:-GIT_FRIENDS_LOG_LEVEL}"
}

function git::logger::level::set_variable {
  GIT_FRIENDS_LOG_LEVEL_VARIABLE="$1"
}

function git::logger::level::unset_variable {
  unset GIT_FRIENDS_LOG_LEVEL_VARIABLE
}

function git::logger::level_default::variable {
  echo "${GIT_FRIENDS_LOG_LEVEL_DEFAULT_VARIABLE:-GIT_FRIENDS_LOG_LEVEL_DEFAULT}"
}

function git::logger::level_default::set_variable {
  GIT_FRIENDS_LOG_LEVEL_DEFAULT_VARIABLE="$1"
}

function git::logger::level_default::unset_variable {
  unset GIT_FRIENDS_LOG_LEVEL_DEFAULT_VARIABLE
}

function git::logger::is_silenced {
  local silence
  silence="$(git::logger::silence)"
  (( silence == 1 ))
}

function git::logger::silence {
  local variable
  variable="$(git::logger::silence::variable)"
  echo "${!variable:-0}"
}

function git::logger::silence::variable {
  echo "${GIT_FRIENDS_LOG_SILENCE_VARIABLE:-GIT_FRIENDS_LOG_SILENCE}"
}

function git::logger::silence::set_variable {
  GIT_FRIENDS_LOG_SILENCE_VARIABLE="$1"
}

function git::logger::silence::unset_variable {
  unset GIT_FRIENDS_LOG_SILENCE_VARIABLE
}

function git::logger::caller_formatter {
  read -r -a array <<< "$@"
  for index in "${!array[@]}"; do
    case "${index}" in
      0) echo -n "line: ${array[${index}]}, " ;;
      1) echo -n "function: ${array[${index}]}, " ;;
      *)
        echo -n "file: ${array[*]:${index}}"
        break
        ;;
    esac
  done
  echo ''
}
