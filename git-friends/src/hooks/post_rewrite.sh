#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/__module__.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/hooks/task_runner.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/cscope.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/ctags.sh"

git::__module__::load || return 0

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

# KCOV_EXCL_START
function git::hooks::post_rewrite::__recall__ {
  export -fn git::hooks::post_rewrite
}
# KCOV_EXCL_STOP

git::__module__::export
