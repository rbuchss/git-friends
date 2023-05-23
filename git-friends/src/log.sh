#!/bin/bash

function git::log::pretty() {
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
    --graph \
    --pretty=format:"${format}" \
    --decorate \
    "$@"
}
