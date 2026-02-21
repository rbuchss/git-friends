#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/exec.sh"

function git::config::group {
  local \
    group="$1" \
    flags=("${@:2}")

  git::__exec__ config "${flags[@]}" --get-regexp "^${group}"
}

function git::config::aliases {
  local search="$1"

  git::config::group 'alias' \
    | sort \
    | awk -v search="${search}" 'BEGIN {
      print "ALIAS", "#", "COMMAND"
      print "-----", "#", "-------"
    }
    {
      gsub("alias\.", "", $1)
      first = $1
      $1 = ""
      gsub("^[[:space:]]+", "")
      if (first ~ search || $0 ~ search) {
        print first, "#", $0
      }
    }' \
    | column -t -s '#'
}

function git::config::exists {
  local key="$1" \
    flags=("${@:2}")

  git::__exec__ config "${flags[@]}" --get "${key}" >/dev/null
}

function git::config::is_null {
  ! git::config::exists "$@"
}

function git::config::is_true {
  local value \
    key="$1" \
    flags=("${@:2}")

  git::config::is_null "$@" \
    && return 2

  value="$(git::__exec__ config "${flags[@]}" --type=bool --get "${key}")" \
    && [[ "${value}" == 'true' ]]
}

function git::config::is_false {
  local value \
    key="$1" \
    flags=("${@:2}")

  git::config::is_null "$@" \
    && return 2

  value="$(git::__exec__ config "${flags[@]}" --type=bool --get "${key}")" \
    && [[ "${value}" == 'false' ]]
}

function git::config::is_truthy {
  git::config::exists "$@" \
    && ! git::config::is_false "$@"
}

function git::config::is_falsey {
  ! git::config::is_truthy "$@"
}

function git::config::get {
  local key="$1" \
    flags=("${@:2}")

  git::__exec__ config "${flags[@]}" --get "${key}"
}

function git::config::get_all {
  local key="$1" \
    flags=("${@:2}")

  git::__exec__ config "${flags[@]}" --get-all "${key}"
}

function git::dir {
  if (($# == 0)); then
    git::__exec__ rev-parse --git-dir
    return
  fi

  git::__exec__ rev-parse --git-path "$@"
}

function git::config::__export__ {
  export -f git::config::group
  export -f git::config::aliases
  export -f git::config::exists
  export -f git::config::is_null
  export -f git::config::is_true
  export -f git::config::is_false
  export -f git::config::is_truthy
  export -f git::config::is_falsey
  export -f git::config::get
  export -f git::config::get_all
  export -f git::dir
}

function git::config::__recall__ {
  export -fn git::config::group
  export -fn git::config::aliases
  export -fn git::config::exists
  export -fn git::config::is_null
  export -fn git::config::is_true
  export -fn git::config::is_false
  export -fn git::config::is_truthy
  export -fn git::config::is_falsey
  export -fn git::config::get
  export -fn git::config::get_all
  export -fn git::dir
}

git::config::__export__
