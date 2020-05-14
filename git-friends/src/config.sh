#!/bin/bash

function git::config::group() {
  local group="$1"
  git config --get-regexp "^${group}"
}

function git::config::aliases() {
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

function git::config::exists() {
  local value key="$1"

  value="$(git config --get "${key}")" \
    && [[ -n "${value}" ]] \
    && return 0

  return 1
}

function git::config::is_null() {
  git::config::exists "$@" \
    && return 1

  return 0
}

function git::config::is_true() {
  local value key="$1"

  value="$(git config --get "${key}")" \
    && [[ "${value}" == 'true' ]] \
    && return 0

  return 1
}

function git::config::is_false() {
  git::config::is_true "$@" \
    && return 1

  return 0
}

function git::config::get_array() {
  local value key="$1"

  if ! value="$(git config --get "${key}")"; then
    return 1
  fi

  tr ',' '\n' <<< "${value}"
}

function git::dir() {
  git rev-parse --git-dir
}
