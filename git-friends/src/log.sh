#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/remote.sh"

function git::log::basic() {
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

  git log \
    --pretty=format:"${format}" \
    --decorate \
    "$@"
}

function git::log::pretty() {
  git::log::basic \
    --graph \
    "$@"
}

function git::log::from_default_branch() {
  if [[ "$*" =~ \.\. ]]; then
    git::log::basic \
      --reverse \
      "$@"
    return
  fi

  local default_branch \
    commit_range

  default_branch="$(git::remote::default_branch)"
  commit_range="HEAD...${default_branch}"

  git::log::basic \
    --reverse \
    "$@" \
    "${commit_range}"
}
