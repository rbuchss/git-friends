#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/logger.sh"

function git::remote::default_branch {
  local remote_name="${1:-origin}"
  # This way is more relable but slow due to the network call:
  # git remote show "${remote_name}" | sed -n '/HEAD branch/s/.*: //p'
  #
  # This version is faster since it uses the git cached version. However, due to this this can fail.
  # To avoid this we can sync this symbolic ref from upstream using:
  # $ git remote set-head origin --auto.
  # This updates both what is seen in git remote show and the symbolic ref referenced here.
  git symbolic-ref "refs/remotes/${remote_name}/HEAD" \
    | sed "s@^refs/remotes/${remote_name}/@@"
}

function git::remote::check_status {
  local \
    current_branch \
    remote="${1:-origin}" \
    remote_branch \
    local_hash \
    remote_hash \
    commit_hashes \
    branch_status

  if ! git::remote::validate_repository; then
    git::logger::error 'Not a valid repository'
    return 1
  fi

  if ! current_branch="$(git::remote::get_current_branch)"; then
    git::logger::error 'Could not determine current branch'
    return 1
  fi

  git::logger::info "Current branch: ${current_branch}"

  remote_branch="${remote}/${current_branch}"

  if ! git::remote::fetch_remote "${remote}"; then
    git::logger::error 'Could not fetch remote branch'
    return 1
  fi

  if ! git::remote::validate_remote_branch "${remote_branch}"; then
    branch_status=$?
    if (( branch_status == 2 )); then
      # Missing remote branch is not an error, just exit cleanly
      return 0
    fi
    return 1
  fi

  if ! commit_hashes="$(
    git::remote::get_commit_hashes "${remote_branch}"
  )"; then
    git::logger::error 'Error: Could not get commit hashes'
    return 1
  fi

  read -r local_hash remote_hash <<< "${commit_hashes}"

  git::remote::compare_branches \
    "${current_branch}" \
    "${remote}" \
    "${remote_branch}" \
    "${local_hash}" \
    "${remote_hash}"
}

function git::remote::compare_branches {
  local \
    current_branch="$1" \
    remote="$2" \
    remote_branch="$3" \
    local_hash="$4" \
    remote_hash="$5" \
    merge_base \
    commits_ahead \
    commits_behind \
    red='\033[0;31m' \
    green='\033[0;32m' \
    yellow='\033[0;33m' \
    nc='\033[0m' # No Color

  if [[ "${local_hash}" == "${remote_hash}" ]]; then
    git::logger::info "${green}✓ Repository is up to date${nc}"
    return 0
  fi

  # Check if local is ahead, behind, or diverged
  merge_base="$(git merge-base HEAD "${remote_branch}")"

  # Local is ahead
  if [[ "${merge_base}" == "${remote_hash}" ]]; then
    commits_ahead="$(git rev-list --count "${remote_branch}"..HEAD)"

    git::logger::warning \
      "${yellow}⚠ Local repository is ${commits_ahead} commit(s) ahead of remote${nc}" \
      "Consider pushing your changes: git push ${remote} ${current_branch}"

    return 0
  fi

  # Local is behind
  if [[ "${merge_base}" == "${local_hash}" ]]; then
    commits_behind="$(git rev-list --count HEAD.."${remote_branch}")"

    git::logger::error \
      "${red}⚠ Repository is OUT OF DATE!${nc}" \
      "Local repository is ${commits_behind} commit(s) behind remote"

    git::logger::warning "To update: git rebase ${remote}/${current_branch}"

    return 1
  fi

  # Branches have diverged
  commits_ahead="$(git rev-list --count "${remote_branch}"..HEAD)"
  commits_behind="$(git rev-list --count HEAD.."${remote_branch}")"

  git::logger::warning \
    "${yellow}⚠ Branches have diverged!${nc}" \
    "Local is ${commits_ahead} commit(s) ahead and ${commits_behind} commit(s) behind remote" \
    "Consider rebasing or merging: git rebase ${remote}/${current_branch}"

  return 1
}

function git::remote::get_commit_hashes {
  local \
    remote_branch="$1" \
    local_hash \
    remote_hash

  local_hash="$(git rev-parse HEAD)"
  remote_hash="$(git rev-parse "${remote_branch}")"

  printf "%s %s" "${local_hash}" "${remote_hash}"
}

function git::remote::validate_remote_branch {
  local remote_branch="$1"

  if ! git show-ref --verify --quiet "refs/remotes/${remote_branch}"; then
    git::logger::warning \
      "Warning: Remote branch '${remote_branch}' doesn't exist" \
      "This might be a new local branch that hasn't been pushed yet"

    return 2  # Special return code for missing remote branch
  fi

  return 0
}

function git::remote::fetch_remote {
  local remote="$1"

  git::logger::info "Fetching latest changes from ${remote}..."

  # Fetch the latest changes from remote without merging
  if ! git fetch "${remote}" 2>/dev/null; then
    git::remote::handle_fetch_error "$?"
    return $?
  fi

  return 0
}

function git::remote::get_current_branch {
  local current_branch

  current_branch="$(
    git symbolic-ref --short HEAD 2>/dev/null \
    || git rev-parse --short HEAD
  )"

  if [[ -z "${current_branch}" ]]; then
    return 1
  fi

  printf "%s" "${current_branch}"
}

function git::remote::validate_repository {
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    git::logger::error 'Not in a git repository'
    return 1
  fi

  return 0
}

function git::remote::handle_fetch_error {
  local status="${1:-${?}}"

  case "${status}" in
    128)
      git::logger::error 'Could not connect to remote repository'
      git::logger::warning \
        'Possible causes:' \
        '  • Network connectivity issues' \
        '  • Remote repository URL has changed' \
        '  • Authentication credentials expired' \
        '  • Remote repository no longer exists'
      ;;
    129)
      git::logger::error 'Authentication failed'
      git::logger::warning 'Check your SSH keys or access tokens'
      ;;
    *)
      git::logger::error "Git fetch failed with exit code ${status}"
      git::logger::warning 'Check your network connection and repository access'
      ;;
  esac

  return "${status}"
}
