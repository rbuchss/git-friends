#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"

git::__module__::load || return 0

function _git_ls {
  _git_log
}

function _git_ll {
  _git_log
}

function _git_ld {
  _git_log
}

function _git_lds {
  _git_log
}

function _git_ldi {
  _git_log
}

function _git_prune_branches {
  local index=1 \
    flag_index=1 \
    mode='local' \
    modes='--all --local --remote' \
    found

  local flags="${modes} --force"

  # shellcheck disable=SC2154
  while ((index < cword)); do
    # shellcheck disable=SC2154
    case "${words[index]}" in
      -a | --all)
        mode='all'
        ((flag_index++))
        ;;
      -r | --remote)
        mode='remote'
        ((flag_index++))
        ;;
      -l | --local)
        mode='local'
        ((flag_index++))
        ;;
      -f | --force)
        ((flag_index++))
        ;;
      *) ;;
    esac
    ((index++))
  done

  # shellcheck disable=SC2154
  case "${cur}" in
    --*)
      if found="$(__git_find_on_cmdline "${flags}")" \
        && [[ -z "${found}" ]]; then
        __gitcomp "${flags}"
      elif found="$(__git_find_on_cmdline "${modes}")" \
        && [[ -z "${found}" ]]; then
        __gitcomp "${modes}"
      elif found="$(__git_find_on_cmdline '--force')" \
        && [[ -z "${found}" ]]; then
        __gitcomp '--force'
      fi
      ;;
    *)
      case "${mode}" in
        all)
          case "$((index - flag_index))" in
            2) __gitcomp_direct "$(__git_heads "" "$cur" " ")" ;;
            1) __gitcomp_nl "$(__git_remotes)" ;;
            *) ;;
          esac
          ;;
        remote)
          ((index - flag_index == 1)) \
            && __gitcomp_nl "$(__git_remotes)"
          ;;
        local)
          ((index - flag_index == 1)) \
            && __gitcomp_direct "$(__git_heads "" "$cur" " ")"
          ;;
        *) ;;
      esac
      ;;
  esac
}

# Completions for worktree aliases
function _git_wt {
  _git_worktree
}

function _git_wa {
  # shellcheck disable=SC2154
  case "${cur}" in
    -*)
      __gitcomp '-b --branch'
      ;;
    *)
      __git_complete_refs
      ;;
  esac
}

# Completion for the git::invoke wrapper function.
# Dispatches to subcommand-specific completions or falls back to git completion.
function git::invoke::__complete__ {
  local cur words cword prev

  # Set up completion variables. When registered via __git_complete, these are
  # already provided by __git_func_wrap; re-initializing is harmless.
  # Falls back to raw COMP_WORDS when _get_comp_words_by_ref is unavailable.
  if declare -F _get_comp_words_by_ref >/dev/null 2>&1; then
    _get_comp_words_by_ref -n =: cur words cword prev
  else
    cur="${COMP_WORDS[COMP_CWORD]}"
    words=("${COMP_WORDS[@]}")
    cword="${COMP_CWORD}"
    # shellcheck disable=SC2034
    prev="${COMP_WORDS[COMP_CWORD - 1]:-}"
  fi

  # First argument: complete g subcommands + git commands
  if ((cword == 1)); then
    local g_subcommands='cd cld wcld wco init-context'

    # Get git's completions first (__git_main overwrites COMPREPLY)
    if type __git_main &>/dev/null; then
      __git_main
    fi

    # Then append our custom subcommands so they always appear
    while IFS='' read -r line; do
      COMPREPLY+=("${line}")
    done < <(compgen -W "${g_subcommands}" -- "${cur}")

    return
  fi

  # Subcommand-specific completions
  case "${words[1]}" in
    wco)
      case "${cur}" in
        -*)
          while IFS='' read -r line; do
            COMPREPLY+=("${line}")
          done < <(compgen -W '- -b --branch' -- "${cur}")
          ;;
        *)
          if type __git_complete_refs &>/dev/null; then
            __git_complete_refs
          elif type __git_heads &>/dev/null; then
            __gitcomp_direct "$(__git_heads "" "${cur}" " ")"
          fi
          ;;
      esac
      ;;
    wcld | cld)
      # No special completion — accepts URLs/paths
      ;;
    cd | init-context)
      # No arguments to complete
      ;;
    *)
      # Delegate to git's completion
      if type __git_main &>/dev/null; then
        __git_main
      fi
      ;;
  esac
}
