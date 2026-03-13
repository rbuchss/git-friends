#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/exec.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/utility.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/worktree.sh"

git::__module__::load || return 0

# Move files and directories from source to destination, skipping named entries.
# Handles regular files, hidden files, and symlinks.
# Usage: git::layout::__move_contents__ <src> <dst> [skip_names...]
function git::layout::__move_contents__ {
  local src="$1" dst="$2"
  shift 2
  local skip_names=("$@")

  local item basename skip skip_name
  for item in "${src}"/* "${src}"/.[!.]* "${src}"/..?*; do
    [[ -e "${item}" || -L "${item}" ]] || continue
    basename="${item##*/}"

    skip=0
    for skip_name in "${skip_names[@]}"; do
      if [[ "${basename}" == "${skip_name}" ]]; then
        skip=1
        break
      fi
    done
    ((skip)) && continue

    mv "${item}" "${dst}/"
  done
}

# Convert a normal git clone to a bare worktree structure.
# Creates: <root>/__git__/.git (bare) and <root>/<branch>/ (worktree)
# Requires a clean working tree.
# Usage: git::layout::to_worktree
function git::layout::to_worktree {
  local \
    root \
    branch \
    remote \
    tmp_dir

  if ! root="$(git::exec rev-parse --show-toplevel 2>/dev/null)"; then
    git::logger::error 'Not inside a git repository'
    return 1
  fi

  if [[ -d "${root}/__git__" ]]; then
    git::logger::error 'Already a bare worktree structure'
    return 1
  fi

  if git::utility::is_bare; then
    git::logger::error 'Repository is already bare'
    return 1
  fi

  if git::utility::is_worktree; then
    git::logger::error 'Already inside a worktree linked to a bare repository'
    return 1
  fi

  # Exclude __context__ before the clean check so a preserved context
  # directory from a prior conversion does not appear as untracked.
  if [[ -d "${root}/__context__" ]]; then
    local exclude_file="${root}/.git/info/exclude"
    mkdir -p "${root}/.git/info"
    if ! grep -qFx '__context__' "${exclude_file}" 2>/dev/null; then
      echo '__context__' >>"${exclude_file}"
    fi
  fi

  if [[ -n "$(git::exec status --porcelain 2>/dev/null)" ]]; then
    git::logger::error 'Working tree is not clean - commit or stash changes first'
    return 1
  fi

  if ! branch="$(git::exec branch --show-current 2>/dev/null)" || [[ -z "${branch}" ]]; then
    git::logger::error 'Could not determine current branch (detached HEAD?)'
    return 1
  fi

  remote="$(git::worktree::default_remote)"

  if ! git::utility::ask "Convert '${root}' from normal clone to bare worktree structure?"; then
    return 0
  fi

  git::logger::info 'Converting to bare worktree structure...'

  if ! mkdir "${root}/__git__"; then
    git::logger::error "Could not create '${root}/__git__'"
    return 1
  fi

  mv "${root}/.git" "${root}/__git__/.git"

  # Configure as bare and set remote fetch refspec
  git::exec -C "${root}/__git__" config --bool core.bare true
  git::exec -C "${root}/__git__" config "remote.${remote}.fetch" \
    "+refs/heads/*:refs/remotes/${remote}/*"

  # Stash working tree files in a temp directory
  tmp_dir="${root}/.git-friends-layout-tmp"
  mkdir "${tmp_dir}"

  git::layout::__move_contents__ "${root}" "${tmp_dir}" \
    '__git__' '.git-friends-layout-tmp' '__context__'

  # Create worktree for the current branch
  if ! git::exec -C "${root}/__git__" worktree add "../${branch}" "${branch}"; then
    git::logger::error 'Failed to create worktree - rolling back'
    git::layout::__move_contents__ "${tmp_dir}" "${root}"
    rm -rf "${tmp_dir}"
    mv "${root}/__git__/.git" "${root}/.git"
    git::exec config --bool core.bare false
    rm -rf "${root}/__git__"
    return 1
  fi

  rm -rf "${tmp_dir}"

  # Set upstream tracking if remote branch exists
  if git::exec -C "${root}/${branch}" show-ref \
    --quiet "refs/remotes/${remote}/${branch}" 2>/dev/null; then
    git::exec -C "${root}/${branch}" branch \
      --set-upstream-to="${remote}/${branch}" "${branch}"
  fi

  git::worktree::init_context "${root}/${branch}"

  git::logger::info "Converted to bare worktree: '${root}/${branch}'"
}

# Convert a normal clone to bare worktree and cd into the main worktree.
# Usage: git::layout::to_worktree::cd
function git::layout::to_worktree::cd {
  local root branch

  root="$(git::exec rev-parse --show-toplevel 2>/dev/null)" || return 1
  branch="$(git::exec branch --show-current 2>/dev/null)" || return 1

  if ! git::layout::to_worktree; then
    return 1
  fi

  git::logger::info "Changing directory to: '${root}/${branch}'"
  cd "${root}/${branch}" || return 1
}

# Convert a bare worktree structure back to a normal git clone.
# Must have exactly one worktree (besides the bare __git__ entry).
# Requires a clean working tree.
# Usage: git::layout::to_clone
function git::layout::to_clone {
  local \
    git_common_dir \
    project_root \
    branch \
    worktree_path \
    worktree_count=0 \
    worktree_paths=()

  if ! git_common_dir="$(git::exec rev-parse --git-common-dir 2>/dev/null)"; then
    git::logger::error 'Not inside a git repository'
    return 1
  fi

  project_root="${git_common_dir%/__git__/.git}"

  if [[ "${project_root}" == "${git_common_dir}" ]]; then
    git::logger::error 'Not inside a bare worktree structure (expected __git__/.git layout)'
    return 1
  fi

  if [[ -n "$(git::exec status --porcelain 2>/dev/null)" ]]; then
    git::logger::error 'Working tree is not clean - commit or stash changes first'
    return 1
  fi

  if ! branch="$(git::exec branch --show-current 2>/dev/null)" || [[ -z "${branch}" ]]; then
    git::logger::error 'Could not determine current branch (detached HEAD?)'
    return 1
  fi

  # Count non-bare worktrees
  while IFS= read -r worktree_path; do
    [[ "${worktree_path}" == */__git__ ]] && continue
    worktree_paths+=("${worktree_path}")
    worktree_count=$((worktree_count + 1))
  done < <(git::exec worktree list --porcelain | sed -n 's/^worktree //p')

  if ((worktree_count == 0)); then
    git::logger::error 'No worktrees found'
    return 1
  fi

  if ((worktree_count > 1)); then
    git::logger::error "Multiple worktrees exist (${worktree_count}) - remove extras before converting:"
    local wt
    for wt in "${worktree_paths[@]}"; do
      git::logger::error "  ${wt}"
    done
    return 1
  fi

  worktree_path="${worktree_paths[0]}"

  if ! git::utility::ask "Convert '${project_root}' from bare worktree to normal clone?"; then
    return 0
  fi

  git::logger::info 'Converting to normal clone...'

  # Remove the worktree .git pointer file
  rm -f "${worktree_path}/.git"

  # Remove all worktree registrations (safe since we verified only one exists)
  rm -rf "${project_root}/__git__/.git/worktrees"

  # Unset bare mode
  git::exec --git-dir="${project_root}/__git__/.git" config --bool core.bare false

  # Move .git to project root
  mv "${project_root}/__git__/.git" "${project_root}/.git"
  rm -rf "${project_root}/__git__"

  # Move worktree files to project root (skip __context__ symlink)
  git::layout::__move_contents__ "${worktree_path}" "${project_root}" '__context__'

  # Clean up worktree directory
  rm -rf "${worktree_path}"

  # Reset index to match working tree
  git::exec -C "${project_root}" reset 2>/dev/null

  git::logger::info "Converted to normal clone: '${project_root}'"
}

# Convert bare worktree to normal clone and cd into the repo root.
# Usage: git::layout::to_clone::cd
function git::layout::to_clone::cd {
  local git_common_dir project_root

  git_common_dir="$(git::exec rev-parse --git-common-dir 2>/dev/null)" || return 1
  project_root="${git_common_dir%/__git__/.git}"

  if ! git::layout::to_clone; then
    return 1
  fi

  git::logger::info "Changing directory to: '${project_root}'"
  cd "${project_root}" || return 1
}

function git::layout::__export__ {
  export -f git::layout::to_worktree
  export -f git::layout::to_worktree::cd
  export -f git::layout::to_clone
  export -f git::layout::to_clone::cd
}

# KCOV_EXCL_START
function git::layout::__recall__ {
  export -fn git::layout::to_worktree
  export -fn git::layout::to_worktree::cd
  export -fn git::layout::to_clone
  export -fn git::layout::to_clone::cd
}
# KCOV_EXCL_STOP

git::__module__::export
