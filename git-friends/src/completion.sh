#!/bin/bash

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
  while (( index < cword )); do
    # shellcheck disable=SC2154
    case "${words[index]}" in
      -a | --all)
        mode='all'
        (( flag_index++ ))
        ;;
      -r | --remote)
        mode='remote'
        (( flag_index++ ))
        ;;
      -l | --local)
        mode='local'
        (( flag_index++ ))
        ;;
      -f | --force)
        (( flag_index++ ))
        ;;
      *)
        ;;
    esac
    (( index++ ))
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
          case "$(( index - flag_index ))" in
            2) __gitcomp_direct "$(__git_heads "" "$cur" " ")" ;;
            1) __gitcomp_nl "$(__git_remotes)" ;;
            *) ;;
          esac
          ;;
        remote)
          (( index - flag_index == 1 )) \
            && __gitcomp_nl "$(__git_remotes)"
          ;;
        local)
          (( index - flag_index == 1 )) \
            && __gitcomp_direct "$(__git_heads "" "$cur" " ")"
          ;;
        *)
          ;;
      esac
      ;;
  esac
}
