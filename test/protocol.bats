#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/protocol.sh'

# bats test_tags=git::protocol::set
@test "git::protocol::set fails when no remote is configured" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"
  git init "${repo_dir}"
  cd "${repo_dir}"

  # Remove origin if it exists (bare init has none, but be explicit)
  git remote remove origin 2>/dev/null || true

  run git::protocol::set 'ssh'

  assert_failure
  assert_output --partial "remote 'origin' not found"
}

# bats test_tags=git::protocol::set
@test "git::protocol::set 'ssh' converts https origin to ssh format" {
  local source_dir="${BATS_TEST_TMPDIR}/source"
  local repo_dir="${BATS_TEST_TMPDIR}/repo"
  git init "${source_dir}"
  git -C "${source_dir}" -c user.name=test -c user.email=test commit --allow-empty -m 'initial'
  git clone "${source_dir}" "${repo_dir}"
  git -C "${repo_dir}" remote set-url origin 'https://github.com/test/repo.git'
  cd "${repo_dir}"

  __protocol_set_with_yes() { echo 'y' | git::protocol::set "$@"; }
  export -f __protocol_set_with_yes

  run __protocol_set_with_yes 'ssh'

  assert_success

  run git config --get remote.origin.url
  assert_success
  assert_output 'git@github.com:test/repo.git'
}

# bats test_tags=git::protocol::set
@test "git::protocol::set 'ssh' 'upstream' fails when upstream remote does not exist" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"
  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::protocol::set 'ssh' 'upstream'

  assert_failure
  assert_output --partial "remote 'upstream' not found"
}

# bats test_tags=git::protocol::set
@test "git::protocol::set with invalid protocol does not change remote url" {
  local source_dir="${BATS_TEST_TMPDIR}/source"
  local repo_dir="${BATS_TEST_TMPDIR}/repo"
  git init "${source_dir}"
  git -C "${source_dir}" -c user.name=test -c user.email=test commit --allow-empty -m 'initial'
  git clone "${source_dir}" "${repo_dir}"
  git -C "${repo_dir}" remote set-url origin 'https://github.com/test/repo.git'
  cd "${repo_dir}"

  __protocol_set_with_yes() { echo 'y' | git::protocol::set "$@"; }
  export -f __protocol_set_with_yes

  run __protocol_set_with_yes 'not-valid'
  assert_success

  # URL should remain unchanged
  run git config --get remote.origin.url
  assert_output 'https://github.com/test/repo.git'
}

################################################################################
# git::protocol::is (generic predicate)
################################################################################

# bats test_tags=git::protocol::is
@test "git::protocol::is returns 0 when protocol matches" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'https://github.com/user/repo.git'
  cd "${repo_dir}"

  run git::protocol::is 'https'

  assert_success
}

# bats test_tags=git::protocol::is
@test "git::protocol::is returns 1 when protocol does not match" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'https://github.com/user/repo.git'
  cd "${repo_dir}"

  run git::protocol::is 'ssh'

  assert_failure
}

# bats test_tags=git::protocol::is
@test "git::protocol::is returns 0 when not in a git repo" {
  cd "${BATS_TEST_TMPDIR}"

  run git::protocol::is 'https'

  assert_success
}

# bats test_tags=git::protocol::is
@test "git::protocol::is returns 0 when remote does not exist" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::protocol::is 'https'

  assert_success
}

# bats test_tags=git::protocol::is
@test "git::protocol::is accepts custom remote name" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'https://github.com/user/repo.git'
  git -C "${repo_dir}" remote add upstream 'git@github.com:user/repo.git'
  cd "${repo_dir}"

  run git::protocol::is 'https' upstream
  assert_failure

  run git::protocol::is 'https' origin
  assert_success
}

################################################################################
# git::protocol::is_https
################################################################################

# bats test_tags=git::protocol::is_https
@test "git::protocol::is_https matches HTTPS remote" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'https://github.com/user/repo.git'
  cd "${repo_dir}"

  run git::protocol::is_https
  assert_success
}

# bats test_tags=git::protocol::is_https
@test "git::protocol::is_https rejects SSH remote" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'git@github.com:user/repo.git'
  cd "${repo_dir}"

  run git::protocol::is_https
  assert_failure
}

################################################################################
# git::protocol::is_ssh
################################################################################

# bats test_tags=git::protocol::is_ssh
@test "git::protocol::is_ssh matches SCP-style SSH remote" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'git@github.com:user/repo.git'
  cd "${repo_dir}"

  run git::protocol::is_ssh
  assert_success
}

# bats test_tags=git::protocol::is_ssh
@test "git::protocol::is_ssh matches ssh:// remote" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'ssh://git@github.com/user/repo.git'
  cd "${repo_dir}"

  run git::protocol::is_ssh
  assert_success
}

# bats test_tags=git::protocol::is_ssh
@test "git::protocol::is_ssh rejects HTTPS remote" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'https://github.com/user/repo.git'
  cd "${repo_dir}"

  run git::protocol::is_ssh
  assert_failure
}

################################################################################
# git::protocol::is_http
################################################################################

# bats test_tags=git::protocol::is_http
@test "git::protocol::is_http matches HTTP remote" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'http://github.com/user/repo.git'
  cd "${repo_dir}"

  run git::protocol::is_http
  assert_success
}

# bats test_tags=git::protocol::is_http
@test "git::protocol::is_http rejects HTTPS remote" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'https://github.com/user/repo.git'
  cd "${repo_dir}"

  run git::protocol::is_http
  assert_failure
}

################################################################################
# git::protocol::is_git
################################################################################

# bats test_tags=git::protocol::is_git
@test "git::protocol::is_git matches git:// remote" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'git://github.com/user/repo.git'
  cd "${repo_dir}"

  run git::protocol::is_git
  assert_success
}

# bats test_tags=git::protocol::is_git
@test "git::protocol::is_git rejects SSH remote" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'git@github.com:user/repo.git'
  cd "${repo_dir}"

  run git::protocol::is_git
  assert_failure
}

################################################################################
# git::protocol::is_file
################################################################################

# bats test_tags=git::protocol::is_file
@test "git::protocol::is_file matches file:// remote" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'file:///path/to/repo.git'
  cd "${repo_dir}"

  run git::protocol::is_file
  assert_success
}

# bats test_tags=git::protocol::is_file
@test "git::protocol::is_file rejects HTTPS remote" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'https://github.com/user/repo.git'
  cd "${repo_dir}"

  run git::protocol::is_file
  assert_failure
}
