#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/__module__.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/hooks/task_runner.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/cscope.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/ctags.sh"

git::__module__::load || return 0

function git::hooks::post_checkout {
  git::hooks::task_runner 'post-checkout' \
    'git::cscope::generate' \
    'git::ctags::generate'
}

function git::hooks::post_checkout::__export__ {
  export -f git::hooks::post_checkout
}

function git::hooks::post_checkout::__recall__ {
  export -fn git::hooks::post_checkout
}

git::__module__::export
