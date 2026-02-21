#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/__module__.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/hooks/task_runner.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/cscope.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/ctags.sh"

git::__module__::load || return 0

function git::hooks::post_commit {
  git::hooks::task_runner 'post-commit' \
    'git::cscope::generate' \
    'git::ctags::generate'
}

function git::hooks::post_commit::__export__ {
  export -f git::hooks::post_commit
}

function git::hooks::post_commit::__recall__ {
  export -fn git::hooks::post_commit
}

git::__module__::export
