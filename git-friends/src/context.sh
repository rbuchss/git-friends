#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/exec.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/config.sh"

git::__module__::load || return 0

# Bypass any shell wrappers for rsync and ssh.
# Similar to git::exec using 'command git', these ensure we get the real
# binaries and not user-defined functions/aliases that add extra flags.
function git::context::__rsync__ {
  command rsync "$@"
}

function git::context::__ssh__ {
  command ssh -T "$@"
}

# Show a unified diff between two files on stderr with labels.
# Color mode: auto (enable on TTY, default), always (force on), never (force off).
# Usage: git::context::__diff__ <label> <local_file> <remote_file> [color]
function git::context::__diff__ {
  local \
    label="$1" \
    local_file="$2" \
    remote_file="$3" \
    color="${4:-auto}" \
    use_color=0
  local diff_args=('-u' '-L' "local: ${label}" '-L' "remote: ${label}")

  case "${color}" in
    always) use_color=1 ;;
    never) use_color=0 ;;
    auto | *) [[ -t 2 ]] && use_color=1 ;;
  esac

  if ((use_color)) \
    && command diff --color=always /dev/null /dev/null &>/dev/null; then
    diff_args=('--color=always' "${diff_args[@]}")
  fi

  command diff "${diff_args[@]}" "${local_file}" "${remote_file}" >&2 || true
}

# Locate the __context__ directory from anywhere inside a bare worktree structure.
# Prints the absolute path to __context__ on stdout.
# Usage: git::context::__find_dir__
function git::context::__find_dir__ {
  local \
    git_common_dir \
    project_root \
    context_dir

  git_common_dir="$(git::exec rev-parse --git-common-dir 2>/dev/null)" || {
    git::logger::error 'Not inside a git repository'
    return 1
  }

  project_root="${git_common_dir%/__git__/.git}"

  if [[ "${project_root}" == "${git_common_dir}" ]]; then
    git::logger::error 'Not inside a bare worktree structure (expected __git__/.git layout)'
    return 1
  fi

  context_dir="${project_root}/__context__"

  if [[ ! -d "${context_dir}" ]]; then
    git::logger::error "No __context__ directory found. Run 'git init-context' first"
    return 1
  fi

  echo "${context_dir}"
}

# Parse a remote spec into host and path components.
# Sets remote_host and remote_path in the caller's scope.
# Supports two forms:
#   user@host:/path/to/project  - explicit remote project root
#   user@host                   - assumes same path as local
# Usage: git::context::__parse_remote__ <remote_spec> <local_context_dir>
function git::context::__parse_remote__ {
  local \
    remote_spec="$1" \
    local_context_dir="$2"

  if [[ -z "${remote_spec}" ]]; then
    git::logger::error 'No remote specified'
    return 1
  fi

  # SCP-like syntax: user@host:/path or host:/path
  if [[ "${remote_spec}" == *:* ]]; then
    remote_host="${remote_spec%%:*}"
    remote_path="${remote_spec#*:}/__context__/"
  else
    # Host only: assume same project path on remote
    remote_host="${remote_spec}"
    remote_path="${local_context_dir%/}/"
  fi
}

# One-way push: sync local context to remote.
# Uses --update to skip files newer on the remote.
# Usage: git::context::push <local_path> <remote_host> <remote_path>
function git::context::push {
  local \
    local_path="$1" \
    remote_host="$2" \
    remote_path="$3"

  git::logger::info "Pushing context to '${remote_host}:${remote_path}'"

  # Ensure remote directory exists
  git::context::__ssh__ "${remote_host}" "mkdir -p '${remote_path}'"

  git::context::__rsync__ -avz --update --exclude='.DS_Store' -e 'ssh -T' \
    "${local_path}" "${remote_host}:${remote_path}"
}

# One-way pull: sync remote context to local.
# Uses --update to skip files newer locally.
# Usage: git::context::pull <local_path> <remote_host> <remote_path>
function git::context::pull {
  local \
    local_path="$1" \
    remote_host="$2" \
    remote_path="$3"

  git::logger::info "Pulling context from '${remote_host}:${remote_path}'"
  git::context::__rsync__ -avz --update --exclude='.DS_Store' -e 'ssh -T' \
    "${remote_host}:${remote_path}" "${local_path}"
}

# Resolve a single conflicting file interactively.
# Fetches the remote copy, shows a diff (or metadata for binary files),
# and prompts the user to choose a resolution.
# Usage: git::context::__resolve_conflict__ <file> <local_path> <remote_host> <remote_path> [color]
function git::context::__resolve_conflict__ {
  local \
    file="$1" \
    local_path="$2" \
    remote_host="$3" \
    remote_path="$4" \
    color="${5:-auto}" \
    tmp_file \
    choice \
    is_binary=0

  tmp_file="$(mktemp)"

  # Fetch remote copy to temp file
  if ! git::context::__ssh__ "${remote_host}" "cat '${remote_path}${file}'" >"${tmp_file}" 2>/dev/null; then
    git::logger::error "Failed to fetch remote file: '${file}'"
    rm -f "${tmp_file}"
    return 1
  fi

  # Detect binary files
  if file --mime-encoding "${local_path}${file}" 2>/dev/null | grep -q 'binary'; then
    is_binary=1
  fi

  git::logger::warning "Conflict: '${file}'"

  # Show initial diff or metadata
  if ((is_binary)); then
    local \
      local_size \
      remote_size
    local_size="$(stat -c '%s' "${local_path}${file}" 2>/dev/null \
      || stat -f '%z' "${local_path}${file}" 2>/dev/null \
      || echo 'unknown')"
    remote_size="$(git::context::__ssh__ "${remote_host}" \
      "stat -c '%s' '${remote_path}${file}' 2>/dev/null \
        || stat -f '%z' '${remote_path}${file}' 2>/dev/null \
        || echo 'unknown'")"
    echo "  Binary file" >&2
    echo "  Local size:  ${local_size} bytes" >&2
    echo "  Remote size: ${remote_size} bytes" >&2
  else
    git::context::__diff__ "${file}" "${local_path}${file}" "${tmp_file}" "${color}"
  fi

  while true; do
    read -r -p "  (l)ocal / (r)emote / (b)oth / (s)kip / (d)iff ? " choice </dev/tty

    case "${choice}" in
      l)
        git::context::__rsync__ -az -e 'ssh -T' "${local_path}${file}" "${remote_host}:${remote_path}${file}"
        git::logger::info "Kept local version of '${file}'"
        break
        ;;
      r)
        command cp "${tmp_file}" "${local_path}${file}"
        git::logger::info "Kept remote version of '${file}'"
        break
        ;;
      b)
        # Local side gets a .remote copy, remote side gets a .local copy
        command cp "${tmp_file}" "${local_path}${file}.remote"
        git::context::__rsync__ -az -e 'ssh -T' "${local_path}${file}" "${remote_host}:${remote_path}${file}.local"
        git::logger::info "Kept both versions of '${file}' (added .local and .remote copies)"
        break
        ;;
      s)
        git::logger::info "Skipped '${file}'"
        break
        ;;
      d)
        if ((is_binary)); then
          echo "  Binary file, cannot show diff" >&2
        else
          git::context::__diff__ "${file}" "${local_path}${file}" "${tmp_file}" "${color}"
        fi
        ;;
      *)
        echo "  Invalid choice. Use (l)ocal, (r)emote, (b)oth, (s)kip, or (d)iff" >&2
        ;;
    esac
  done

  rm -f "${tmp_file}"
}

# Bidirectional sync with conflict prompting.
# Auto-copies files unique to one side, then prompts for files that differ.
# Usage: git::context::merge <local_path> <remote_host> <remote_path> [color]
function git::context::merge {
  local \
    local_path="$1" \
    remote_host="$2" \
    remote_path="$3" \
    color="${4:-auto}" \
    conflicts

  # Ensure remote directory exists
  git::context::__ssh__ "${remote_host}" "mkdir -p '${remote_path}'"

  git::logger::info "Syncing new files"

  # Push local-only files (--ignore-existing won't overwrite remote files)
  git::context::__rsync__ -avz --ignore-existing --exclude='.DS_Store' -e 'ssh -T' \
    "${local_path}" "${remote_host}:${remote_path}"

  # Pull remote-only files (--ignore-existing won't overwrite local files)
  git::context::__rsync__ -avz --ignore-existing --exclude='.DS_Store' -e 'ssh -T' \
    "${remote_host}:${remote_path}" "${local_path}"

  # Detect remaining differences (files on both sides with different content)
  git::logger::info "Checking for conflicts"
  conflicts="$(git::context::__rsync__ -rnc --out-format='%n' --exclude='.DS_Store' -e 'ssh -T' \
    "${local_path}" "${remote_host}:${remote_path}" 2>/dev/null \
    | grep -v '/$' || true)"

  if [[ -z "${conflicts}" ]]; then
    git::logger::info "All files synced, no conflicts"
    return 0
  fi

  git::logger::warning "Found conflicts:"

  # Drain conflicts into an array first, then iterate. This avoids having
  # ssh/rsync inside __resolve_conflict__ consume filenames from stdin.
  local -a files=()
  local file
  while IFS= read -r file; do
    [[ -n "${file}" ]] && files+=("${file}")
  done <<<"${conflicts}"

  for file in "${files[@]}"; do
    git::context::__resolve_conflict__ "${file}" "${local_path}" "${remote_host}" "${remote_path}" "${color}"
  done

  git::logger::info "Sync complete"
}

# Read the saved remote spec from git config.
# Prints the spec on stdout, empty if unset. Always returns 0 so callers
# can use `var="$(...)"` cleanly without errexit headaches.
# Usage: git::context::__get_saved_remote__
function git::context::__get_saved_remote__ {
  git::config::get 'sync-context.remote' 2>/dev/null || true
}

# Save the remote spec to git config (local scope = bare repo's config).
# Usage: git::context::__save_remote__ <spec>
function git::context::__save_remote__ {
  local spec="$1"
  git::exec config 'sync-context.remote' "${spec}"
}

# Set the saved remote spec with diff-aware logging.
# - First save: logs "Saved remote ..."
# - Override: logs "Updated saved remote from ... to ..."
# - Same as previous: silent (no-op log)
# Used by both --set and the auto-save-on-success block.
# Usage: git::context::__set_remote__ <spec>
function git::context::__set_remote__ {
  local \
    spec="$1" \
    previous
  previous="$(git::context::__get_saved_remote__)"
  git::context::__save_remote__ "${spec}"
  if [[ -z "${previous}" ]]; then
    git::logger::info "Saved remote '${spec}' to sync-context.remote"
  elif [[ "${previous}" != "${spec}" ]]; then
    git::logger::info "Updated saved remote from '${previous}' to '${spec}'"
  fi
}

# Clear the saved remote spec. Idempotent: silent-success when nothing saved.
# Usage: git::context::__unset_remote__
function git::context::__unset_remote__ {
  local saved
  saved="$(git::context::__get_saved_remote__)"
  if [[ -z "${saved}" ]]; then
    git::logger::info 'No saved remote to unset'
    return 0
  fi
  git::exec config --unset 'sync-context.remote'
  git::logger::info "Unset saved remote '${saved}'"
}

# Print the saved remote spec to stdout.
# Returns 0 when set, 1 when unset (matches `git config --get` semantics).
# Usage: git::context::__show_remote__
function git::context::__show_remote__ {
  local saved
  saved="$(git::context::__get_saved_remote__)"
  if [[ -z "${saved}" ]]; then
    return 1
  fi
  echo "${saved}"
}

# Sync the __context__ directory with a remote host.
# Bidirectional by default with conflict prompting. The remote spec is
# saved to git config (sync-context.remote) on success and reused when
# omitted on subsequent invocations.
# Usage: git::context::sync [--push|--pull] [--color|--no-color] [<user@host[:path]>]
function git::context::sync {
  local \
    mode='merge' \
    color='auto' \
    source_was_cli=0 \
    sync_status=0 \
    action='' \
    remote_spec \
    set_spec \
    local_path \
    remote_host \
    remote_path

  while (($# > 0)); do
    case "$1" in
      --push) mode='push' ;;
      --pull) mode='pull' ;;
      --color) color='always' ;;
      --no-color) color='never' ;;
      --set)
        shift
        if (($# == 0)); then
          git::logger::error '--set requires a remote spec'
          return 1
        fi
        action='set'
        set_spec="$1"
        ;;
      --unset) action='unset' ;;
      --show) action='show' ;;
      -*)
        git::logger::error "Unknown option: '$1'"
        return 1
        ;;
      *)
        if [[ -n "${remote_spec}" ]]; then
          git::logger::error "Unexpected argument: '$1'"
          return 1
        fi
        remote_spec="$1"
        source_was_cli=1
        ;;
    esac
    shift
  done

  # Management actions are terminal: short-circuit before sync logic.
  case "${action}" in
    set)
      git::context::__set_remote__ "${set_spec}"
      return $?
      ;;
    unset)
      git::context::__unset_remote__
      return $?
      ;;
    show)
      git::context::__show_remote__
      return $?
      ;;
  esac

  # Fall back to saved remote when none given on the CLI
  if [[ -z "${remote_spec}" ]]; then
    remote_spec="$(git::context::__get_saved_remote__)"
    if [[ -n "${remote_spec}" ]]; then
      git::logger::info "Using saved remote '${remote_spec}'"
    fi
  fi

  if [[ -z "${remote_spec}" ]]; then
    git::logger::error 'usage: git sync-context [--push|--pull] [--color|--no-color] [<user@host[:path]>]'
    git::logger::error 'No remote saved. Pass one once to set the default.'
    return 1
  fi

  if ! local_path="$(git::context::__find_dir__)"; then
    return 1
  fi
  local_path="${local_path%/}/"

  git::context::__parse_remote__ "${remote_spec}" "${local_path}"

  # Fail fast if the remote project root doesn't exist.
  # When using an implicit path (host-only form), try swapping the home
  # directory prefix between macOS (/Users) and Linux (/home) before failing.
  local \
    remote_project_root="${remote_path%__context__/}" \
    fallback_root
  if ! git::context::__ssh__ "${remote_host}" "test -d '${remote_project_root}'"; then
    case "${remote_project_root}" in
      /Users/*) fallback_root="/home/${remote_project_root#/Users/}" ;;
      /home/*) fallback_root="/Users/${remote_project_root#/home/}" ;;
    esac

    if [[ -n "${fallback_root}" ]] \
      && git::context::__ssh__ "${remote_host}" "test -d '${fallback_root}'"; then
      git::logger::info "Resolved remote path to '${fallback_root}__context__/'"
      remote_path="${fallback_root}__context__/"
    else
      git::logger::error "Remote project root does not exist: '${remote_host}:${remote_project_root}'"
      return 1
    fi
  fi

  git::logger::info "Syncing context (${mode}) with '${remote_host}'"

  case "${mode}" in
    push) git::context::push "${local_path}" "${remote_host}" "${remote_path}" || sync_status=$? ;;
    pull) git::context::pull "${local_path}" "${remote_host}" "${remote_path}" || sync_status=$? ;;
    merge) git::context::merge "${local_path}" "${remote_host}" "${remote_path}" "${color}" || sync_status=$? ;;
  esac

  if ((sync_status == 0)) && ((source_was_cli)); then
    git::context::__set_remote__ "${remote_spec}"
  fi

  return "${sync_status}"
}

function git::context::__export__ {
  export -f git::context::sync
  export -f git::context::push
  export -f git::context::pull
  export -f git::context::merge
}

# KCOV_EXCL_START
function git::context::__recall__ {
  export -fn git::context::sync
  export -fn git::context::push
  export -fn git::context::pull
  export -fn git::context::merge
}
# KCOV_EXCL_STOP

git::__module__::export
