#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/logger.sh"

function git::utility::ask() {
  local question="$1" \
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

function git::utility::array_contains() {
  local match="$1" \
    element
  shift

  for element; do
    [[ "${element}" == "${match}" ]] \
      && return 0
  done

  return 1
}

function git::utility::is_executable() {
  local task="$1"

  if ! declare -F "${task}" > /dev/null 2>&1 \
    && ! command -v "${task}" > /dev/null 2>&1; then
      return 1
  fi
}

function git::utility::is_not_executable() {
  ! git::utility::is_executable "$@"
}

function git::utility::get_mainline_ref {
  local remote="${1:-origin}" \
    branch_ref \
    branch_name \
    branch_refs=() \
    branch_names=(
      master
      main
      mainline
    )

  for branch_name in "${branch_names[@]}"; do
    branch_refs+=("${remote}/${branch_name}")
  done

  for branch_ref in "${branch_refs[@]}"; do
    git::logger::debug "Checking if remote git branch: '${branch_ref}' exists"

    if git show-ref --quiet "refs/remotes/${branch_ref}"; then
      git::logger::info "Found git remote branch: '${branch_ref}' - using as mainline ref"

      echo "${branch_ref%*/}"
      return 0
    fi
  done

  git::logger::warning "Could not find any matching remote git branches: [${branch_refs[*]}] - exiting"
  return 1
}
