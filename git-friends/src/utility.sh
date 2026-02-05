#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/logger.sh"

function git::utility::ask {
  local \
    question="$1" \
    response_for_all_var_="$2" \
    response_for_all_

  if [[ -n "${response_for_all_var_}" ]]; then
    echo -n "${question} [yes/no/all/none (y/n/a/z)] ? "

    read -r response_for_all_ <<< "${!response_for_all_var_}"

    if [[ -n "${response_for_all_}" ]]; then
      (( response_for_all_ == 0 )) \
        && echo 'all' \
        || echo 'none'
      return "${response_for_all_}"
    fi

    read -r response

    case "${response}" in
      [yY]|[yY][eE][sS]) return 0 ;;
      [nN]|[nN][oO]) return 1 ;;
      [aA]|[aA][lL][lL])
        read -r "$2" <<< 0
        return 0
        ;;
      [zZ]|[nN][oO][nN][eE])
        read -r "$2" <<< 1
        return 1
        ;;
      *) return 1 ;;
    esac
  fi

  read -r -p "${question} [yes/no (y/n)] ? " response

  case "${response}" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

function git::utility::array_contains {
  local \
    match="$1" \
    element

  shift

  for element; do
    [[ "${element}" == "${match}" ]] \
      && return 0
  done

  return 1
}

function git::utility::is_executable {
  local task="$1"

  if ! declare -F "${task}" > /dev/null 2>&1 \
    && ! command -v "${task}" > /dev/null 2>&1; then
      return 1
  fi
}

function git::utility::is_not_executable {
  ! git::utility::is_executable "$@"
}

function git::utility::get_main_ref {
  local \
    remote="${1:-origin}" \
    path="$2" \
    git_cmd=(git) \
    is_bare \
    git_common_dir \
    ref_prefix \
    branch_ref_prefix \
    branch_ref \
    branch_name \
    branch_refs=() \
    branch_names=(
      master
      main
      mainline
    )

  if [[ -n "${path}" ]]; then
    git_cmd=(git -C "${path}")
  fi

  is_bare="$("${git_cmd[@]}" rev-parse --is-bare-repository 2>/dev/null)"
  git::logger::debug "is_bare (initial): '${is_bare}'"

  # Also check if we're in a worktree linked to a bare repo
  if [[ "${is_bare}" != 'true' ]]; then
    git_common_dir="$("${git_cmd[@]}" rev-parse --git-common-dir 2>/dev/null)"
    git::logger::debug "git_common_dir: '${git_common_dir}'"

    if [[ -n "${git_common_dir}" ]]; then
      is_bare="$(git --git-dir="${git_common_dir}" rev-parse --is-bare-repository 2>/dev/null)"
      git::logger::debug "is_bare (from common dir): '${is_bare}'"
    fi
  fi

  if [[ "${is_bare}" == 'true' ]]; then
    ref_prefix='refs/heads'
    branch_ref_prefix=''
  else
    ref_prefix="refs/remotes/${remote}"
    branch_ref_prefix="${remote}/"
  fi

  for branch_name in "${branch_names[@]}"; do
    branch_ref="${branch_ref_prefix}${branch_name}"
    branch_refs+=("${branch_ref}")

    git::logger::debug "Checking if git branch: '${branch_ref}' exists"

    if "${git_cmd[@]}" show-ref --quiet "${ref_prefix}/${branch_name}"; then
      git::logger::debug "Found git branch: '${branch_ref}' - using as main ref"

      echo "${branch_ref}"
      return 0
    fi
  done

  git::logger::warning "Could not find any matching git branches: [${branch_refs[*]}] - exiting"
  return 1
}
