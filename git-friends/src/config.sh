#!/bin/bash

function git::config::group {
  local group="$1"
  git config --get-regexp "^${group}"
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

  git config "${flags[@]}" --get "${key}" > /dev/null
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

  value="$(git config "${flags[@]}" --type=bool --get "${key}")" \
    && [[ "${value}" == 'true' ]]
}

function git::config::is_false {
  local value \
    key="$1" \
    flags=("${@:2}")

  git::config::is_null "$@" \
    && return 2

  value="$(git config "${flags[@]}" --type=bool --get "${key}")" \
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

  git config "${flags[@]}" --get "${key}"
}

function git::config::get_all {
  local key="$1" \
    flags=("${@:2}")

  git config "${flags[@]}" --get-all "${key}"
}

function git::dir {
  if (( $# == 0 )); then
    git rev-parse --git-dir
    return
  fi

  git rev-parse --git-path "$@"
}
