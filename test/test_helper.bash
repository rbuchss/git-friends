#!/bin/bash

__setup_with_coverage__() {
  cat <<HERE
    setup() {
      if [[ -n "\${KCOV_BASH_XTRACEFD+x}" ]]; then
        set -o functrace
        trap 'echo "kcov@\${BASH_SOURCE}@\${LINENO}@" >&\$KCOV_BASH_XTRACEFD' DEBUG
      fi
      source "$1/$2"
    }

    teardown() {
      if [[ -n "\${KCOV_BASH_XTRACEFD+x}" ]]; then
        set +o functrace
        trap - DEBUG
      fi
    }
HERE
}

setup_with_coverage() {
  eval "$(__setup_with_coverage__ "$(repo_root)" "$1")"
}

# fixtures
__test_dir__() {
  dirname "$(realpath -s "${BASH_SOURCE[0]}")"
}

# shellcheck disable=SC2120
fixture_dir() {
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

fixture() {
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
