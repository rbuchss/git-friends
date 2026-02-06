#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/logger.sh"

# Prompt the user with a yes/no question.
# When a response variable name is provided, also supports all/none (a/z) to
# batch subsequent prompts. The variable is set to 0 (all) or 1 (none) and
# reused on future calls to skip the prompt.
# Usage: git::utility::ask <question> [response_variable]
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

# Check if an array contains a given element.
# Usage: git::utility::array_contains <match> [elements...]
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

# Check if a function or command is executable.
# Returns success if the name is a declared function or found on PATH.
# Usage: git::utility::is_executable <name>
function git::utility::is_executable {
  local task="$1"

  if ! declare -F "${task}" > /dev/null 2>&1 \
    && ! command -v "${task}" > /dev/null 2>&1; then
      return 1
  fi
}

# Inverse of git::utility::is_executable.
# Usage: git::utility::is_not_executable <name>
function git::utility::is_not_executable {
  ! git::utility::is_executable "$@"
}

# Get main branch name candidates.
# Reads from GIT_FRIENDS_MAIN_BRANCH_NAMES env var, defaulting to 'master main mainline'.
# Sets the named array variable in caller's scope.
# Usage: git::utility::main_branch_names <variable_name>
function git::utility::main_branch_names {
  local __git_utility_main_branch_names_output="$1"

  IFS=' ' read -ra "${__git_utility_main_branch_names_output?}" \
    <<< "${GIT_FRIENDS_MAIN_BRANCH_NAMES:-master main mainline}"
}

# Find the main branch ref for a repository.
# Tries remote tracking refs first, falls back to local refs for bare repos.
# Usage: git::utility::get_main_ref [remote] [path]
function git::utility::get_main_ref {
  local \
    remote="${1:-origin}" \
    path="$2"

  git::utility::get_main_ref::remote "${remote}" "${path}" && return 0

  git::logger::debug "No remote tracking ref found - checking for bare/worktree fallback"

  if git::utility::is_bare_or_worktree "${path}"; then
    git::utility::get_main_ref::local "${path}" && return 0
  fi

  git::logger::warning "Could not find main branch for remote: '${remote}' - exiting"
  return 1
}

# Find the main branch from remote tracking refs (refs/remotes/<remote>/*).
# Usage: git::utility::get_main_ref::remote <remote> [path]
function git::utility::get_main_ref::remote {
  local \
    remote="$1" \
    path="$2" \
    git_cmd=(git) \
    branch_name \
    main_branch_names

  git::utility::main_branch_names main_branch_names

  [[ -n "${path}" ]] && git_cmd+=(-C "${path}")

  for branch_name in "${main_branch_names[@]}"; do
    if "${git_cmd[@]}" show-ref --quiet "refs/remotes/${remote}/${branch_name}"; then
      git::logger::debug "Found remote branch: '${remote}/${branch_name}'"
      echo "${remote}/${branch_name}"
      return 0
    fi
  done

  return 1
}

# Find the main branch from local refs (refs/heads/*).
# Used as fallback for bare repos during initial clone before fetch.
# Usage: git::utility::get_main_ref::local [path]
function git::utility::get_main_ref::local {
  local \
    path="$1" \
    git_cmd=(git) \
    branch_name \
    main_branch_names

  git::utility::main_branch_names main_branch_names

  [[ -n "${path}" ]] && git_cmd+=(-C "${path}")

  for branch_name in "${main_branch_names[@]}"; do
    if "${git_cmd[@]}" show-ref --quiet "refs/heads/${branch_name}"; then
      git::logger::debug "Found local branch: '${branch_name}'"
      echo "${branch_name}"
      return 0
    fi
  done

  return 1
}

# Check if a repo is bare directly or a worktree linked to a bare repo.
# Usage: git::utility::is_bare_or_worktree [path]
function git::utility::is_bare_or_worktree {
  git::utility::is_bare "$@" \
    || git::utility::is_worktree "$@"
}

# Check if a repo is a bare repository.
# Usage: git::utility::is_bare [path]
function git::utility::is_bare {
  local \
    path="$1" \
    git_cmd=(git) \
    is_bare

  [[ -n "${path}" ]] && git_cmd+=(-C "${path}")

  is_bare="$("${git_cmd[@]}" rev-parse --is-bare-repository 2>/dev/null)"

  [[ "${is_bare}" == 'true' ]]
}

# Check if a path is a worktree linked to a bare repository.
# Usage: git::utility::is_worktree [path]
function git::utility::is_worktree {
  local \
    path="$1" \
    git_cmd=(git) \
    git_common_dir \
    parent_is_bare

  [[ -n "${path}" ]] && git_cmd+=(-C "${path}")

  git_common_dir="$("${git_cmd[@]}" rev-parse --git-common-dir 2>/dev/null)" \
    || return 1

  [[ -z "${git_common_dir}" ]] && return 1

  parent_is_bare="$(git --git-dir="${git_common_dir}" rev-parse --is-bare-repository 2>/dev/null)"

  [[ "${parent_is_bare}" == 'true' ]]
}
