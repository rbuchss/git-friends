#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/exec.sh"
source "${BASH_SOURCE[0]%/*}/remote.sh"

function git::log::basic {
  local format \
    format_options \
    date_regexp=' (--date[[:space:]=]|--relative-date)'

  format_options=(
    '%C(bold)%C(yellow)%h'
    '%C(nobold) %ad'
    '%C(auto)%d '
    '%s'
    '%C(bold)%C(cyan) [%an]'
  )

  [[ ! " $* " =~ $date_regexp ]] \
    && unset 'format_options[1]'

  printf -v format '%s' "${format_options[@]}"

  git::__exec__ log \
    --pretty=format:"${format}" \
    --decorate \
    "$@"
}

function git::log::pretty {
  git::log::basic \
    --graph \
    "$@"
}

function git::log::from_default_branch {
  if [[ "$*" =~ \.\. ]]; then
    git::log::pretty \
      "$@"
    return
  fi

  local default_branch \
    commit_range

  default_branch="$(git::remote::default_branch)"
  commit_range="HEAD...${default_branch}"

  git::log::pretty \
    "$@" \
    "${commit_range}"
}

function git::log::__export__ {
  export -f git::log::basic
  export -f git::log::pretty
  export -f git::log::from_default_branch
}

function git::log::__recall__ {
  export -fn git::log::basic
  export -fn git::log::pretty
  export -fn git::log::from_default_branch
}

git::log::__export__
