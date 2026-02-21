#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/exec.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"

git::__module__::load || return 0

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

    read -r response_for_all_ <<<"${!response_for_all_var_}"

    if [[ -n "${response_for_all_}" ]]; then
      ((response_for_all_ == 0)) \
        && echo 'all' \
        || echo 'none'
      return "${response_for_all_}"
    fi

    read -r response

    case "${response}" in
      [yY] | [yY][eE][sS]) return 0 ;;
      [nN] | [nN][oO]) return 1 ;;
      [aA] | [aA][lL][lL])
        read -r "$2" <<<0
        return 0
        ;;
      [zZ] | [nN][oO][nN][eE])
        read -r "$2" <<<1
        return 1
        ;;
      *) return 1 ;;
    esac
  fi

  read -r -p "${question} [yes/no (y/n)] ? " response

  case "${response}" in
    [yY] | [yY][eE][sS]) return 0 ;;
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

# Expand index arguments (integers and Python-style ranges) into individual indices.
# Outputs expanded indices to stdout, one per line.
# Range syntax uses exclusive stop (like Python slices):
#   2:5  → 2, 3, 4
#   1:   → 1 through max (open end defaults to max+1)
#   :3   → min through 2 (open start defaults to min)
#   :    → min through max (both open)
# Usage: git::utility::expand_indices <min> <max> [args...]
function git::utility::expand_indices {
  local \
    min="$1" \
    max="$2" \
    max_stop=$(($2 + 1))

  shift 2

  local arg start stop index

  for arg in "$@"; do
    if [[ "${arg}" == *:* ]]; then
      start="${arg%%:*}"
      stop="${arg##*:}"
      start="${start:-${min}}"
      stop="${stop:-${max_stop}}"

      case "${start}" in *[!0-9]* | '')
        git::logger::error "invalid range '${arg}'"
        return 1
        ;;
      esac

      case "${stop}" in *[!0-9]* | '')
        git::logger::error "invalid range '${arg}'"
        return 1
        ;;
      esac

      if ((start < min || stop > max_stop)); then
        git::logger::error "range '${arg}' is out of bounds (${min}-${max})"
        return 1
      fi

      if ((start >= stop)); then
        git::logger::error "range '${arg}' is empty or inverted"
        return 1
      fi

      for ((index = start; index < stop; index++)); do
        echo "${index}"
      done
    else
      case "${arg}" in *[!0-9]* | '')
        git::logger::error "'${arg}' is not a valid index"
        return 1
        ;;
      esac

      if ((arg < min || arg > max)); then
        git::logger::error "index ${arg} is out of range (${min}-${max})"
        return 1
      fi

      echo "${arg}"
    fi
  done
}

# Check if a function or command is executable.
# Returns success if the name is a declared function or found on PATH.
# Usage: git::utility::is_executable <name>
function git::utility::is_executable {
  local task="$1"

  if ! declare -F "${task}" >/dev/null 2>&1 \
    && ! command -v "${task}" >/dev/null 2>&1; then
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
    <<<"${GIT_FRIENDS_MAIN_BRANCH_NAMES:-master main mainline}"
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
    git_cmd=(git::exec) \
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
    git_cmd=(git::exec) \
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
    git_cmd=(git::exec) \
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
    git_cmd=(git::exec) \
    git_common_dir \
    parent_is_bare

  [[ -n "${path}" ]] && git_cmd+=(-C "${path}")

  git_common_dir="$("${git_cmd[@]}" rev-parse --git-common-dir 2>/dev/null)" \
    || return 1

  [[ -z "${git_common_dir}" ]] && return 1

  parent_is_bare="$(git::exec --git-dir="${git_common_dir}" rev-parse --is-bare-repository 2>/dev/null)"

  [[ "${parent_is_bare}" == 'true' ]]
}

function git::utility::__export__ {
  export -f git::utility::ask
  export -f git::utility::array_contains
  export -f git::utility::expand_indices
  export -f git::utility::is_executable
  export -f git::utility::is_not_executable
  export -f git::utility::main_branch_names
  export -f git::utility::get_main_ref
  export -f git::utility::get_main_ref::remote
  export -f git::utility::get_main_ref::local
  export -f git::utility::is_bare_or_worktree
  export -f git::utility::is_bare
  export -f git::utility::is_worktree
}

# KCOV_EXCL_START
function git::utility::__recall__ {
  export -fn git::utility::ask
  export -fn git::utility::array_contains
  export -fn git::utility::expand_indices
  export -fn git::utility::is_executable
  export -fn git::utility::is_not_executable
  export -fn git::utility::main_branch_names
  export -fn git::utility::get_main_ref
  export -fn git::utility::get_main_ref::remote
  export -fn git::utility::get_main_ref::local
  export -fn git::utility::is_bare_or_worktree
  export -fn git::utility::is_bare
  export -fn git::utility::is_worktree
}
# KCOV_EXCL_STOP

git::__module__::export
