#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/task_runner.sh"
source "${BASH_SOURCE[0]%/*/*}/cscope.sh"
source "${BASH_SOURCE[0]%/*/*}/ctags.sh"

function git::hooks::post_rewrite() {
  case "$1" in
    rebase)
      git::hooks::task_runner 'post-rewrite' \
        'git::cscope::generate' \
        'git::ctags::generate'
      ;;
  esac
}
