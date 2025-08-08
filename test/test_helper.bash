#!/bin/bash

# fixtures
function __test_dir__ {
  dirname "$(realpath -s "${BASH_SOURCE[0]}")"
}

# shellcheck disable=SC2120
function fixture_dir {
  local dir

  dir="$(__test_dir__)/fixtures"

  if [[ "$#" -eq 1 ]]; then
    dir+="/$1"
  fi

  if ! [ -d "${dir}" ]; then
    >&2 echo "ERROR: cannot find fixture dir: '${dir}'"
    return 1
  fi

  echo "${dir}"
}

function fixture {
  local file

  if [[ "$#" -ne 1 ]]; then
    >&2 echo "ERROR: must specify fixture file"
    return 1
  fi

  # shellcheck disable=SC2119
  file="$(fixture_dir)/$1"
  if ! [ -f "${file}" ]; then
    >&2 echo "ERROR: cannot find fixture file: '${file}'"
    return 1
  fi

  echo "${file}"
}
