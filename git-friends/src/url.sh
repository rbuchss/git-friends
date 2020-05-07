#!/bin/bash

function git::url::parse() {
  local regexp='(git\@|https://|http://)([^/:]+)(:|/)([^/]+)/(.+$)'

  if [[ "$1" =~ $regexp ]] \
    && [[ -n "${BASH_REMATCH[$2]}" ]]; then
      echo "${BASH_REMATCH[$2]}"
      return
  fi

  return 1
}

function git::url::prefix() {
  git::url::parse "$1" 1
}

function git::url::domain() {
  git::url::parse "$1" 2
}

function git::url::separator() {
  git::url::parse "$1" 3
}

function git::url::user() {
  git::url::parse "$1" 4
}

function git::url::repo() {
  git::url::parse "$1" 5
}

function git::url::protocol() {
  local prefix
  prefix="$(git::url::prefix "$1")"

  case "${prefix}" in
    git@) echo 'ssh' ;;
    https://) echo 'https' ;;
    http://) echo 'http' ;;
    *)
      >&2 echo "ERROR: url: '${prefix}' is not valid"
      return 1
      ;;
  esac
}

function git::url::change_user() {
  local url="$1" \
    prefix \
    domain \
    separator \
    user="$2" \
    repo

  if [[ -z "${url}" ]] \
    || [[ -z "${user}" ]]; then
    >&2 echo 'ERROR: invalid arguments'
    >&2 echo "Usage: ${FUNCNAME[0]} url user"
    return 1
  fi

  if prefix="$(git::url::prefix "${url}")" \
    && domain="$(git::url::domain "${url}")" \
    && separator="$(git::url::separator "${url}")" \
    && repo="$(git::url::repo "${url}")"; then
      printf '%s%s%s%s/%s' \
        "${prefix}" \
        "${domain}" \
        "${separator}" \
        "${user}" \
        "${repo}"
      return
  fi

  return 1
}

function git::url::prefix_for_protocol() {
  case "$1" in
    ssh) echo 'git@' ;;
    https) echo 'https://' ;;
    http) echo 'http://' ;;
    *)
      >&2 echo "ERROR: protocol: '$1' is not valid"
      return 1
      ;;
  esac
}

function git::url::separator_for_protocol() {
  case "$1" in
    ssh) echo ':' ;;
    https) echo '/' ;;
    http) echo '/' ;;
    *)
      >&2 echo "ERROR: protocol: '$1' is not valid"
      return 1
      ;;
  esac
}

function git::url::change_protocol() {
  local url="$1" \
    protocol="$2" \
    prefix \
    domain \
    separator \
    user \
    repo

  if [[ -z "${url}" ]] \
    || [[ -z "${protocol}" ]]; then
    >&2 echo 'ERROR: invalid arguments'
    >&2 echo "Usage: ${FUNCNAME[0]} url protocol"
    return 1
  fi

  if prefix=$(git::url::prefix_for_protocol "${protocol}") \
    && domain="$(git::url::domain "${url}")" \
    && separator="$(git::url::separator_for_protocol "${protocol}")" \
    && user="$(git::url::user "${url}")" \
    && repo="$(git::url::repo "${url}")"; then
      printf '%s%s%s%s/%s' \
        "${prefix}" \
        "${domain}" \
        "${separator}" \
        "${user}" \
        "${repo}"
      return
  fi

  return 1
}
