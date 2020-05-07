#!/usr/bin/env bats

load test_helper

source "$(repo_root)/git-friends/src/url.sh"

@test "git::url::parse 'git@github.com:rbuchss/git-friends.git' 1" {
  run git::url::parse 'git@github.com:rbuchss/git-friends.git' 1
  assert_success
  assert_output 'git@'
}

@test "git::url::parse 'git@github.com:rbuchss/git-friends.git' 2" {
  run git::url::parse 'git@github.com:rbuchss/git-friends.git' 2
  assert_success
  assert_output 'github.com'
}

@test "git::url::parse 'git@github.com:rbuchss/git-friends.git' 3" {
  run git::url::parse 'git@github.com:rbuchss/git-friends.git' 3
  assert_success
  assert_output ':'
}

@test "git::url::parse 'git@github.com:rbuchss/git-friends.git' 4" {
  run git::url::parse 'git@github.com:rbuchss/git-friends.git' 4
  assert_success
  assert_output 'rbuchss'
}

@test "git::url::parse 'git@github.com:rbuchss/git-friends.git' 5" {
  run git::url::parse 'git@github.com:rbuchss/git-friends.git' 5
  assert_success
  assert_output 'git-friends.git'
}

@test "git::url::parse 'git@github.com:rbuchss/git-friends.git' 6" {
  run git::url::parse 'git@github.com:rbuchss/git-friends.git' 6
  assert_failure
}

@test "git::url::parse 'https://github.com/rbuchss/git-friends.git' 1" {
  run git::url::parse 'https://github.com/rbuchss/git-friends.git' 1
  assert_success
  assert_output 'https://'
}

@test "git::url::parse 'https://github.com/rbuchss/git-friends.git' 2" {
  run git::url::parse 'https://github.com/rbuchss/git-friends.git' 2
  assert_success
  assert_output 'github.com'
}

@test "git::url::parse 'https://github.com/rbuchss/git-friends.git' 3" {
  run git::url::parse 'https://github.com/rbuchss/git-friends.git' 3
  assert_success
  assert_output '/'
}

@test "git::url::parse 'https://github.com/rbuchss/git-friends.git' 4" {
  run git::url::parse 'https://github.com/rbuchss/git-friends.git' 4
  assert_success
  assert_output 'rbuchss'
}

@test "git::url::parse 'https://github.com/rbuchss/git-friends.git' 5" {
  run git::url::parse 'https://github.com/rbuchss/git-friends.git' 5
  assert_success
  assert_output 'git-friends.git'
}

@test "git::url::parse 'https://github.com/rbuchss/git-friends.git' 6" {
  run git::url::parse 'https://github.com/rbuchss/git-friends.git' 6
  assert_failure
}

@test "git::url::prefix 'git@github.com:rbuchss/git-friends.git'" {
  run git::url::prefix 'git@github.com:rbuchss/git-friends.git'
  assert_success
  assert_output 'git@'
}

@test "git::url::domain 'git@github.com:rbuchss/git-friends.git'" {
  run git::url::domain 'git@github.com:rbuchss/git-friends.git'
  assert_success
  assert_output 'github.com'
}

@test "git::url::separator 'git@github.com:rbuchss/git-friends.git'" {
  run git::url::separator 'git@github.com:rbuchss/git-friends.git'
  assert_success
  assert_output ':'
}

@test "git::url::user 'git@github.com:rbuchss/git-friends.git'" {
  run git::url::user 'git@github.com:rbuchss/git-friends.git'
  assert_success
  assert_output 'rbuchss'
}

@test "git::url::repo 'git@github.com:rbuchss/git-friends.git'" {
  run git::url::repo 'git@github.com:rbuchss/git-friends.git'
  assert_success
  assert_output 'git-friends.git'
}

@test "git::url::prefix 'https://github.com/rbuchss/git-friends.git'" {
  run git::url::prefix 'https://github.com/rbuchss/git-friends.git'
  assert_success
  assert_output 'https://'
}

@test "git::url::domain 'https://github.com/rbuchss/git-friends.git'" {
  run git::url::domain 'https://github.com/rbuchss/git-friends.git'
  assert_success
  assert_output 'github.com'
}

@test "git::url::separator 'https://github.com/rbuchss/git-friends.git'" {
  run git::url::separator 'https://github.com/rbuchss/git-friends.git'
  assert_success
  assert_output '/'
}

@test "git::url::user 'https://github.com/rbuchss/git-friends.git'" {
  run git::url::user 'https://github.com/rbuchss/git-friends.git'
  assert_success
  assert_output 'rbuchss'
}

@test "git::url::repo 'https://github.com/rbuchss/git-friends.git'" {
  run git::url::repo 'https://github.com/rbuchss/git-friends.git'
  assert_success
  assert_output 'git-friends.git'
}

@test "git::url::protocol 'git@github.com:rbuchss/git-friends.git'" {
  run git::url::protocol 'git@github.com:rbuchss/git-friends.git'
  assert_success
  assert_output 'ssh'
}

@test "git::url::protocol 'https://github.com/rbuchss/git-friends.git'" {
  run git::url::protocol 'https://github.com/rbuchss/git-friends.git'
  assert_success
  assert_output 'https'
}

@test "git::url::protocol 'http://github.com/rbuchss/git-friends.git'" {
  run git::url::protocol 'http://github.com/rbuchss/git-friends.git'
  assert_success
  assert_output 'http'
}

@test "git::url::protocol 'not-valid://github.com/rbuchss/git-friends.git'" {
  run git::url::protocol 'not-valid://github.com/rbuchss/git-friends.git'
  assert_failure
}

@test "git::url::change_user" {
  run git::url::change_user
  assert_failure
}

@test "git::url::change_user 'git@github.com:rbuchss/git-friends.git'" {
  run git::url::change_user 'git@github.com:rbuchss/git-friends.git'
  assert_failure
}

@test "git::url::change_user 'git@github.com:rbuchss/git-friends.git' 'someone'" {
  run git::url::change_user 'git@github.com:rbuchss/git-friends.git' 'someone'
  assert_success
  assert_output 'git@github.com:someone/git-friends.git'
}

@test "git::url::change_user 'https://github.com/rbuchss/git-friends.git' 'someone'" {
  run git::url::change_user 'https://github.com/rbuchss/git-friends.git' 'someone'
  assert_success
  assert_output 'https://github.com/someone/git-friends.git'
}

@test "git::url::change_user 'not-valid://github.com/rbuchss/git-friends.git' 'someone'" {
  run git::url::change_user 'not-vaild://github.com/rbuchss/git-friends.git' 'someone'
  assert_failure
  assert_no_output_exists
}

@test "git::url::prefix_for_protocol" {
  run git::url::prefix_for_protocol
  assert_failure
}

@test "git::url::prefix_for_protocol 'ssh'" {
  run git::url::prefix_for_protocol 'ssh'
  assert_success
  assert_output 'git@'
}

@test "git::url::prefix_for_protocol 'https'" {
  run git::url::prefix_for_protocol 'https'
  assert_success
  assert_output 'https://'
}

@test "git::url::prefix_for_protocol 'http'" {
  run git::url::prefix_for_protocol 'http'
  assert_success
  assert_output 'http://'
}

@test "git::url::prefix_for_protocol 'not-valid'" {
  run git::url::prefix_for_protocol 'not-valid'
  assert_failure
}

@test "git::url::separator_for_protocol" {
  run git::url::separator_for_protocol
  assert_failure
}

@test "git::url::separator_for_protocol 'ssh'" {
  run git::url::separator_for_protocol 'ssh'
  assert_success
  assert_output ':'
}

@test "git::url::separator_for_protocol 'https'" {
  run git::url::separator_for_protocol 'https'
  assert_success
  assert_output '/'
}

@test "git::url::separator_for_protocol 'http'" {
  run git::url::separator_for_protocol 'http'
  assert_success
  assert_output '/'
}

@test "git::url::separator_for_protocol 'not-valid'" {
  run git::url::separator_for_protocol 'not-valid'
  assert_failure
}

@test "git::url::change_protocol" {
  run git::url::change_protocol
  assert_failure
}

@test "git::url::change_protocol 'git@github.com:rbuchss/git-friends.git'" {
  run git::url::change_protocol 'git@github.com:rbuchss/git-friends.git'
  assert_failure
}

@test "git::url::change_protocol 'https://github.com/rbuchss/git-friends.git' 'ssh'" {
  run git::url::change_protocol 'https://github.com/rbuchss/git-friends.git' 'ssh'
  assert_success
  assert_output 'git@github.com:rbuchss/git-friends.git'
}

@test "git::url::change_protocol 'git@github.com:rbuchss/git-friends.git' 'ssh'" {
  run git::url::change_protocol 'git@github.com:rbuchss/git-friends.git' 'ssh'
  assert_success
  assert_output 'git@github.com:rbuchss/git-friends.git'
}

@test "git::url::change_protocol 'git@github.com:rbuchss/git-friends.git' 'https'" {
  run git::url::change_protocol 'git@github.com:rbuchss/git-friends.git' 'https'
  assert_success
  assert_output 'https://github.com/rbuchss/git-friends.git'
}

@test "git::url::change_protocol 'git@github.com:rbuchss/git-friends.git' 'http'" {
  run git::url::change_protocol 'git@github.com:rbuchss/git-friends.git' 'http'
  assert_success
  assert_output 'http://github.com/rbuchss/git-friends.git'
}

@test "git::url::change_protocol 'git@github.com:rbuchss/git-friends.git' 'not-valid'" {
  run git::url::change_protocol 'git@github.com:rbuchss/git-friends.git' 'not-valid'
  assert_failure
}

@test "git::url::change_protocol 'not-valid://github.com/rbuchss/git-friends.git' 'ssh'" {
  run git::url::change_protocol 'not-vaild://github.com/rbuchss/git-friends.git' 'ssh'
  assert_failure
  assert_no_output_exists
}
