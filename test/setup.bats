#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load test_helper

setup_with_coverage 'git-friends/src/setup.sh'

################################################################################
# git::setup::config - usage and validation
################################################################################

# bats test_tags=git::setup
@test "git::setup::config with no args shows usage" {
  run git::setup::config

  assert_failure
  assert_output --partial 'Usage:'
  assert_output --partial 'gitconfig-local'
  assert_output --partial 'agent-env'
}

# bats test_tags=git::setup
@test "git::setup::config --help shows usage and succeeds" {
  run git::setup::config --help

  assert_success
  assert_output --partial 'Usage:'
  assert_output --partial 'gitconfig-local'
  assert_output --partial 'agent-env'
}

# bats test_tags=git::setup
@test "git::setup::config -h shows usage and succeeds" {
  run git::setup::config -h

  assert_success
  assert_output --partial 'Usage:'
}

# bats test_tags=git::setup
@test "git::setup::config with unknown template shows error" {
  run git::setup::config 'nonexistent'

  assert_failure
  assert_output --partial 'Usage:'
  assert_output --partial 'gitconfig-local'
}

################################################################################
# git::setup::config - gitconfig-local
################################################################################

# bats test_tags=git::setup
@test "git::setup::config gitconfig-local installs to target path" {
  local target="${BATS_TEST_TMPDIR}/gitconfig.local"

  run --separate-stderr git::setup::config gitconfig-local "${target}"

  assert_success
  assert_stderr --partial "Installed gitconfig-local to ${target}"
  [[ -f "${target}" ]]
}

# bats test_tags=git::setup
@test "git::setup::config gitconfig-local copies template content" {
  local target="${BATS_TEST_TMPDIR}/gitconfig.local"

  git::setup::config gitconfig-local "${target}"

  run grep 'insteadOf' "${target}"
  assert_success
}

################################################################################
# git::setup::config - agent-env
################################################################################

# bats test_tags=git::setup
@test "git::setup::config agent-env installs to target path" {
  local target="${BATS_TEST_TMPDIR}/agent.env"

  # Run from a non-git directory so the post-install protocol prompt
  # is not triggered (is_https returns true when not in a repo).
  cd "${BATS_TEST_TMPDIR}"

  run --separate-stderr git::setup::config agent-env "${target}"

  assert_success
  assert_stderr --partial "Installed agent-env to ${target}"
  [[ -f "${target}" ]]
}

# bats test_tags=git::setup
@test "git::setup::config agent-env copies template content" {
  local target="${BATS_TEST_TMPDIR}/agent.env"

  cd "${BATS_TEST_TMPDIR}"
  git::setup::config agent-env "${target}"

  run grep 'GITHUB_TOKEN' "${target}"
  assert_success

  run grep 'GIT_CONFIG_COUNT' "${target}"
  assert_success

  run grep 'credential-helper' "${target}"
  assert_success
}

################################################################################
# git::setup::config - existing file behavior
################################################################################

# bats test_tags=git::setup
@test "git::setup::config warns on existing file" {
  local target="${BATS_TEST_TMPDIR}/existing-config"

  echo 'existing content' >"${target}"

  run --separate-stderr git::setup::config gitconfig-local "${target}"

  assert_failure
  assert_stderr --partial 'File already exists:'
  assert_stderr --partial '--force'
  assert_stderr --partial '--merge'

  # Verify original content is preserved
  run cat "${target}"
  assert_output 'existing content'
}

# bats test_tags=git::setup
@test "git::setup::config --force overwrites existing file" {
  local target="${BATS_TEST_TMPDIR}/existing-config"

  echo 'existing content' >"${target}"

  run --separate-stderr git::setup::config gitconfig-local "${target}" --force

  assert_success
  assert_stderr --partial "Installed gitconfig-local to ${target}"

  # Verify content was replaced
  run grep 'insteadOf' "${target}"
  assert_success
}

# bats test_tags=git::setup
@test "git::setup::config -f flag overwrites existing file" {
  local target="${BATS_TEST_TMPDIR}/existing-config"

  echo 'existing content' >"${target}"

  run --separate-stderr git::setup::config gitconfig-local "${target}" -f

  assert_success
  assert_stderr --partial "Installed gitconfig-local to ${target}"
}

################################################################################
# git::setup::config - merge mode
################################################################################

# bats test_tags=git::setup
@test "git::setup::config --merge appends to existing file" {
  local target="${BATS_TEST_TMPDIR}/existing-config"

  echo 'existing content' >"${target}"

  run --separate-stderr git::setup::config gitconfig-local "${target}" --merge

  assert_success
  assert_stderr --partial "Merged gitconfig-local into ${target}"

  # Verify original content is preserved and template is appended
  run grep 'existing content' "${target}"
  assert_success

  run grep 'insteadOf' "${target}"
  assert_success
}

# bats test_tags=git::setup
@test "git::setup::config -m flag appends to existing file" {
  local target="${BATS_TEST_TMPDIR}/existing-config"

  echo 'existing content' >"${target}"

  run --separate-stderr git::setup::config gitconfig-local "${target}" -m

  assert_success
  assert_stderr --partial "Merged gitconfig-local into ${target}"
}

# bats test_tags=git::setup
@test "git::setup::config --merge on new file creates it" {
  local target="${BATS_TEST_TMPDIR}/new-config"

  run --separate-stderr git::setup::config gitconfig-local "${target}" --merge

  assert_success
  assert_stderr --partial "Installed gitconfig-local to ${target}"
  [[ -f "${target}" ]]
}

# bats test_tags=git::setup
@test "git::setup::config --force and --merge together fails" {
  local target="${BATS_TEST_TMPDIR}/config"

  run --separate-stderr git::setup::config gitconfig-local "${target}" --force --merge

  assert_failure
  assert_stderr --partial 'Cannot use --force and --merge together'
}

# bats test_tags=git::setup
@test "git::setup::config --merge adds blank line separator" {
  local target="${BATS_TEST_TMPDIR}/existing-config"

  printf 'last line\n' >"${target}"

  git::setup::config agent-env "${target}" --merge

  # Verify blank line separates old and new content
  local line2
  line2="$(sed -n '2p' "${target}")"
  [[ -z "${line2}" ]]
}

################################################################################
# git::setup::config - error handling
################################################################################

# bats test_tags=git::setup
@test "git::setup::config fails if target directory does not exist" {
  local target="${BATS_TEST_TMPDIR}/nonexistent-dir/config"

  run --separate-stderr git::setup::config gitconfig-local "${target}"

  assert_failure
  assert_stderr --partial 'Target directory does not exist'
}

# bats test_tags=git::setup
@test "git::setup::config --force flag position is flexible" {
  local target="${BATS_TEST_TMPDIR}/existing-config"

  echo 'existing content' >"${target}"

  run --separate-stderr git::setup::config --force gitconfig-local "${target}"

  assert_success
  assert_stderr --partial "Installed gitconfig-local to ${target}"
}

################################################################################
# git::setup::config - agent-env protocol prompt
################################################################################

# Helper: run setup config with stdin answer for the protocol prompt.
__setup_config_with_answer() {
  local answer="$1"
  shift
  echo "${answer}" | git::setup::config "$@"
}
export -f __setup_config_with_answer

# bats test_tags=git::setup
@test "git::setup::config agent-env offers protocol switch on SSH remote" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"
  local target="${repo_dir}/.env"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'git@github.com:user/repo.git'
  cd "${repo_dir}"

  run --separate-stderr __setup_config_with_answer 'n' agent-env "${target}"

  assert_success
  assert_stderr --partial "Installed agent-env"
  assert_stderr --partial 'requires HTTPS'
}

# bats test_tags=git::setup
@test "git::setup::config agent-env converts remote when user accepts" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"
  local target="${repo_dir}/.env"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'git@github.com:user/repo.git'
  cd "${repo_dir}"

  run --separate-stderr __setup_config_with_answer 'y' agent-env "${target}"

  assert_success

  local url
  url="$(git -C "${repo_dir}" config --get remote.origin.url)"
  [[ "${url}" == "https://github.com/user/repo.git" ]]
}

# bats test_tags=git::setup
@test "git::setup::config agent-env keeps SSH when user declines" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"
  local target="${repo_dir}/.env"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'git@github.com:user/repo.git'
  cd "${repo_dir}"

  run --separate-stderr __setup_config_with_answer 'n' agent-env "${target}"

  assert_success

  local url
  url="$(git -C "${repo_dir}" config --get remote.origin.url)"
  [[ "${url}" == "git@github.com:user/repo.git" ]]
}

# bats test_tags=git::setup
@test "git::setup::config agent-env skips prompt for HTTPS remote" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"
  local target="${repo_dir}/.env"

  git init "${repo_dir}"
  git -C "${repo_dir}" remote add origin 'https://github.com/user/repo.git'
  cd "${repo_dir}"

  run --separate-stderr git::setup::config agent-env "${target}"

  assert_success
  assert_stderr --partial "Installed agent-env"
  refute_stderr --partial 'requires HTTPS'
}
