#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/utility.sh"

function git::hooks::submodule::remove() {
  local submodule_path

  for submodule_path in "$@"; do
    if [[ ! -d "${submodule_path}" ]]; then
      >&2 echo "ERROR: path to submodule: '${submodule_path}' not found"
      return 1
    fi

    if git::utility::ask "remove submodule? ${submodule_path}"; then
      # 1: Remove the submodule entry from .git/config
      # 2: Remove the submodule directory from the superproject's .git/modules directory
      # 3: Remove the entry in .gitmodules and remove the submodule directory located at ${submodule_path}
      git submodule deinit -f -- "${submodule_path}" \
        && rm -rf ".git/modules/${submodule_path}" \
        && git rm -f "${submodule_path}"
    fi
  done
}

function git::hooks::submodule::upgrade() {
  # NOTE: old way: git submodule foreach git pull origin master
  if (( $# > 0 )); then
    git submodule update --recursive --remote -- "$@"
    return
  fi

  git submodule update --recursive --remote
}
