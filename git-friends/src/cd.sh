#!/bin/bash

function git::cd::root_dir {
  local root_dir

  if ! root_dir="$(git rev-parse --show-toplevel)"; then
    return 1
  fi

  echo "cd to git root dir: ${root_dir}"

  cd "${root_dir}" || return 1
 }
