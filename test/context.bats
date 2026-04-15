#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load test_helper

setup_with_coverage 'git-friends/src/context.sh'

# Helper to create a cloned repo (non-bare) with remote tracking.
# Sets repo_dir in caller's scope.
__create_cloned_repo() {
  local source_dir="${BATS_TEST_TMPDIR}/source"

  repo_dir="${BATS_TEST_TMPDIR}/cloned"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  git clone "${source_dir}" "${repo_dir}"
}

# Helper to create a bare worktree structure (like git::worktree::clone produces).
# Sets bare_dir, worktree_dir, and branch in caller's scope.
__create_bare_worktree_structure() {
  local source_dir="${BATS_TEST_TMPDIR}/source"

  bare_dir="${BATS_TEST_TMPDIR}/project/__git__/.git"
  worktree_dir="${BATS_TEST_TMPDIR}/project"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  mkdir -p "${BATS_TEST_TMPDIR}/project/__git__"
  mkdir "${BATS_TEST_TMPDIR}/project/__context__"
  git clone --bare "${source_dir}" "${bare_dir}"

  # Exclude __context__ symlinks from git status
  mkdir -p "${bare_dir}/info"
  echo '__context__' >>"${bare_dir}/info/exclude"

  # Configure remote tracking
  git -C "${BATS_TEST_TMPDIR}/project/__git__" config \
    'remote.origin.fetch' '+refs/heads/*:refs/remotes/origin/*'
  git -C "${BATS_TEST_TMPDIR}/project/__git__" fetch origin

  branch="$(git --git-dir="${bare_dir}" symbolic-ref --short HEAD)"
  git -C "${BATS_TEST_TMPDIR}/project/__git__" worktree add \
    "../${branch}" "${branch}"

  git -C "${worktree_dir}/${branch}" branch \
    --set-upstream-to="origin/${branch}" "${branch}"
}

# Stub git::context::__rsync__ and git::context::__ssh__ with recording stubs.
# Records invocations to rsync_calls and ssh_calls files in BATS_TEST_TMPDIR.
__mock_rsync_ssh__() {
  git::context::__rsync__() {
    echo "$*" >>"${BATS_TEST_TMPDIR}/rsync_calls"
  }
  export -f git::context::__rsync__

  git::context::__ssh__() {
    echo "$*" >>"${BATS_TEST_TMPDIR}/ssh_calls"
  }
  export -f git::context::__ssh__
}

################################################################################
# git::context::__find_dir__
################################################################################

# bats test_tags=git::context::__find_dir__
@test "git::context::__find_dir__ finds __context__ from inside worktree" {
  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  # Resolve symlinks (macOS /var → /private/var)
  local expected
  expected="$(cd "${worktree_dir}" && pwd -P)/__context__"

  run git::context::__find_dir__
  assert_success
  assert_output "${expected}"
}

# bats test_tags=git::context::__find_dir__
@test "git::context::__find_dir__ fails outside a git repo" {
  cd "${BATS_TEST_TMPDIR}"

  run --separate-stderr git::context::__find_dir__
  assert_failure
  assert_stderr --partial 'Not inside a git repository'
}

# bats test_tags=git::context::__find_dir__
@test "git::context::__find_dir__ fails outside bare worktree structure" {
  __create_cloned_repo
  cd "${repo_dir}"

  run --separate-stderr git::context::__find_dir__
  assert_failure
  assert_stderr --partial 'Not inside a bare worktree structure'
}

# bats test_tags=git::context::__find_dir__
@test "git::context::__find_dir__ fails when __context__ dir does not exist" {
  __create_bare_worktree_structure
  rmdir "${worktree_dir}/__context__"
  cd "${worktree_dir}/${branch}"

  run --separate-stderr git::context::__find_dir__
  assert_failure
  assert_stderr --partial 'No __context__ directory found'
  assert_stderr --partial 'git init-context'
}

################################################################################
# git::context::__parse_remote__
################################################################################

# bats test_tags=git::context::__parse_remote__
@test "git::context::__parse_remote__ parses user@host:/path syntax" {
  local remote_host remote_path

  git::context::__parse_remote__ 'user@server:/home/user/myproject' '/local/__context__/'

  assert_equal "${remote_host}" 'user@server'
  assert_equal "${remote_path}" '/home/user/myproject/__context__/'
}

# bats test_tags=git::context::__parse_remote__
@test "git::context::__parse_remote__ uses local path when no colon" {
  local remote_host remote_path

  git::context::__parse_remote__ 'user@server' '/local/project/__context__/'

  assert_equal "${remote_host}" 'user@server'
  assert_equal "${remote_path}" '/local/project/__context__/'
}

# bats test_tags=git::context::__parse_remote__
@test "git::context::__parse_remote__ fails with empty remote spec" {
  local remote_host remote_path

  run --separate-stderr git::context::__parse_remote__ '' '/local/__context__/'
  assert_failure
  assert_stderr --partial 'No remote specified'
}

################################################################################
# git::context::__diff__
################################################################################

# bats test_tags=git::context::__diff__
@test "git::context::__diff__ outputs unified diff with labels" {
  echo 'line 1' >"${BATS_TEST_TMPDIR}/local.txt"
  echo 'line 2' >"${BATS_TEST_TMPDIR}/remote.txt"

  run --separate-stderr git::context::__diff__ 'notes.md' \
    "${BATS_TEST_TMPDIR}/local.txt" "${BATS_TEST_TMPDIR}/remote.txt" 'never'

  assert_success
  assert_stderr --partial 'local: notes.md'
  assert_stderr --partial 'remote: notes.md'
  assert_stderr --partial '-line 1'
  assert_stderr --partial '+line 2'
}

# bats test_tags=git::context::__diff__
@test "git::context::__diff__ returns success when files are identical" {
  echo 'same' >"${BATS_TEST_TMPDIR}/a.txt"
  echo 'same' >"${BATS_TEST_TMPDIR}/b.txt"

  run --separate-stderr git::context::__diff__ 'file' \
    "${BATS_TEST_TMPDIR}/a.txt" "${BATS_TEST_TMPDIR}/b.txt" 'never'

  assert_success
  refute_stderr
}

# bats test_tags=git::context::__diff__
@test "git::context::__diff__ never mode produces no ANSI escape codes" {
  echo 'a' >"${BATS_TEST_TMPDIR}/a.txt"
  echo 'b' >"${BATS_TEST_TMPDIR}/b.txt"

  run --separate-stderr git::context::__diff__ 'f' \
    "${BATS_TEST_TMPDIR}/a.txt" "${BATS_TEST_TMPDIR}/b.txt" 'never'

  assert_success
  # ANSI escape sequences start with ESC ([)
  refute_stderr --regexp $'\x1b\\['
}

# bats test_tags=git::context::__diff__
@test "git::context::__diff__ always mode includes ANSI codes when diff supports --color" {
  # Probe: does diff actually emit ANSI codes with --color=always?
  echo 'a' >"${BATS_TEST_TMPDIR}/probe_a.txt"
  echo 'b' >"${BATS_TEST_TMPDIR}/probe_b.txt"
  if ! command diff --color=always "${BATS_TEST_TMPDIR}/probe_a.txt" \
    "${BATS_TEST_TMPDIR}/probe_b.txt" 2>/dev/null \
    | grep -q $'\x1b\\['; then
    skip 'diff does not emit ANSI color codes'
  fi

  echo 'a' >"${BATS_TEST_TMPDIR}/a.txt"
  echo 'b' >"${BATS_TEST_TMPDIR}/b.txt"

  run --separate-stderr git::context::__diff__ 'f' \
    "${BATS_TEST_TMPDIR}/a.txt" "${BATS_TEST_TMPDIR}/b.txt" 'always'

  assert_success
  assert_stderr --regexp $'\x1b\\['
}

# bats test_tags=git::context::__diff__
@test "git::context::__diff__ auto mode produces no color when stderr is not a TTY" {
  echo 'a' >"${BATS_TEST_TMPDIR}/a.txt"
  echo 'b' >"${BATS_TEST_TMPDIR}/b.txt"

  # 'run' captures stderr, so stderr is not a TTY
  run --separate-stderr git::context::__diff__ 'f' \
    "${BATS_TEST_TMPDIR}/a.txt" "${BATS_TEST_TMPDIR}/b.txt" 'auto'

  assert_success
  refute_stderr --regexp $'\x1b\\['
}

# bats test_tags=git::context::__diff__
@test "git::context::__diff__ defaults to auto when color arg omitted" {
  echo 'a' >"${BATS_TEST_TMPDIR}/a.txt"
  echo 'b' >"${BATS_TEST_TMPDIR}/b.txt"

  run --separate-stderr git::context::__diff__ 'f' \
    "${BATS_TEST_TMPDIR}/a.txt" "${BATS_TEST_TMPDIR}/b.txt"

  assert_success
  refute_stderr --regexp $'\x1b\\['
}

################################################################################
# git::context::sync argument parsing
################################################################################

# bats test_tags=git::context::sync
@test "git::context::sync fails with no arguments" {
  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  run --separate-stderr git::context::sync
  assert_failure
  assert_stderr --partial 'usage:'
}

# bats test_tags=git::context::sync
@test "git::context::sync fails with unknown option" {
  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  run --separate-stderr git::context::sync --unknown host
  assert_failure
  assert_stderr --partial "Unknown option: '--unknown'"
}

# bats test_tags=git::context::sync
@test "git::context::sync fails fast when remote project root does not exist" {
  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  # ssh stub: 'test -d' always returns failure (no dir exists)
  git::context::__ssh__() { return 1; }
  export -f git::context::__ssh__

  run --separate-stderr git::context::sync --push user@host:/nonexistent/path
  assert_failure
  assert_stderr --partial 'Remote project root does not exist'
}

# bats test_tags=git::context::sync
@test "git::context::sync falls back from /Users to /home on implicit path" {
  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  # The local __context__ path will contain BATS_TEST_TMPDIR.
  # Override __find_dir__ to return a /Users-prefixed path so fallback triggers.
  git::context::__find_dir__() { echo '/Users/russ/Developer/myproject/__context__'; }
  export -f git::context::__find_dir__

  # ssh stub: first 'test -d' fails (/Users path), second succeeds (/home path)
  local ssh_call_num=0
  git::context::__ssh__() {
    echo "$*" >>"${BATS_TEST_TMPDIR}/ssh_calls"
    # 'test -d /Users/...' fails, 'test -d /home/...' succeeds, rest succeed
    if [[ "$*" == *"/Users/"* ]]; then
      return 1
    fi
    return 0
  }
  export -f git::context::__ssh__

  git::context::__rsync__() {
    echo "$*" >>"${BATS_TEST_TMPDIR}/rsync_calls"
  }
  export -f git::context::__rsync__

  run --separate-stderr git::context::sync --push user@host
  assert_success
  assert_stderr --partial 'Resolved remote path'
  assert_stderr --partial '/home/russ/Developer/myproject/__context__/'
}

# bats test_tags=git::context::sync
@test "git::context::sync falls back from /home to /Users on implicit path" {
  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  git::context::__find_dir__() { echo '/home/russ/Developer/myproject/__context__'; }
  export -f git::context::__find_dir__

  git::context::__ssh__() {
    if [[ "$*" == *"/home/"* ]]; then
      return 1
    fi
    return 0
  }
  export -f git::context::__ssh__

  git::context::__rsync__() { return 0; }
  export -f git::context::__rsync__

  run --separate-stderr git::context::sync --push user@host
  assert_success
  assert_stderr --partial '/Users/russ/Developer/myproject/__context__/'
}

# bats test_tags=git::context::sync
@test "git::context::sync forwards --color to merge" {
  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  git::context::__ssh__() { return 0; }
  export -f git::context::__ssh__

  git::context::__rsync__() { return 0; }
  export -f git::context::__rsync__

  # Capture the color value passed to merge (4th positional arg)
  git::context::merge() { echo "color=$4" >"${BATS_TEST_TMPDIR}/merge_color"; }
  export -f git::context::merge

  run git::context::sync --color user@host
  assert_success
  run cat "${BATS_TEST_TMPDIR}/merge_color"
  assert_output 'color=always'
}

# bats test_tags=git::context::sync
@test "git::context::sync forwards --no-color to merge" {
  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  git::context::__ssh__() { return 0; }
  export -f git::context::__ssh__

  git::context::merge() { echo "color=$4" >"${BATS_TEST_TMPDIR}/merge_color"; }
  export -f git::context::merge

  run git::context::sync --no-color user@host
  assert_success
  run cat "${BATS_TEST_TMPDIR}/merge_color"
  assert_output 'color=never'
}

# bats test_tags=git::context::sync
@test "git::context::sync defaults color to auto when no flag given" {
  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  git::context::__ssh__() { return 0; }
  export -f git::context::__ssh__

  git::context::merge() { echo "color=$4" >"${BATS_TEST_TMPDIR}/merge_color"; }
  export -f git::context::merge

  run git::context::sync user@host
  assert_success
  run cat "${BATS_TEST_TMPDIR}/merge_color"
  assert_output 'color=auto'
}

# bats test_tags=git::context::sync
@test "git::context::sync --push dispatches to push" {
  __create_bare_worktree_structure
  __mock_rsync_ssh__
  cd "${worktree_dir}/${branch}"

  run git::context::sync --push user@host
  assert_success

  # Verify rsync was called with --update (push mode)
  run cat "${BATS_TEST_TMPDIR}/rsync_calls"
  assert_output --partial '--update'
  assert_output --partial 'user@host:'
}

# bats test_tags=git::context::sync
@test "git::context::sync --pull dispatches to pull" {
  __create_bare_worktree_structure
  __mock_rsync_ssh__
  cd "${worktree_dir}/${branch}"

  run git::context::sync --pull user@host
  assert_success

  # Verify rsync was called with --update (pull mode)
  run cat "${BATS_TEST_TMPDIR}/rsync_calls"
  assert_output --partial '--update'
  assert_output --partial 'user@host:'
}

################################################################################
# git::context::push
################################################################################

# bats test_tags=git::context::push
@test "git::context::push creates remote dir and invokes rsync" {
  __mock_rsync_ssh__

  run git::context::push '/local/__context__/' 'user@host' '/remote/__context__/'
  assert_success

  # Verify ssh mkdir -p was called first
  run cat "${BATS_TEST_TMPDIR}/ssh_calls"
  assert_output --partial "user@host"
  assert_output --partial "mkdir -p"

  # Verify rsync was called with correct flags
  run cat "${BATS_TEST_TMPDIR}/rsync_calls"
  assert_output --partial '-avz'
  assert_output --partial '--update'
  assert_output --partial '--exclude=.DS_Store'
  assert_output --partial '/local/__context__/'
  assert_output --partial 'user@host:/remote/__context__/'
}

# bats test_tags=git::context::push
@test "git::context::push propagates rsync failure" {
  # Mock ssh to succeed (mkdir -p), mock rsync to fail
  git::context::__ssh__() { return 0; }
  export -f git::context::__ssh__
  git::context::__rsync__() { return 1; }
  export -f git::context::__rsync__

  run git::context::push '/local/__context__/' 'user@host' '/remote/__context__/'
  assert_failure
}

################################################################################
# git::context::pull
################################################################################

# bats test_tags=git::context::pull
@test "git::context::pull invokes rsync with correct flags and paths" {
  __mock_rsync_ssh__

  run git::context::pull '/local/__context__/' 'user@host' '/remote/__context__/'
  assert_success

  run cat "${BATS_TEST_TMPDIR}/rsync_calls"
  assert_output --partial '-avz'
  assert_output --partial '--update'
  assert_output --partial '--exclude=.DS_Store'
  assert_output --partial 'user@host:/remote/__context__/'
  assert_output --partial '/local/__context__/'
}

# bats test_tags=git::context::pull
@test "git::context::pull propagates rsync failure" {
  git::context::__rsync__() { return 1; }
  export -f git::context::__rsync__

  run git::context::pull '/local/__context__/' 'user@host' '/remote/__context__/'
  assert_failure
}

################################################################################
# git::context::merge
################################################################################

# bats test_tags=git::context::merge
@test "git::context::merge runs ignore-existing rsync in both directions" {
  __mock_rsync_ssh__

  run git::context::merge '/local/__context__/' 'user@host' '/remote/__context__/'
  assert_success

  # Verify both --ignore-existing calls present
  local ignore_count
  ignore_count="$(grep -c 'ignore-existing' "${BATS_TEST_TMPDIR}/rsync_calls")"
  assert_equal "${ignore_count}" 2
}

# bats test_tags=git::context::merge
@test "git::context::merge reports no conflicts when all files match" {
  __mock_rsync_ssh__

  run --separate-stderr git::context::merge '/local/__context__/' 'user@host' '/remote/__context__/'
  assert_success
  assert_stderr --partial 'no conflicts'
}

# bats test_tags=git::context::merge
@test "git::context::merge detects conflicts from dry-run output" {
  # Rsync stub: return conflict filenames only on dry-run checksum call
  git::context::__rsync__() {
    echo "$*" >>"${BATS_TEST_TMPDIR}/rsync_calls"
    if [[ "$*" == *"-rnc"* ]]; then
      echo "notes.md"
    fi
  }
  export -f git::context::__rsync__

  git::context::__ssh__() { return 0; }
  export -f git::context::__ssh__

  # Stub out __resolve_conflict__ since it needs /dev/tty
  git::context::__resolve_conflict__() {
    git::logger::info "Would resolve conflict for: '$1'"
  }
  export -f git::context::__resolve_conflict__

  run --separate-stderr git::context::merge \
    '/local/__context__/' 'user@host' '/remote/__context__/'
  assert_success
  assert_stderr --partial 'Found conflicts'
}

################################################################################
# git::context::sync remote persistence
################################################################################

# bats test_tags=git::context::sync
@test "git::context::sync saves remote spec on first successful run" {
  __create_bare_worktree_structure
  __mock_rsync_ssh__
  cd "${worktree_dir}/${branch}"

  run --separate-stderr git::context::sync --push 'user@host:/remote/proj'
  assert_success
  assert_stderr --partial "Saved remote 'user@host:/remote/proj' to sync-context.remote"

  run git --git-dir="${bare_dir}" config sync-context.remote
  assert_success
  assert_output 'user@host:/remote/proj'
}

# bats test_tags=git::context::sync
@test "git::context::sync uses saved remote when no arg given" {
  __create_bare_worktree_structure
  __mock_rsync_ssh__
  cd "${worktree_dir}/${branch}"

  git --git-dir="${bare_dir}" config sync-context.remote 'saved@host:/saved/path'

  run --separate-stderr git::context::sync
  assert_success
  assert_stderr --partial "Using saved remote 'saved@host:/saved/path'"

  run cat "${BATS_TEST_TMPDIR}/rsync_calls"
  assert_output --partial 'saved@host:/saved/path/__context__/'
}

# bats test_tags=git::context::sync
@test "git::context::sync errors when no arg and no saved remote" {
  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  run --separate-stderr git::context::sync
  assert_failure
  assert_stderr --partial 'No remote saved'
  assert_stderr --partial 'usage:'
}

# bats test_tags=git::context::sync
@test "git::context::sync arg overrides saved remote and re-saves on success" {
  __create_bare_worktree_structure
  __mock_rsync_ssh__
  cd "${worktree_dir}/${branch}"

  git --git-dir="${bare_dir}" config sync-context.remote 'old@host:/old/path'

  run --separate-stderr git::context::sync --push 'new@host:/new/path'
  assert_success
  assert_stderr --partial "Updated saved remote from 'old@host:/old/path' to 'new@host:/new/path'"

  run git --git-dir="${bare_dir}" config sync-context.remote
  assert_success
  assert_output 'new@host:/new/path'
}

# bats test_tags=git::context::sync
@test "git::context::sync does NOT save when remote root check fails" {
  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  # ssh stub: 'test -d' always returns failure (and no fallback path matches)
  git::context::__ssh__() { return 1; }
  export -f git::context::__ssh__

  run --separate-stderr git::context::sync --push 'user@host:/nonexistent'
  assert_failure

  run git --git-dir="${bare_dir}" config sync-context.remote
  assert_failure
}

# bats test_tags=git::context::sync
@test "git::context::sync does NOT save when push fails" {
  __create_bare_worktree_structure
  __mock_rsync_ssh__
  cd "${worktree_dir}/${branch}"

  # Override rsync to fail (overrides the mock from __mock_rsync_ssh__)
  git::context::__rsync__() { return 1; }
  export -f git::context::__rsync__

  run git::context::sync --push 'user@host:/remote/proj'
  assert_failure

  run git --git-dir="${bare_dir}" config sync-context.remote
  assert_failure
}

# bats test_tags=git::context::sync
@test "git::context::sync --push uses saved remote when no arg given" {
  __create_bare_worktree_structure
  __mock_rsync_ssh__
  cd "${worktree_dir}/${branch}"

  git --git-dir="${bare_dir}" config sync-context.remote 'pushuser@host:/p/path'

  run git::context::sync --push
  assert_success

  run cat "${BATS_TEST_TMPDIR}/rsync_calls"
  # --update is the push-mode rsync flag
  assert_output --partial '--update'
  assert_output --partial 'pushuser@host:/p/path/__context__/'
}

################################################################################
# git::context::sync --set / --unset / --show
################################################################################

# bats test_tags=git::context::sync
@test "git::context::sync --set saves spec without syncing" {
  __create_cloned_repo
  __mock_rsync_ssh__
  cd "${repo_dir}"

  run --separate-stderr git::context::sync --set 'me@host:/path'
  assert_success
  assert_stderr --partial "Saved remote 'me@host:/path' to sync-context.remote"

  run git --git-dir="${repo_dir}/.git" config sync-context.remote
  assert_success
  assert_output 'me@host:/path'
}

# bats test_tags=git::context::sync
@test "git::context::sync --set overwrites and logs update" {
  __create_cloned_repo
  cd "${repo_dir}"

  git --git-dir="${repo_dir}/.git" config sync-context.remote 'old@host:/old'

  run --separate-stderr git::context::sync --set 'new@host:/new'
  assert_success
  assert_stderr --partial "Updated saved remote from 'old@host:/old' to 'new@host:/new'"

  run git --git-dir="${repo_dir}/.git" config sync-context.remote
  assert_success
  assert_output 'new@host:/new'
}

# bats test_tags=git::context::sync
@test "git::context::sync --set requires a remote spec" {
  __create_cloned_repo
  cd "${repo_dir}"

  run --separate-stderr git::context::sync --set
  assert_failure
  assert_stderr --partial '--set requires a remote spec'
}

# bats test_tags=git::context::sync
@test "git::context::sync --unset clears saved remote" {
  __create_cloned_repo
  cd "${repo_dir}"

  git --git-dir="${repo_dir}/.git" config sync-context.remote 'me@host:/path'

  run --separate-stderr git::context::sync --unset
  assert_success
  assert_stderr --partial "Unset saved remote 'me@host:/path'"

  run git --git-dir="${repo_dir}/.git" config sync-context.remote
  assert_failure
}

# bats test_tags=git::context::sync
@test "git::context::sync --unset is no-op when nothing saved" {
  __create_cloned_repo
  cd "${repo_dir}"

  run --separate-stderr git::context::sync --unset
  assert_success
  assert_stderr --partial 'No saved remote to unset'
}

# bats test_tags=git::context::sync
@test "git::context::sync --show prints saved remote" {
  __create_cloned_repo
  cd "${repo_dir}"

  git --git-dir="${repo_dir}/.git" config sync-context.remote 'me@host:/path'

  run git::context::sync --show
  assert_success
  assert_output 'me@host:/path'
}

# bats test_tags=git::context::sync
@test "git::context::sync --show returns 1 when nothing saved" {
  __create_cloned_repo
  cd "${repo_dir}"

  run git::context::sync --show
  assert_failure
  refute_output
}

# bats test_tags=git::context::sync
@test "git::context::sync --set is silent when spec is unchanged" {
  __create_cloned_repo
  cd "${repo_dir}"

  git --git-dir="${repo_dir}/.git" config sync-context.remote 'me@host:/path'

  run --separate-stderr git::context::sync --set 'me@host:/path'
  assert_success
  refute_stderr
}
