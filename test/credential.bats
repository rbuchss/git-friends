#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load test_helper

setup_with_coverage 'git-friends/src/credential.sh'

################################################################################
# git::credential::token_helper - get action
################################################################################

# bats test_tags=git::credential
@test "git::credential::token_helper get outputs username and password" {
  export GITHUB_TOKEN='ghp_test_token_123'

  run git::credential::token_helper get

  assert_success
  assert_line 'username=x-access-token'
  assert_line "password=ghp_test_token_123"
}

# bats test_tags=git::credential
@test "git::credential::token_helper get uses GIT_FRIENDS_CREDENTIAL_USERNAME override" {
  export GITHUB_TOKEN='ghp_test_token_123'
  export GIT_FRIENDS_CREDENTIAL_USERNAME='oauth2'

  run git::credential::token_helper get

  assert_success
  assert_line 'username=oauth2'
  assert_line "password=ghp_test_token_123"
}

# bats test_tags=git::credential
@test "git::credential::token_helper get falls back to GIT_FRIENDS_CREDENTIAL_TOKEN" {
  unset GITHUB_TOKEN
  export GIT_FRIENDS_CREDENTIAL_TOKEN='gho_fallback_456'

  run git::credential::token_helper get

  assert_success
  assert_line 'username=x-access-token'
  assert_line "password=gho_fallback_456"
}

# bats test_tags=git::credential
@test "git::credential::token_helper get prefers GITHUB_TOKEN over GIT_FRIENDS_CREDENTIAL_TOKEN" {
  export GITHUB_TOKEN='ghp_primary'
  export GIT_FRIENDS_CREDENTIAL_TOKEN='gho_fallback'

  run git::credential::token_helper get

  assert_success
  assert_line "password=ghp_primary"
}

# bats test_tags=git::credential
@test "git::credential::token_helper get fails when no token is set" {
  unset GITHUB_TOKEN
  unset GIT_FRIENDS_CREDENTIAL_TOKEN

  run git::credential::token_helper get

  assert_failure
  refute_output
}

# bats test_tags=git::credential
@test "git::credential::token_helper get consumes stdin protocol info" {
  export GITHUB_TOKEN='ghp_test_token_123'

  __helper_with_stdin() {
    printf "protocol=https\nhost=github.com\n\n" \
      | git::credential::token_helper get
  }
  export -f __helper_with_stdin

  run __helper_with_stdin

  assert_success
  assert_line 'username=x-access-token'
  assert_line "password=ghp_test_token_123"
}

################################################################################
# git::credential::token_helper - store and erase actions
################################################################################

# bats test_tags=git::credential
@test "git::credential::token_helper store returns success with no output" {
  export GITHUB_TOKEN='ghp_test_token_123'

  run git::credential::token_helper store

  assert_success
  refute_output
}

# bats test_tags=git::credential
@test "git::credential::token_helper erase returns success with no output" {
  export GITHUB_TOKEN='ghp_test_token_123'

  run git::credential::token_helper erase

  assert_success
  refute_output
}

################################################################################
# git::credential::token_helper - no action
################################################################################

# bats test_tags=git::credential
@test "git::credential::token_helper with no args returns success with no output" {
  export GITHUB_TOKEN='ghp_test_token_123'

  run git::credential::token_helper

  assert_success
  refute_output
}
