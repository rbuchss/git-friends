#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/task_runner.sh"
source "${BASH_SOURCE[0]%/*/*}/cscope.sh"
source "${BASH_SOURCE[0]%/*/*}/ctags.sh"

function git::hooks::post_rewrite {
  case "$1" in
    rebase)
      git::hooks::task_runner 'post-rewrite' \
        'git::cscope::generate' \
        'git::ctags::generate'
      ;;
  esac
}

function git::hooks::post_rewrite::__export__ {
  export -f git::hooks::post_rewrite
}

function git::hooks::post_rewrite::__recall__ {
  export -fn git::hooks::post_rewrite
}

git::hooks::post_rewrite::__export__
