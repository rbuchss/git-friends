#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/clone.sh'

################################################################################
# git::clone::cd
################################################################################

# bats test_tags=git::clone::cd
@test "git::clone::cd fails with no repository url" {
  run git::clone::cd
  assert_failure
}

# bats test_tags=git::clone::cd
@test "git::clone::cd clones and changes to directory" {
  local source_dir="${BATS_TEST_TMPDIR}/source"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  cd "${BATS_TEST_TMPDIR}"

  git::clone::cd "${source_dir}" 'cloned'

  assert_equal "${PWD}" "${BATS_TEST_TMPDIR}/cloned"
}

# bats test_tags=git::clone::cd
@test "git::clone::cd derives directory from url when not provided" {
  cd "${BATS_TEST_TMPDIR}"

  git::clone::cd 'https://github.com/rbuchss/git-friends.git'

  assert_equal "${PWD}" "${BATS_TEST_TMPDIR}/git-friends"
}

# bats test_tags=git::clone::cd
@test "git::clone::cd fails when git clone fails" {
  cd "${BATS_TEST_TMPDIR}"

  # Provide a repository URL but it won't actually clone
  run git::clone::cd '/nonexistent/path/to/repo' 'target-dir'
  assert_failure
}
