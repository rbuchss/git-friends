#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/exec.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/utility.sh"

git::__module__::load || return 0

function git::prune::branches {
  local \
    cmd='git::prune::branches::local' \
    force=0 \
    arguments=()

  while (($# != 0)); do
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
        git::logger::error "invalid option: '$1'"
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

function git::prune::branches::usage {
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

function git::prune::branches::local {
  local \
    force="$1" \
    ref_branch="$2" \
    current_branch \
    branch \
    protected_branches=() \
    merged_branches=() \
    squashed_branches=()
  # shellcheck disable=SC2034
  local \
    merged_response \
    squashed_response

  [[ -z "${ref_branch}" ]] \
    && ref_branch="$(git::exec branch --show-current)"

  if ! git::exec show-ref --verify --quiet "refs/heads/${ref_branch}"; then
    git::logger::error "reference branch '${ref_branch}' does not exist"
    return 1
  fi

  # Branches that must never be pruned: the configured main branch names plus
  # the current branch and the reference branch.
  git::utility::main_branch_names protected_branches
  protected_branches+=("${ref_branch}")
  current_branch="$(git::exec branch --show-current)"
  [[ -n "${current_branch}" ]] && protected_branches+=("${current_branch}")

  # Ancestry-merged branches are reachable from the ref, so the safe `-d`
  # delete accepts them. `--format` yields bare names with no `*`/`+` markers.
  while IFS= read -r branch; do
    [[ -z "${branch}" ]] && continue
    git::utility::array_contains "${branch}" "${protected_branches[@]}" \
      && continue
    merged_branches+=("${branch}")
  done < <(git::exec branch --merged "${ref_branch}" --format='%(refname:short)')

  # Squash-merged branches are patch-equivalent to the ref but not ancestors of
  # it, so `-d` refuses them and only `-D` (force) can remove them.
  while IFS= read -r branch; do
    [[ -z "${branch}" ]] && continue
    git::utility::array_contains "${branch}" "${protected_branches[@]}" \
      && continue
    git::utility::array_contains "${branch}" "${merged_branches[@]}" \
      && continue
    git::prune::branches::is_squash_merged "${ref_branch}" "${branch}" \
      && squashed_branches+=("${branch}")
  done < <(git::exec for-each-ref --format='%(refname:short)' refs/heads)

  (("${#merged_branches[@]}" == 0 && "${#squashed_branches[@]}" == 0)) \
    && return

  if (("${#merged_branches[@]}" > 0)); then
    git::logger::info "found ${#merged_branches[@]} branches merged into '${ref_branch}':"
    printf ' - %s\n' "${merged_branches[@]}"

    for branch in "${merged_branches[@]}"; do
      if ((force == 1)) \
        || git::utility::ask "remove: '${branch}'" merged_response; then
        git::exec branch -d "${branch}"
      fi
    done
  fi

  if (("${#squashed_branches[@]}" > 0)); then
    git::logger::info "found ${#squashed_branches[@]} squash-merged branches into '${ref_branch}' (require force-delete):"
    printf ' - %s\n' "${squashed_branches[@]}"

    for branch in "${squashed_branches[@]}"; do
      if ((force == 1)) \
        || git::utility::ask "force-remove squash-merged: '${branch}'" squashed_response; then
        git::exec branch -D "${branch}"
      fi
    done
  fi
}

# Return success if <branch> is squash-merged into <ref_branch>: its full diff
# against the merge-base already exists in the ref as a single (squashed)
# commit. Such a branch is patch-equivalent to the ref but not an ancestor of
# it, so `git branch -d` refuses it. A branch that has any commits beyond what
# was squash-merged diverges from the ref and is reported as not merged, which
# is what keeps force-deleting safe.
# Usage: git::prune::branches::is_squash_merged <ref_branch> <branch>
function git::prune::branches::is_squash_merged {
  local \
    ref_branch="$1" \
    branch="$2" \
    merge_base \
    tree \
    synthetic \
    cherry

  merge_base="$(git::exec merge-base "${ref_branch}" "${branch}")" \
    || return 1
  tree="$(git::exec rev-parse "${branch}^{tree}")" \
    || return 1

  # The synthetic commit is throwaway, so supply a fixed identity rather than
  # depending on the user's git config (commit-tree fails without one).
  synthetic="$(
    export \
      GIT_AUTHOR_NAME='git-friends' \
      GIT_AUTHOR_EMAIL='git-friends@localhost' \
      GIT_COMMITTER_NAME='git-friends' \
      GIT_COMMITTER_EMAIL='git-friends@localhost'
    git::exec commit-tree "${tree}" -p "${merge_base}" -m _
  )" || return 1

  cherry="$(git::exec cherry "${ref_branch}" "${synthetic}")" \
    || return 1

  # `git cherry` prefixes a commit already present in the ref with '-'.
  [[ "${cherry}" == -* ]]
}

function git::prune::branches::remote {
  local \
    force="$1" \
    remote="${2:-origin}" \
    dry_run_response

  if ! dry_run_response="$(git::exec remote prune -n "${remote}")"; then
    git::logger::error "remote '${remote}' is not valid"
    return 1
  fi

  # nothing to prune so exit
  [[ -z "${dry_run_response}" ]] && return

  printf '%s: %s\n%s\n' \
    "${FUNCNAME[0]}" \
    "${remote}" \
    "${dry_run_response}"

  if ((force == 1)) \
    || git::utility::ask "confirm prune remote: '${remote}'"; then
    git::exec remote prune "${remote}"
  fi
}

function git::prune::branches::all {
  local \
    force="$1" \
    remote="$2" \
    ref_branch="$3"

  if (($# == 2)); then
    git::logger::error 'invalid number of arguments'
    git::logger::error "Usage: ${FUNCNAME[0]} force [remote] [branch]"
    git::logger::error ' - optional remote and branch must be specified together'
    return 1
  fi

  git::prune::branches::local "${force}" "${ref_branch}" \
    && echo \
    && git::prune::branches::remote "${force}" "${remote}"
}

function git::prune::__export__ {
  export -f git::prune::branches
  export -f git::prune::branches::usage
  export -f git::prune::branches::local
  export -f git::prune::branches::is_squash_merged
  export -f git::prune::branches::remote
  export -f git::prune::branches::all
}

# KCOV_EXCL_START
function git::prune::__recall__ {
  export -fn git::prune::branches
  export -fn git::prune::branches::usage
  export -fn git::prune::branches::local
  export -fn git::prune::branches::is_squash_merged
  export -fn git::prune::branches::remote
  export -fn git::prune::branches::all
}
# KCOV_EXCL_STOP

git::__module__::export
