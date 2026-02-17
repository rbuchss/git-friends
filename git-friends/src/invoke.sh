#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/exec.sh"
source "${BASH_SOURCE[0]%/*}/cd.sh"
source "${BASH_SOURCE[0]%/*}/clone.sh"
source "${BASH_SOURCE[0]%/*}/worktree.sh"
source "${BASH_SOURCE[0]%/*}/completion.sh"

# Unified git-friends shell wrapper.
# Intercepts subcommands that need the current shell (cd, clone-cd, worktree-checkout)
# and passes everything else through to git.
# Usage: git::invoke <subcommand> [args...]
function git::invoke {
  case "$1" in
    cd)
      shift
      git::cd::root_dir "$@"
      ;;
    cld)
      shift
      git::clone::cd "$@"
      ;;
    wcld)
      shift
      git::worktree::clone::cd "$@"
      ;;
    wco)
      shift
      git::worktree::checkout "$@"
      ;;
    init-context)
      shift
      git::worktree::init_context "$@"
      ;;
    *) git::__exec__ "$@" ;;
  esac
}

# Set up aliases and completion registration.
function git::invoke::__enable__ {
  # shellcheck disable=SC2139
  alias git='git::invoke'
  # shellcheck disable=SC2139
  alias g='git::invoke'

  if declare -F __git_complete >/dev/null 2>&1; then
    __git_complete git git::invoke::__complete__
    __git_complete g git::invoke::__complete__
  else
    complete -F git::invoke::__complete__ git
    complete -F git::invoke::__complete__ g
  fi
}

# Remove aliases and completion registration.
function git::invoke::__disable__ {
  unalias git 2>/dev/null
  unalias g 2>/dev/null

  # __git_complete uses complete under the hood so using
  #   complete -r to remove
  # ref:
  #   https://github.com/git/git/blob/e79552d19784ee7f4bbce278fe25f93fbda196fa/contrib/completion/git-completion.bash#L3741-L3747
  complete -r git 2>/dev/null
  complete -r g 2>/dev/null
}

function git::invoke::__export__ {
  export -f git::invoke
}

function git::invoke::__recall__ {
  export -fn git::invoke
}

git::invoke::__export__
