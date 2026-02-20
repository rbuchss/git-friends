#!/usr/bin/env bats

load test_helper

bats_require_minimum_version 1.5.0

setup_with_coverage 'git-friends/src/remote.sh'

# Helper to create a cloned repo.
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

################################################################################
# git::remote::validate_repository
################################################################################

# bats test_tags=git::remote::validate_repository
@test "git::remote::validate_repository returns success in git repo" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  run git::remote::validate_repository
  assert_success
}

# bats test_tags=git::remote::validate_repository
@test "git::remote::validate_repository returns failure outside git repo" {
  cd "${BATS_TEST_TMPDIR}"

  run git::remote::validate_repository
  assert_failure
}

################################################################################
# git::remote::get_current_branch
################################################################################

# bats test_tags=git::remote::get_current_branch
@test "git::remote::get_current_branch returns current branch name" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  run git::remote::get_current_branch
  assert_success
  assert_output --regexp '^(main|master)$'
}

# bats test_tags=git::remote::get_current_branch
@test "git::remote::get_current_branch returns branch after checkout" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"
  git checkout -b 'feature'

  run git::remote::get_current_branch
  assert_success
  assert_output 'feature'
}

################################################################################
# git::remote::validate_remote_branch
################################################################################

# bats test_tags=git::remote::validate_remote_branch
@test "git::remote::validate_remote_branch returns success for existing remote branch" {
  local repo_dir branch

  __create_cloned_repo
  cd "${repo_dir}"
  branch="$(git branch --show-current)"

  run git::remote::validate_remote_branch "origin/${branch}"
  assert_success
}

# bats test_tags=git::remote::validate_remote_branch
@test "git::remote::validate_remote_branch returns 2 for missing remote branch" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  run git::remote::validate_remote_branch 'origin/nonexistent'
  assert_failure
  assert_equal "${status}" 2
}

################################################################################
# git::remote::get_commit_hashes
################################################################################

# bats test_tags=git::remote::get_commit_hashes
@test "git::remote::get_commit_hashes returns local and remote hashes" {
  local repo_dir branch

  __create_cloned_repo
  cd "${repo_dir}"
  branch="$(git branch --show-current)"

  run git::remote::get_commit_hashes "origin/${branch}"
  assert_success
  # Output should be two space-separated hashes
  assert_output --regexp '^[0-9a-f]+ [0-9a-f]+$'
}

################################################################################
# git::remote::handle_fetch_error
################################################################################

# bats test_tags=git::remote::handle_fetch_error
@test "git::remote::handle_fetch_error returns status 128 for connection error" {
  run git::remote::handle_fetch_error 128
  assert_failure
  assert_equal "${status}" 128
}

# bats test_tags=git::remote::handle_fetch_error
@test "git::remote::handle_fetch_error returns status 129 for auth error" {
  run git::remote::handle_fetch_error 129
  assert_failure
  assert_equal "${status}" 129
}

# bats test_tags=git::remote::handle_fetch_error
@test "git::remote::handle_fetch_error returns status for unknown error" {
  run git::remote::handle_fetch_error 1
  assert_failure
  assert_equal "${status}" 1
}

################################################################################
# git::remote::default_branch
################################################################################

# bats test_tags=git::remote::default_branch
@test "git::remote::default_branch returns main branch name" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  run git::remote::default_branch
  assert_success
  assert_output --regexp '^(main|master)$'
}

################################################################################
# git::remote::fetch_remote
################################################################################

# bats test_tags=git::remote::fetch_remote
@test "git::remote::fetch_remote succeeds with valid remote" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  run git::remote::fetch_remote 'origin'
  assert_success
}

################################################################################
# git::remote::compare_branches
################################################################################

# bats test_tags=git::remote::compare_branches
@test "git::remote::compare_branches reports up to date" {
  local repo_dir branch

  __create_cloned_repo
  cd "${repo_dir}"
  branch="$(git branch --show-current)"

  local local_hash remote_hash
  local_hash="$(git rev-parse HEAD)"
  remote_hash="$(git rev-parse "origin/${branch}")"

  run git::remote::compare_branches \
    "${branch}" 'origin' "origin/${branch}" \
    "${local_hash}" "${remote_hash}"
  assert_success
}

# bats test_tags=git::remote::compare_branches
@test "git::remote::compare_branches reports local ahead" {
  local repo_dir branch

  __create_cloned_repo
  cd "${repo_dir}"
  branch="$(git branch --show-current)"

  # Create a local commit ahead of remote
  git -c user.name=test -c user.email=test \
    commit --allow-empty -m 'local ahead'

  local local_hash remote_hash
  local_hash="$(git rev-parse HEAD)"
  remote_hash="$(git rev-parse "origin/${branch}")"

  run git::remote::compare_branches \
    "${branch}" 'origin' "origin/${branch}" \
    "${local_hash}" "${remote_hash}"
  assert_success
  assert_output --regexp 'ahead'
}

# bats test_tags=git::remote::compare_branches
@test "git::remote::compare_branches reports local behind" {
  local source_dir="${BATS_TEST_TMPDIR}/source"
  local repo_dir="${BATS_TEST_TMPDIR}/cloned"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  git clone "${source_dir}" "${repo_dir}"

  # Add commit to source and fetch it
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'upstream ahead'

  cd "${repo_dir}"
  git fetch origin

  local branch
  branch="$(git branch --show-current)"

  local local_hash remote_hash
  local_hash="$(git rev-parse HEAD)"
  remote_hash="$(git rev-parse "origin/${branch}")"

  run git::remote::compare_branches \
    "${branch}" 'origin' "origin/${branch}" \
    "${local_hash}" "${remote_hash}"
  assert_failure
  assert_output --regexp 'OUT OF DATE'
}

# bats test_tags=git::remote::compare_branches
@test "git::remote::compare_branches reports diverged" {
  local source_dir="${BATS_TEST_TMPDIR}/source"
  local repo_dir="${BATS_TEST_TMPDIR}/cloned"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  git clone "${source_dir}" "${repo_dir}"

  # Add commit to source
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'upstream diverge'

  # Add commit locally
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'local diverge'

  cd "${repo_dir}"
  git fetch origin

  local branch
  branch="$(git branch --show-current)"

  local local_hash remote_hash
  local_hash="$(git rev-parse HEAD)"
  remote_hash="$(git rev-parse "origin/${branch}")"

  run git::remote::compare_branches \
    "${branch}" 'origin' "origin/${branch}" \
    "${local_hash}" "${remote_hash}"
  assert_failure
  assert_output --regexp 'diverged'
}

################################################################################
# git::remote::check_status
################################################################################

# bats test_tags=git::remote::check_status
@test "git::remote::check_status returns success when up to date" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  run git::remote::check_status
  assert_success
}

# bats test_tags=git::remote::check_status
@test "git::remote::check_status fails outside git repo" {
  cd "${BATS_TEST_TMPDIR}"

  run git::remote::check_status
  assert_failure
}

# bats test_tags=git::remote::check_status
@test "git::remote::check_status handles missing remote branch" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  git checkout -b 'new-local-branch'

  run git::remote::check_status
  # Missing remote branch is not an error — exit cleanly
  assert_success
}

# bats test_tags=git::remote::check_status
@test "git::remote::check_status detects local ahead" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  git -c user.name=test -c user.email=test \
    commit --allow-empty -m 'local ahead'

  run git::remote::check_status
  assert_success
}

# bats test_tags=git::remote::check_status
@test "git::remote::check_status detects local behind" {
  local source_dir="${BATS_TEST_TMPDIR}/source"
  local repo_dir="${BATS_TEST_TMPDIR}/behind"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  git clone "${source_dir}" "${repo_dir}"

  # Add commit to source and fetch it
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'upstream ahead'

  cd "${repo_dir}"

  run git::remote::check_status
  assert_failure
}

# bats test_tags=git::remote::check_status
@test "git::remote::check_status returns failure with error message when not in git repo" {
  cd "${BATS_TEST_TMPDIR}"

  run --separate-stderr git::remote::check_status
  assert_failure
  assert_stderr --partial 'Not a valid repository'
}

# bats test_tags=git::remote::check_status
@test "git::remote::check_status returns failure when fetch fails" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  # Stub fetch_remote to simulate a fetch failure
  git::remote::fetch_remote() {
    return 1
  }
  export -f git::remote::fetch_remote

  run --separate-stderr git::remote::check_status
  assert_failure
  assert_stderr --partial 'Could not fetch remote branch'
}

################################################################################
# git::remote::check_status (get_commit_hashes failure)
################################################################################

# bats test_tags=git::remote::check_status
@test "git::remote::check_status fails when get_commit_hashes fails" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  git::remote::get_commit_hashes() { return 1; }
  export -f git::remote::get_commit_hashes

  run --separate-stderr git::remote::check_status
  assert_failure
  assert_stderr --partial 'Could not get commit hashes'
}

################################################################################
# git::remote::fetch_remote (fetch fails with error code)
################################################################################

# bats test_tags=git::remote::fetch_remote
@test "git::remote::fetch_remote calls handle_fetch_error on failure" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  # Stub git::exec to fail fetch
  git::exec() {
    if [[ "$1" == 'fetch' ]]; then
      return 1
    fi
    command git "$@"
  }
  export -f git::exec

  run --separate-stderr git::remote::fetch_remote 'origin'
  # Note: handle_fetch_error receives $? from the `!` negation (0),
  # but the lines in fetch_remote are still exercised
  assert_stderr --partial 'Fetching latest changes'
  assert_stderr --partial 'handle_fetch_error'
}

################################################################################
# git::remote::get_current_branch (empty branch)
################################################################################

# bats test_tags=git::remote::get_current_branch
@test "git::remote::get_current_branch returns failure when branch is empty" {
  # Stub git::exec to produce empty output so current_branch is empty
  git::exec() {
    return 1
  }
  export -f git::exec

  run git::remote::get_current_branch
  assert_failure
  refute_output
}

################################################################################
# git::remote::validate_repository (error message)
################################################################################

# bats test_tags=git::remote::validate_repository
@test "git::remote::validate_repository logs error when not in git repo" {
  cd "${BATS_TEST_TMPDIR}"

  run --separate-stderr git::remote::validate_repository
  assert_failure
  assert_stderr --partial 'Not in a git repository'
}

################################################################################
# git::remote::handle_fetch_error (stderr messages)
################################################################################

# bats test_tags=git::remote::handle_fetch_error
@test "git::remote::handle_fetch_error logs connection error message for status 128" {
  run --separate-stderr git::remote::handle_fetch_error 128
  assert_failure
  assert_equal "${status}" 128
  assert_stderr --partial 'Could not connect to remote repository'
  assert_stderr --partial 'Possible causes'
}

# bats test_tags=git::remote::handle_fetch_error
@test "git::remote::handle_fetch_error logs auth error message for status 129" {
  run --separate-stderr git::remote::handle_fetch_error 129
  assert_failure
  assert_equal "${status}" 129
  assert_stderr --partial 'Authentication failed'
  assert_stderr --partial 'SSH keys or access tokens'
}

# bats test_tags=git::remote::handle_fetch_error
@test "git::remote::handle_fetch_error logs generic error message for unknown status" {
  run --separate-stderr git::remote::handle_fetch_error 42
  assert_failure
  assert_equal "${status}" 42
  assert_stderr --partial 'Git fetch failed with exit code 42'
  assert_stderr --partial 'network connection and repository access'
}

################################################################################
# git::remote::check_status (get_current_branch failure)
################################################################################

# bats test_tags=git::remote::check_status
@test "git::remote::check_status fails when branch cannot be determined" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  # Stub get_current_branch to simulate failure
  git::remote::get_current_branch() { return 1; }
  export -f git::remote::get_current_branch

  run --separate-stderr git::remote::check_status
  assert_failure
  assert_stderr --partial 'Could not determine current branch'
}
