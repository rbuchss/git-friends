#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/upstream.sh'

# bats test_tags=git::upstream::add
@test "git::upstream::add fails when no user is provided and stdin is empty" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"
  git init "${repo_dir}"
  cd "${repo_dir}"

  __upstream_add_empty() { echo '' | git::upstream::add; }
  export -f __upstream_add_empty

  run __upstream_add_empty

  assert_failure
  assert_output --partial 'no upstream user/organization name provided'
}

# bats test_tags=git::upstream::add
@test "git::upstream::add adds upstream remote with provided user" {
  local source_dir="${BATS_TEST_TMPDIR}/source"
  local repo_dir="${BATS_TEST_TMPDIR}/repo"
  git init "${source_dir}"
  git -C "${source_dir}" -c user.name=test -c user.email=test commit --allow-empty -m 'initial'
  git clone "${source_dir}" "${repo_dir}"
  git -C "${repo_dir}" remote set-url origin 'https://github.com/testuser/repo.git'
  cd "${repo_dir}"

  __upstream_add_with_yes() { echo 'y' | git::upstream::add "$@"; }
  export -f __upstream_add_with_yes

  run __upstream_add_with_yes 'otheruser'

  assert_success

  run git config --get remote.upstream.url
  assert_success
  assert_output 'https://github.com/otheruser/repo.git'
}

# bats test_tags=git::upstream::add
@test "git::upstream::add adds custom-named remote with provided user" {
  local source_dir="${BATS_TEST_TMPDIR}/source"
  local repo_dir="${BATS_TEST_TMPDIR}/repo"
  git init "${source_dir}"
  git -C "${source_dir}" -c user.name=test -c user.email=test commit --allow-empty -m 'initial'
  git clone "${source_dir}" "${repo_dir}"
  git -C "${repo_dir}" remote set-url origin 'https://github.com/testuser/repo.git'
  cd "${repo_dir}"

  __upstream_add_with_yes() { echo 'y' | git::upstream::add "$@"; }
  export -f __upstream_add_with_yes

  run __upstream_add_with_yes 'otheruser' 'custom-remote'

  assert_success

  run git config --get remote.custom-remote.url
  assert_success
  assert_output 'https://github.com/otheruser/repo.git'
}

# bats test_tags=git::upstream::add
@test "git::upstream::add does nothing when no origin remote exists" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"
  git init "${repo_dir}"
  cd "${repo_dir}"

  __upstream_add_with_yes() { echo 'y' | git::upstream::add "$@"; }
  export -f __upstream_add_with_yes

  run __upstream_add_with_yes 'otheruser'
  assert_success

  # No remote should have been added
  run git remote
  refute_output --partial 'upstream'
}
