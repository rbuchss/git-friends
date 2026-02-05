#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.git-friends/src/cd.sh"
source "${HOME}/.git-friends/src/worktree.sh"

# NOTE: these need to be bash aliases vs git ones since git aliases run
# in a subshell and as such cannot change the parent shell's directory.
alias gcd='git::cd::root_dir'
alias gwco='git::worktree::checkout'
