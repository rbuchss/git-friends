#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/utility.sh"

function git::url::is_valid {
  local url="$1"

  if [[ "${url}" =~ ^file:// ]]; then
    # file:// needs prefix, domain, separator, and repo (no user/org concept)
    git::url::parse "${url}" 1:4 5 >/dev/null 2>&1
  else
    git::url::parse "${url}" 1: >/dev/null 2>&1
  fi
}

# Parses a URL and returns the specified capture groups.
# Each argument after the URL is a group index (1-5) or a Python-style
# range (start:stop, exclusive stop). Open-ended ranges are supported:
#   1:4  → groups 1, 2, 3
#   2:   → groups 2, 3, 4, 5
#   :3   → groups 1, 2
#   :    → groups 1, 2, 3, 4, 5
# Returns 1 if the URL doesn't match or any requested group is empty.
#
# Capture groups (normalized across all URL types):
#   1: prefix    (git@, https://, http://, file://, ssh://, git://)
#   2: domain    (github.com, localhost for file://)
#   3: separator (: or /)
#   4: user/path (user/org for remote, parent path for file://)
#   5: repo      (repository name including .git suffix)
#
# ssh:// and git:// URLs may include userinfo and port components
# which are parsed but not mapped to capture groups.
function git::url::parse {
  local \
    url="$1" \
    remote_regexp='^(git\@|https://|http://)([^/:]+)(:|/)([^/]+)/(.+)$' \
    ssh_regexp='^(ssh://[^@]+@|ssh://)([^/:]+)[^/]*(/)([^/]+)/(.+)$' \
    git_regexp='^(git://)([^/:]+)[^/]*(/)([^/]+)/(.+)$' \
    file_regexp='^(file://)([^/]*)(/)(.*/)?([^/]+)$'

  shift

  local -a indices=()

  if (($# > 0)); then
    local expanded line

    expanded="$(git::utility::expand_indices 1 5 "$@")" || return 1

    while IFS= read -r line; do
      indices+=("${line}")
    done <<<"${expanded}"
  fi

  local -a matches=()

  if [[ "${url}" =~ $remote_regexp ]] \
    || [[ "${url}" =~ $ssh_regexp ]] \
    || [[ "${url}" =~ $git_regexp ]]; then
    matches=("${BASH_REMATCH[@]}")
  elif [[ "${url}" =~ $file_regexp ]]; then
    matches=("${BASH_REMATCH[@]}")
    # RFC 8089: empty host implies localhost
    matches[2]="${matches[2]:-localhost}"
  else
    return 1
  fi

  local index
  for index in "${indices[@]}"; do
    if [[ -z "${matches[${index}]}" ]]; then
      return 1
    fi
    echo "${matches[${index}]}"
  done

  return 0
}

function git::url::prefix {
  git::url::parse "$1" 1
}

function git::url::domain {
  git::url::parse "$1" 2
}

function git::url::separator {
  git::url::parse "$1" 3
}

function git::url::user {
  git::url::parse "$1" 4
}

function git::url::repo {
  git::url::parse "$1" 5
}

function git::url::repo_name {
  local repo
  repo="$(git::url::repo "$1")" || return 1
  echo "${repo%.git}"
}

function git::url::protocol {
  local prefix
  prefix="$(git::url::prefix "$1")"

  case "${prefix}" in
    git@ | ssh://*) echo 'ssh' ;;
    https://) echo 'https' ;;
    http://) echo 'http' ;;
    file://) echo 'file' ;;
    git://) echo 'git' ;;
    *)
      git::logger::error "'${prefix}' is not valid"
      return 1
      ;;
  esac
}

function git::url::change_user {
  local \
    url="$1" \
    prefix \
    domain \
    separator \
    user="$2" \
    repo

  if [[ -z "${url}" ]] \
    || [[ -z "${user}" ]]; then
    git::logger::error 'invalid arguments'
    git::logger::error "Usage: ${FUNCNAME[0]} url user"
    return 1
  fi

  if [[ "${url}" =~ ^file:// ]]; then
    git::logger::error 'change_user is not supported for file:// URLs'
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

function git::url::prefix_for_protocol {
  case "$1" in
    ssh) echo 'git@' ;;
    https) echo 'https://' ;;
    http) echo 'http://' ;;
    file) echo 'file://' ;;
    git) echo 'git://' ;;
    *)
      git::logger::error "protocol '$1' is not valid"
      return 1
      ;;
  esac
}

function git::url::separator_for_protocol {
  case "$1" in
    ssh) echo ':' ;;
    https | http | file | git) echo '/' ;;
    *)
      git::logger::error "protocol '$1' is not valid"
      return 1
      ;;
  esac
}

function git::url::change_protocol {
  local \
    url="$1" \
    protocol="$2" \
    prefix \
    domain \
    separator \
    user \
    repo

  if [[ -z "${url}" ]] \
    || [[ -z "${protocol}" ]]; then
    git::logger::error 'invalid arguments'
    git::logger::error "Usage: ${FUNCNAME[0]} url protocol"
    return 1
  fi

  if [[ "${url}" =~ ^file:// ]]; then
    git::logger::error 'change_protocol is not supported for file:// URLs'
    return 1
  fi

  if [[ "${protocol}" == 'file' ]]; then
    git::logger::error 'cannot convert to file:// protocol'
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

function git::url::__export__ {
  export -f git::url::is_valid
  export -f git::url::parse
  export -f git::url::prefix
  export -f git::url::domain
  export -f git::url::separator
  export -f git::url::user
  export -f git::url::repo
  export -f git::url::repo_name
  export -f git::url::protocol
  export -f git::url::change_user
  export -f git::url::prefix_for_protocol
  export -f git::url::separator_for_protocol
  export -f git::url::change_protocol
}

function git::url::__recall__ {
  export -fn git::url::is_valid
  export -fn git::url::parse
  export -fn git::url::prefix
  export -fn git::url::domain
  export -fn git::url::separator
  export -fn git::url::user
  export -fn git::url::repo
  export -fn git::url::repo_name
  export -fn git::url::protocol
  export -fn git::url::change_user
  export -fn git::url::prefix_for_protocol
  export -fn git::url::separator_for_protocol
  export -fn git::url::change_protocol
}

git::url::__export__
