#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/utility.sh"

function git::prune::branches() {
  local cmd='git::prune::branches::local' \
    force=0 \
    arguments=()

  while (( $# != 0 )); do
    case "$1" in
      -a | --all)
        cmd='git::prune::branches::all'
        ;;
      -f | --force)
        force=1
        ;;
      -l | --local)
        cmd='git::prune::branches::local'
        ;;
      -r | --remote)
        cmd='git::prune::branches::remote'
        ;;
      -*)
        >&2 echo "ERROR: ${FUNCNAME[0]} invalid option: '$1'"
        git::prune::branches::usage >&2
        return 1
        ;;
      *)
        arguments+=("$1")
        ;;
    esac
    shift
  done

  "${cmd}" "${force}" "${arguments[@]}"
}

function git::prune::branches::usage() {
  cat <<USAGE_TEXT
Usage: ${FUNCNAME[1]}: [OPTIONS] <target>
  -a, --all     Prune local and remote branches
                <target> = <remote> <branch>

  -f, --force   Do not prompt

  -l, --local   prune local branches (default)
                <target> = <branch>

  -r, --remote  prune remote branches
                <target> = <remote>
USAGE_TEXT
}

function git::prune::branches::local() {
  local force="$1" \
    ref_branch="$2" \
    merged_branches=()
  # shellcheck disable=SC2034
  local all_response

  [[ -z "${ref_branch}" ]] \
    && ref_branch="$(git branch --show-current)"

  if ! git show-ref --verify --quiet "refs/heads/${ref_branch}"; then
    >&2 echo "ERROR: ${FUNCNAME[0]}: reference branch '${ref_branch}' does not exist"
    return 1
  fi

  while IFS= read -r merged_branch; do
    merged_branches+=("${merged_branch//[[:blank:]]/}")
  done < <(git branch --merged "${ref_branch}" \
    | grep -E -v "^(\*\s+.+|\s+(master|${ref_branch}))$")

  (( "${#merged_branches[@]}" == 0 )) && return

  echo "${FUNCNAME[0]} found ${#merged_branches[@]} branches merged into ${ref_branch}:"
  printf ' - %s\n' "${merged_branches[@]}"

  for branch in "${merged_branches[@]}"; do
    if (( force == 1 )) \
      || git::utility::ask "remove: '${branch}'" all_response; then
        git branch -d "${branch}"
    fi
  done
}

function git::prune::branches::remote() {
  local force="$1" \
    remote="${2:-origin}" \
    dry_run_response

  if ! dry_run_response="$(git remote prune -n "${remote}")"; then
    >&2 echo "ERROR: remote '${remote}' is not valid"
    return 1
  fi

  # nothing to prune so exit
  [[ -z "${dry_run_response}" ]] && return

  printf '%s: %s\n%s\n' \
    "${FUNCNAME[0]}" \
    "${remote}" \
    "${dry_run_response}"

  if (( force == 1 )) \
    || git::utility::ask "confirm prune remote: '${remote}'"; then
      git remote prune "${remote}"
  fi
}

function git::prune::branches::all() {
  local force="$1" \
    remote="$2" \
    ref_branch="$3"

  if (( $# == 2 )); then
    >&2 echo 'ERROR: invalid number of arguments'
    >&2 echo "Usage: ${FUNCNAME[0]} force [remote] [branch]"
    >&2 echo ' - optional remote and branch must be specified together'
    return 1
  fi

  git::prune::branches::local "${force}" "${ref_branch}" \
    && echo \
    && git::prune::branches::remote "${force}" "${remote}"
}
