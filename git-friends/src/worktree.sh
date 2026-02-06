#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/logger.sh"
source "${BASH_SOURCE[0]%/*}/url.sh"
source "${BASH_SOURCE[0]%/*}/utility.sh"

# Get the default remote, respecting checkout.defaultRemote config.
# Falls back to 'origin' if not set.
# Usage: git::worktree::default_remote [path]
function git::worktree::default_remote {
  local \
    path="$1" \
    git_cmd=(git)

  [[ -n "${path}" ]] && git_cmd+=(-C "${path}")

  "${git_cmd[@]}" config checkout.defaultRemote 2>/dev/null || echo 'origin'
}

# Get path to file storing previous worktree branch.
# Uses shared git dir so it's accessible from all worktrees.
function git::worktree::previous_file {
  local git_common_dir
  git_common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || return 1
  echo "${git_common_dir}/.git-friends-previous-worktree"
}

# Save current branch as previous worktree.
# Called before cd'ing to a new worktree.
function git::worktree::save_previous {
  local \
    current_branch \
    previous_file

  current_branch="$(git branch --show-current 2>/dev/null)" || return 1
  previous_file="$(git::worktree::previous_file)" || return 1

  echo "${current_branch}" > "${previous_file}"
}

# Get the previous worktree branch.
# Returns 1 if no previous branch is recorded.
function git::worktree::get_previous {
  local previous_file

  previous_file="$(git::worktree::previous_file)" || return 1

  if [[ ! -f "${previous_file}" ]]; then
    return 1
  fi

  cat "${previous_file}"
}

# Resolve branch argument, handling '-' as previous branch.
# Usage: git::worktree::resolve_branch <branch>
# Outputs resolved branch name.
function git::worktree::resolve_branch {
  local branch="$1"

  if [[ "${branch}" == '-' ]]; then
    branch="$(git::worktree::get_previous)" || return 1
  fi

  echo "${branch}"
}

# Clone repository as a bare worktree structure.
# Creates: <directory>/__git__/.git (bare repo) and <directory>/<main-branch> (worktree)
# Sets up remote tracking and branch upstream for git rebase/pull to work.
# Usage: git::worktree::clone <repository> [directory]
function git::worktree::clone {
  local \
    repository="$1" \
    directory="$2" \
    default_remote \
    main_ref \
    main_branch

  if [[ -z "${repository}" ]]; then
    git::logger::error 'No repository url provided - exiting'
    return 1
  fi

  if ! git::url::is_valid "${repository}"; then
    git::logger::error "Invalid repository url provided: '${repository}' - exiting"
    return 1
  fi

  git::logger::info "Cloning repository: '${repository}' as bare worktree"

  if [[ -z "${directory}" ]]; then
    directory="$(git::url::repo_name "${repository}")"
    git::logger::info "No directory provided - using repository name as directory: '${directory}'"
  fi

  if [[ -d "${directory}/__git__" ]]; then
    git::logger::error "Worktree structure already exists: '${directory}/__git__' - exiting"
    return 1
  fi

  if ! mkdir -p "${directory}"; then
    git::logger::error "Could not create base directory: '${directory}' - exiting"
    return 1
  fi

  if ! mkdir "${directory}/__git__"; then
    git::logger::error "Could not create git directory: '${directory}/__git__' - exiting"
    return 1
  fi

  git::logger::info "Created worktree directory structure: '${directory}'"

  if ! git clone --bare "${repository}" "${directory}/__git__/.git"; then
    git::logger::error "Could not clone repository: '${repository}' - exiting"
    return 1
  fi

  git::logger::info "Cloned bare repository to: '${directory}/__git__/.git'"

  # Configure remote tracking branches (bare clone doesn't set this up by default)
  default_remote="$(git::worktree::default_remote "${directory}/__git__")"

  git::logger::info "Configuring remote tracking for '${default_remote}'"

  git -C "${directory}/__git__" config "remote.${default_remote}.fetch" "+refs/heads/*:refs/remotes/${default_remote}/*"
  git -C "${directory}/__git__" fetch "${default_remote}"

  # Derive the main ref from the cloned repository
  if ! main_ref="$(git::utility::get_main_ref "${default_remote}" "${directory}/__git__")"; then
    git::logger::error "Could not find main ref for repository: '${repository}' - exiting"
    return 1
  fi

  # Extract branch name from ref (e.g., "origin/main" -> "main")
  main_branch="${main_ref##*/}"

  git::logger::info "Found main branch: '${main_branch}' - creating worktree"

  # Create worktree for main branch
  if ! git -C "${directory}/__git__" worktree add "../${main_branch}" "${main_branch}"; then
    git::logger::error "Could not create main worktree for branch: '${main_branch}' - exiting"
    return 1
  fi

  # Set up branch tracking so git rebase/pull work without arguments
  git -C "${directory}/${main_branch}" branch --set-upstream-to="${default_remote}/${main_branch}" "${main_branch}"

  git::logger::info "Worktree setup complete: '${directory}/${main_branch}'"
}

# Clone repository as bare worktree and cd into the main worktree.
# Usage: git::worktree::clone::cd <repository> [directory]
function git::worktree::clone::cd {
  local \
    repository="$1" \
    directory="$2" \
    default_remote \
    main_ref \
    main_branch

  if ! git::worktree::clone "$@"; then
    return 1
  fi

  # Re-derive directory and main_branch for cd
  if [[ -z "${directory}" ]]; then
    directory="$(git::url::repo_name "${repository}")"
  fi

  default_remote="$(git::worktree::default_remote "${directory}/__git__")"
  if ! main_ref="$(git::utility::get_main_ref "${default_remote}" "${directory}/__git__")"; then
    git::logger::error 'Could not determine main worktree path'
    return 1
  fi

  main_branch="${main_ref##*/}"

  git::logger::info "Changing directory to: '${directory}/${main_branch}'"
  cd "${directory}/${main_branch}" || return 1
}

# Create or attach a feature worktree.
# Routes to git::worktree::add::existing or git::worktree::add::new based on -b flag.
# Other args are passed through transparently.
# Usage: git::worktree::add <branch>
#        git::worktree::add -b|--branch <branch> [start-point]
function git::worktree::add {
  local \
    create_branch=0 \
    args=()

  while (( $# > 0 )); do
    case "$1" in
      -b|--branch)
        create_branch=1
        ;;
      *)
        args+=("$1")
        ;;
    esac
    shift
  done

  if (( create_branch )); then
    git::worktree::add::new "${args[@]}"
  else
    git::worktree::add::existing "${args[@]}"
  fi
}

# Shared setup for worktree add operations.
# Checks if worktree already exists.
# Sets worktree_dir and worktree_absolute_path variables in caller's scope.
# Returns 0 if setup successful and should proceed, 1 if error, 2 if worktree exists.
function git::worktree::add::setup {
  local branch="$1"

  # Set in caller's scope (not local to this function)
  worktree_dir="../${branch}"
  worktree_absolute_path="${PWD%/*}/${branch}"

  # If a worktree already uses this path, no-op
  if git worktree list --porcelain | grep -q "^worktree ${worktree_absolute_path}$"; then
    git::logger::info "Worktree already exists at: '${worktree_dir}'"
    return 2
  fi

  return 0
}

# Create worktree for an existing branch.
# Fails if branch doesn't exist (local or remote).
# Usage: git::worktree::add::existing <branch> [git-worktree-args...]
function git::worktree::add::existing {
  local \
    branch="$1" \
    default_remote \
    setup_result \
    worktree_dir \
    worktree_absolute_path

  shift

  if [[ -z "${branch}" ]]; then
    git::logger::error 'usage: git::worktree::add::existing <branch> [git-worktree-args...]'
    return 1
  fi

  git::worktree::add::setup "${branch}"
  setup_result=$?

  if (( setup_result == 1 )); then
    return 1
  elif (( setup_result == 2 )); then
    return 0
  fi

  git::logger::info "Creating worktree for branch: '${branch}'"

  if ! git worktree add "${worktree_dir}" "${branch}" "$@"; then
    git::logger::error "Branch '${branch}' not found - use -b/--branch to create a new branch"
    return 1
  fi

  # Set up branch tracking if remote branch exists
  default_remote="$(git::worktree::default_remote)"
  if git show-ref --quiet "refs/remotes/${default_remote}/${branch}"; then
    git -C "${worktree_dir}" branch --set-upstream-to="${default_remote}/${branch}" "${branch}"
  fi
}

# Create worktree with a new branch.
# Creates branch from start-point (defaults to main ref).
# Usage: git::worktree::add::new <branch> [start-point] [git-worktree-args...]
function git::worktree::add::new {
  local \
    branch="$1" \
    start_point="$2" \
    default_remote \
    setup_result \
    worktree_dir \
    worktree_absolute_path

  shift
  (( $# > 0 )) && shift

  if [[ -z "${branch}" ]]; then
    git::logger::error 'usage: git::worktree::add::new <branch> [start-point] [git-worktree-args...]'
    return 1
  fi

  git::worktree::add::setup "${branch}"
  setup_result=$?

  if (( setup_result == 1 )); then
    return 1
  elif (( setup_result == 2 )); then
    return 0
  fi

  if [[ -z "${start_point}" ]]; then
    default_remote="$(git::worktree::default_remote)"

    if ! start_point="$(git::utility::get_main_ref "${default_remote}")"; then
      git::logger::error "Could not determine main ref for remote: '${default_remote}' - exiting"
      return 1
    fi

    git::logger::info "No start point provided - using: '${start_point}'"
  fi

  git::logger::info "Creating new branch '${branch}' from '${start_point}'"
  git worktree add --branch "${branch}" "${worktree_dir}" "${start_point}" "$@"
}

# Create or attach a feature worktree and cd into it.
# Routes to git::worktree::checkout::existing or git::worktree::checkout::new based on -b flag.
# Other args are passed through transparently.
# Usage: git::worktree::checkout <branch>
#        git::worktree::checkout -b|--branch <branch> [start-point]
function git::worktree::checkout {
  local \
    create_branch=0 \
    args=()

  while (( $# > 0 )); do
    case "$1" in
      -b|--branch)
        create_branch=1
        ;;
      *)
        args+=("$1")
        ;;
    esac
    shift
  done

  if (( create_branch )); then
    git::worktree::checkout::new "${args[@]}"
  else
    git::worktree::checkout::existing "${args[@]}"
  fi
}

# Checkout existing branch worktree and cd into it.
# Supports '-' to checkout the previous worktree (like git checkout -).
# Fails if branch doesn't exist.
# Usage: git::worktree::checkout::existing <branch>
function git::worktree::checkout::existing {
  local branch="$1"

  if [[ -z "${branch}" ]]; then
    git::logger::error 'usage: git::worktree::checkout::existing <branch>'
    return 1
  fi

  # Resolve '-' to previous branch
  if ! branch="$(git::worktree::resolve_branch "${branch}")"; then
    git::logger::error 'No previous worktree recorded'
    return 1
  fi

  local worktree_dir="../${branch}"

  if ! git::worktree::add::existing "${branch}"; then
    return 1
  fi

  # Save current branch before changing directory
  git::worktree::save_previous

  git::logger::info "Changing directory to: '${worktree_dir}'"
  cd "${worktree_dir}" || return 1
}

# Create new branch worktree and cd into it.
# Usage: git::worktree::checkout::new <branch> [start-point]
function git::worktree::checkout::new {
  local branch="$1"

  if [[ -z "${branch}" ]]; then
    git::logger::error 'usage: git::worktree::checkout::new <branch> [start-point]'
    return 1
  fi

  local worktree_dir="../${branch}"

  if ! git::worktree::add::new "$@"; then
    return 1
  fi

  # Save current branch before changing directory
  git::worktree::save_previous

  git::logger::info "Changing directory to: '${worktree_dir}'"
  cd "${worktree_dir}" || return 1
}
