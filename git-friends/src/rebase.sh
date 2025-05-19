#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/logger.sh"
source "${BASH_SOURCE[0]%/*}/utility.sh"

function git::rebase::to_main() {
  local remote="${1:-origin}" \
    main_ref

  if ! main_ref="$(git::utility::get_main_ref "${remote}")"; then
    git::logger::error "Could not find main ref for remote: '${remote}' - exiting"
    return 1
  fi

  git::logger::info "Found git main ref for remote: '${main_ref}' - using to rebase"
  git rebase "${main_ref}"
}
