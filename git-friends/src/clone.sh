#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/logger.sh"
source "${BASH_SOURCE[0]%/*}/url.sh"

# Clone repository and cd into it.
# Usage: git::clone::cd <repository> [directory] [git-clone-args...]
function git::clone::cd {
  local \
    repository="$1" \
    directory="$2"

  if [[ -z "${repository}" ]]; then
    git::logger::error 'No repository url provided'
    return 1
  fi

  if ! git clone "$@"; then
    return 1
  fi

  # Derive directory if not provided
  if [[ -z "${directory}" ]]; then
    directory="$(git::url::repo_name "${repository}")"
  fi

  git::logger::info "Changing directory to: '${directory}'"
  cd "${directory}" || return 1
}
