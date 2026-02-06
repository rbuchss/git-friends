#!/usr/bin/env bats

load test_helper

# Stub git completion internals before sourcing completion.sh.
# These must be defined before setup_with_coverage so they are
# available when the source file is loaded.
__gitcomp() { echo "GITCOMP: $*"; }
__gitcomp_nl() { echo "GITCOMP_NL: $*"; }
__gitcomp_direct() { echo "GITCOMP_DIRECT: $*"; }
__git_find_on_cmdline() { echo ""; }
__git_heads() { echo "main feature"; }
__git_remotes() { echo "origin upstream"; }
__git_complete_refs() { echo "COMPLETE_REFS"; }
_git_log() { echo "GIT_LOG_COMPLETION"; }
_git_worktree() { echo "GIT_WORKTREE_COMPLETION"; }

export -f __gitcomp __gitcomp_nl __gitcomp_direct __git_find_on_cmdline
export -f __git_heads __git_remotes __git_complete_refs
export -f _git_log _git_worktree

setup_with_coverage 'git-friends/src/completion.sh'

################################################################################
# _git_ls / _git_ll / _git_ld / _git_lds / _git_ldi (log delegation)
################################################################################

# bats test_tags=_git_ls
@test "_git_ls delegates to _git_log" {
  run _git_ls
  assert_success
  assert_output 'GIT_LOG_COMPLETION'
}

# bats test_tags=_git_ll
@test "_git_ll delegates to _git_log" {
  run _git_ll
  assert_success
  assert_output 'GIT_LOG_COMPLETION'
}

# bats test_tags=_git_ld
@test "_git_ld delegates to _git_log" {
  run _git_ld
  assert_success
  assert_output 'GIT_LOG_COMPLETION'
}

# bats test_tags=_git_lds
@test "_git_lds delegates to _git_log" {
  run _git_lds
  assert_success
  assert_output 'GIT_LOG_COMPLETION'
}

# bats test_tags=_git_ldi
@test "_git_ldi delegates to _git_log" {
  run _git_ldi
  assert_success
  assert_output 'GIT_LOG_COMPLETION'
}

################################################################################
# _git_wt (worktree delegation)
################################################################################

# bats test_tags=_git_wt
@test "_git_wt delegates to _git_worktree" {
  run _git_wt
  assert_success
  assert_output 'GIT_WORKTREE_COMPLETION'
}

################################################################################
# _git_wa
################################################################################

# bats test_tags=_git_wa
@test "_git_wa with cur starting with - completes branch flags" {
  local cur='-'

  run _git_wa
  assert_success
  assert_output 'GITCOMP: -b --branch'
}

# bats test_tags=_git_wa
@test "_git_wa with cur not starting with - completes refs" {
  local cur='feat'

  run _git_wa
  assert_success
  assert_output 'COMPLETE_REFS'
}

################################################################################
# _g_wco
################################################################################

# bats test_tags=_g_wco
@test "_g_wco with cur starting with - populates COMPREPLY with flags" {
  local COMP_WORDS=('g-wco' '-b')
  local COMP_CWORD=1
  local COMPREPLY=()

  _g_wco

  # compgen -W '- -b --branch' -- '-b' should produce '-b'
  [[ " ${COMPREPLY[*]} " == *' -b '* ]]
}

# bats test_tags=_g_wco
@test "_g_wco with cur not starting with - completes refs" {
  local COMP_WORDS=('g-wco' 'feat')
  local COMP_CWORD=1

  run _g_wco
  assert_success
  assert_output 'COMPLETE_REFS'
}

################################################################################
# _git_prune_branches
################################################################################

# bats test_tags=_git_prune_branches
@test "_git_prune_branches with cur=-- and no prior flags completes all flags" {
  local -a words=('git' 'prune-branches' '--')
  local cword=2 cur='--'

  run _git_prune_branches
  assert_success
  assert_output 'GITCOMP: --all --local --remote --force'
}

# bats test_tags=_git_prune_branches
@test "_git_prune_branches with --remote mode and positional arg completes remotes" {
  local -a words=('git' 'prune-branches' '--remote' '')
  local cword=3 cur=''

  run _git_prune_branches
  assert_success
  assert_output 'GITCOMP_NL: origin upstream'
}

# bats test_tags=_git_prune_branches
@test "_git_prune_branches with --all flag sets all mode and completes remotes" {
  local -a words=('git' 'prune-branches' '--all' '')
  local cword=3 cur=''

  run _git_prune_branches
  assert_success
  assert_output 'GITCOMP_NL: origin upstream'
}

# bats test_tags=_git_prune_branches
@test "_git_prune_branches with --all flag and remote set completes branches" {
  local -a words=('git' 'prune-branches' '--all' 'origin' '')
  local cword=4 cur=''

  run _git_prune_branches
  assert_success
  assert_output 'GITCOMP_DIRECT: main feature'
}

# bats test_tags=_git_prune_branches
@test "_git_prune_branches with --local flag explicitly set completes branches" {
  local -a words=('git' 'prune-branches' '--local' '')
  local cword=3 cur=''

  run _git_prune_branches
  assert_success
  assert_output 'GITCOMP_DIRECT: main feature'
}

# bats test_tags=_git_prune_branches
@test "_git_prune_branches with cur=-- after mode set completes remaining flags" {
  local -a words=('git' 'prune-branches' '--remote' '--')
  local cword=3 cur='--'

  # Override __git_find_on_cmdline to simulate: flags found, modes found, force not found
  __git_find_on_cmdline() {
    case "$1" in
      *--force*--all*|*--all*--force*)
        # full flags string: a flag is found
        echo "--remote"
        ;;
      *--all*--local*|*--local*--all*)
        # modes string: a mode is found
        echo "--remote"
        ;;
      '--force')
        # force alone: not found
        echo ""
        ;;
    esac
  }
  export -f __git_find_on_cmdline

  run _git_prune_branches
  assert_success
  assert_output 'GITCOMP: --force'
}

# bats test_tags=_git_prune_branches
@test "_git_prune_branches with cur=-- after mode and force set produces no completions" {
  local -a words=('git' 'prune-branches' '--remote' '--force' '--')
  local cword=4 cur='--'

  # Override __git_find_on_cmdline to simulate: all flags found
  __git_find_on_cmdline() {
    echo "--remote"
  }
  export -f __git_find_on_cmdline

  run _git_prune_branches
  assert_success
  refute_output
}

# bats test_tags=_git_prune_branches
@test "_git_prune_branches with cur=-- after force set completes modes" {
  local -a words=('git' 'prune-branches' '--force' '--')
  local cword=3 cur='--'

  # Override __git_find_on_cmdline to simulate: flags found, modes not found
  __git_find_on_cmdline() {
    case "$1" in
      *--force*--all*|*--all*--force*)
        # full flags string: a flag is found
        echo "--force"
        ;;
      *--all*--local*|*--local*--all*)
        # modes string: no mode found
        echo ""
        ;;
      '--force')
        echo "--force"
        ;;
    esac
  }
  export -f __git_find_on_cmdline

  run _git_prune_branches
  assert_success
  assert_output 'GITCOMP: --all --local --remote'
}

################################################################################
# _g_wco fallback to __git_heads
################################################################################

# bats test_tags=_g_wco
@test "_g_wco falls back to __git_heads when __git_complete_refs is unavailable" {
  local COMP_WORDS=('g-wco' 'feat')
  local COMP_CWORD=1

  # Unset __git_complete_refs so the fallback path is taken
  unset -f __git_complete_refs

  run _g_wco
  assert_success
  assert_output 'GITCOMP_DIRECT: main feature'
}
