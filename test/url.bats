#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load test_helper

setup_with_coverage 'git-friends/src/url.sh'

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
  run --separate-stderr git::url::parse 'git@github.com:rbuchss/git-friends.git' 6

  assert_failure
  assert_stderr --partial 'out of range'
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
  run --separate-stderr git::url::parse 'https://github.com/rbuchss/git-friends.git' 6

  assert_failure
  assert_stderr --partial 'out of range'
}

@test "git::url::parse 'ssh://git@github.com/rbuchss/git-friends.git' 1 2 3 4 5" {
  run git::url::parse 'ssh://git@github.com/rbuchss/git-friends.git' 1 2 3 4 5

  assert_success
  assert_output "ssh://git@
github.com
/
rbuchss
git-friends.git"
}

@test "git::url::parse 'ssh://github.com:2222/rbuchss/git-friends.git' strips port" {
  run git::url::parse 'ssh://github.com:2222/rbuchss/git-friends.git' 1 2 3 4 5

  assert_success
  assert_output "ssh://
github.com
/
rbuchss
git-friends.git"
}

@test "git::url::parse 'git://github.com/rbuchss/git-friends.git' 1 2 3 4 5" {
  run git::url::parse 'git://github.com/rbuchss/git-friends.git' 1 2 3 4 5

  assert_success
  assert_output "git://
github.com
/
rbuchss
git-friends.git"
}

@test "git::url::parse 'git://github.com:9418/rbuchss/git-friends.git' strips port" {
  run git::url::parse 'git://github.com:9418/rbuchss/git-friends.git' 1 2 3 4 5

  assert_success
  assert_output "git://
github.com
/
rbuchss
git-friends.git"
}

@test "git::url::parse 'git@github.com:rbuchss/git-friends.git' 1 2 3 4 5" {
  run git::url::parse 'git@github.com:rbuchss/git-friends.git' 1 2 3 4 5

  assert_success
  assert_output "git@
github.com
:
rbuchss
git-friends.git"
}

@test "git::url::parse 'https://github.com/rbuchss/git-friends.git' 1 2 3 4 5" {
  run git::url::parse 'https://github.com/rbuchss/git-friends.git' 1 2 3 4 5

  assert_success
  assert_output "https://
github.com
/
rbuchss
git-friends.git"
}

@test "git::url::parse 'git@github.com:rbuchss/git-friends.git' 2 3 4" {
  run git::url::parse 'git@github.com:rbuchss/git-friends.git' 2 3 4

  assert_success
  assert_output "github.com
:
rbuchss"
}

@test "git::url::is_valid 'git@github.com:rbuchss/git-friends.git'" {
  run git::url::is_valid 'git@github.com:rbuchss/git-friends.git'

  assert_success
}

@test "git::url::is_valid 'https://github.com/rbuchss/git-friends.git'" {
  run git::url::is_valid 'https://github.com/rbuchss/git-friends.git'

  assert_success
}

@test "git::url::is_valid 'http://github.com/rbuchss/git-friends.git'" {
  run git::url::is_valid 'http://github.com/rbuchss/git-friends.git'

  assert_success
}

@test "git::url::is_valid 'ssh://git@github.com/rbuchss/git-friends.git'" {
  run git::url::is_valid 'ssh://git@github.com/rbuchss/git-friends.git'

  assert_success
}

@test "git::url::is_valid 'ssh://github.com/rbuchss/git-friends.git'" {
  run git::url::is_valid 'ssh://github.com/rbuchss/git-friends.git'

  assert_success
}

@test "git::url::is_valid 'ssh://git@github.com:2222/rbuchss/git-friends.git'" {
  run git::url::is_valid 'ssh://git@github.com:2222/rbuchss/git-friends.git'

  assert_success
}

@test "git::url::is_valid 'git://github.com/rbuchss/git-friends.git'" {
  run git::url::is_valid 'git://github.com/rbuchss/git-friends.git'

  assert_success
}

@test "git::url::is_valid 'git://github.com:9418/rbuchss/git-friends.git'" {
  run git::url::is_valid 'git://github.com:9418/rbuchss/git-friends.git'

  assert_success
}

@test "git::url::is_valid 'file:///home/user/repos/project.git'" {
  run git::url::is_valid 'file:///home/user/repos/project.git'

  assert_success
}

@test "git::url::is_valid 'file:///tmp/source'" {
  run git::url::is_valid 'file:///tmp/source'

  assert_success
}

@test "git::url::is_valid 'file://localhost/repos/project.git'" {
  run git::url::is_valid 'file://localhost/repos/project.git'

  assert_success
}

@test "git::url::is_valid 'file://'" {
  run git::url::is_valid 'file://'

  assert_failure
}

@test "git::url::is_valid 'file:///'" {
  run git::url::is_valid 'file:///'

  assert_failure
}

@test "git::url::is_valid 'not-valid://github.com/rbuchss/git-friends.git'" {
  run git::url::is_valid 'not-valid://github.com/rbuchss/git-friends.git'

  assert_failure
}

@test "git::url::is_valid 'https://github.com/rbuchss'" {
  run git::url::is_valid 'https://github.com/rbuchss'

  assert_failure
}

@test "git::url::is_valid 'not-a-url'" {
  run git::url::is_valid 'not-a-url'

  assert_failure
}

@test "git::url::is_valid ''" {
  run git::url::is_valid ''

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

@test "git::url::domain 'ssh://git@github.com/rbuchss/git-friends.git'" {
  run git::url::domain 'ssh://git@github.com/rbuchss/git-friends.git'

  assert_success
  assert_output 'github.com'
}

@test "git::url::domain 'ssh://git@github.com:2222/rbuchss/git-friends.git' strips port" {
  run git::url::domain 'ssh://git@github.com:2222/rbuchss/git-friends.git'

  assert_success
  assert_output 'github.com'
}

@test "git::url::domain 'file:///tmp/source' returns implicit localhost" {
  run git::url::domain 'file:///tmp/source'

  assert_success
  assert_output 'localhost'
}

@test "git::url::domain 'file://myhost/repos/project.git'" {
  run git::url::domain 'file://myhost/repos/project.git'

  assert_success
  assert_output 'myhost'
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

@test "git::url::repo_name 'git@github.com:rbuchss/git-friends.git'" {
  run git::url::repo_name 'git@github.com:rbuchss/git-friends.git'

  assert_success
  assert_output 'git-friends'
}

@test "git::url::repo_name 'https://github.com/rbuchss/git-friends.git'" {
  run git::url::repo_name 'https://github.com/rbuchss/git-friends.git'

  assert_success
  assert_output 'git-friends'
}

@test "git::url::repo_name 'https://github.com/rbuchss/git-friends'" {
  run git::url::repo_name 'https://github.com/rbuchss/git-friends'

  assert_success
  assert_output 'git-friends'
}

@test "git::url::repo_name 'ssh://git@github.com/rbuchss/git-friends.git'" {
  run git::url::repo_name 'ssh://git@github.com/rbuchss/git-friends.git'

  assert_success
  assert_output 'git-friends'
}

@test "git::url::repo_name 'git://github.com/rbuchss/git-friends.git'" {
  run git::url::repo_name 'git://github.com/rbuchss/git-friends.git'

  assert_success
  assert_output 'git-friends'
}

@test "git::url::repo_name 'file:///home/user/repos/project.git'" {
  run git::url::repo_name 'file:///home/user/repos/project.git'

  assert_success
  assert_output 'project'
}

@test "git::url::repo_name 'file:///tmp/source'" {
  run git::url::repo_name 'file:///tmp/source'

  assert_success
  assert_output 'source'
}

@test "git::url::repo_name 'file://localhost/repos/project.git'" {
  run git::url::repo_name 'file://localhost/repos/project.git'

  assert_success
  assert_output 'project'
}

@test "git::url::repo_name 'file:///deep/nested/path/my-repo'" {
  run git::url::repo_name 'file:///deep/nested/path/my-repo'

  assert_success
  assert_output 'my-repo'
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

@test "git::url::protocol 'ssh://git@github.com/rbuchss/git-friends.git'" {
  run git::url::protocol 'ssh://git@github.com/rbuchss/git-friends.git'

  assert_success
  assert_output 'ssh'
}

@test "git::url::protocol 'git://github.com/rbuchss/git-friends.git'" {
  run git::url::protocol 'git://github.com/rbuchss/git-friends.git'

  assert_success
  assert_output 'git'
}

@test "git::url::protocol 'file:///home/user/repos/project.git'" {
  run git::url::protocol 'file:///home/user/repos/project.git'

  assert_success
  assert_output 'file'
}

@test "git::url::protocol 'file://localhost/repos/project.git'" {
  run git::url::protocol 'file://localhost/repos/project.git'

  assert_success
  assert_output 'file'
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

@test "git::url::change_user 'ssh://git@github.com/rbuchss/git-friends.git' 'someone'" {
  run git::url::change_user 'ssh://git@github.com/rbuchss/git-friends.git' 'someone'

  assert_success
  assert_output 'ssh://git@github.com/someone/git-friends.git'
}

@test "git::url::change_user 'git://github.com/rbuchss/git-friends.git' 'someone'" {
  run git::url::change_user 'git://github.com/rbuchss/git-friends.git' 'someone'

  assert_success
  assert_output 'git://github.com/someone/git-friends.git'
}

@test "git::url::change_user 'file:///home/user/repos/project.git' 'someone'" {
  run --separate-stderr git::url::change_user 'file:///home/user/repos/project.git' 'someone'

  assert_failure
  refute_output
}

@test "git::url::change_user 'not-valid://github.com/rbuchss/git-friends.git' 'someone'" {
  run git::url::change_user 'not-vaild://github.com/rbuchss/git-friends.git' 'someone'

  assert_failure
  refute_output
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

@test "git::url::prefix_for_protocol 'file'" {
  run git::url::prefix_for_protocol 'file'

  assert_success
  assert_output 'file://'
}

@test "git::url::prefix_for_protocol 'git'" {
  run git::url::prefix_for_protocol 'git'

  assert_success
  assert_output 'git://'
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

@test "git::url::separator_for_protocol 'file'" {
  run git::url::separator_for_protocol 'file'

  assert_success
  assert_output '/'
}

@test "git::url::separator_for_protocol 'git'" {
  run git::url::separator_for_protocol 'git'

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

@test "git::url::change_protocol 'ssh://git@github.com/rbuchss/git-friends.git' 'https'" {
  run git::url::change_protocol 'ssh://git@github.com/rbuchss/git-friends.git' 'https'

  assert_success
  assert_output 'https://github.com/rbuchss/git-friends.git'
}

@test "git::url::change_protocol 'git://github.com/rbuchss/git-friends.git' 'ssh'" {
  run git::url::change_protocol 'git://github.com/rbuchss/git-friends.git' 'ssh'

  assert_success
  assert_output 'git@github.com:rbuchss/git-friends.git'
}

@test "git::url::change_protocol 'git@github.com:rbuchss/git-friends.git' 'not-valid'" {
  run git::url::change_protocol 'git@github.com:rbuchss/git-friends.git' 'not-valid'

  assert_failure
}

@test "git::url::change_protocol 'file:///home/user/repos/project.git' 'ssh'" {
  run --separate-stderr git::url::change_protocol 'file:///home/user/repos/project.git' 'ssh'

  assert_failure
  refute_output
}

@test "git::url::change_protocol 'git@github.com:rbuchss/git-friends.git' 'file'" {
  run --separate-stderr git::url::change_protocol 'git@github.com:rbuchss/git-friends.git' 'file'

  assert_failure
  refute_output
}

@test "git::url::change_protocol 'not-valid://github.com/rbuchss/git-friends.git' 'ssh'" {
  run git::url::change_protocol 'not-vaild://github.com/rbuchss/git-friends.git' 'ssh'

  assert_failure
  refute_output
}

# --- Range expansion tests ---

@test "git::url::parse range 1:6 returns all 5 groups" {
  run git::url::parse 'git@github.com:rbuchss/git-friends.git' 1:6

  assert_success
  assert_output "git@
github.com
:
rbuchss
git-friends.git"
}

@test "git::url::parse range 2:5 returns groups 2, 3, 4" {
  run git::url::parse 'git@github.com:rbuchss/git-friends.git' 2:5

  assert_success
  assert_output "github.com
:
rbuchss"
}

@test "git::url::parse mixed range and index 1:4 5" {
  run git::url::parse 'git@github.com:rbuchss/git-friends.git' 1:4 5

  assert_success
  assert_output "git@
github.com
:
git-friends.git"
}

@test "git::url::parse open-end range 1:" {
  run git::url::parse 'git@github.com:rbuchss/git-friends.git' 1:

  assert_success
  assert_output "git@
github.com
:
rbuchss
git-friends.git"
}

@test "git::url::parse open-start range :3" {
  run git::url::parse 'git@github.com:rbuchss/git-friends.git' :3

  assert_success
  assert_output "git@
github.com"
}

@test "git::url::parse fully open range :" {
  run git::url::parse 'git@github.com:rbuchss/git-friends.git' :

  assert_success
  assert_output "git@
github.com
:
rbuchss
git-friends.git"
}

# --- Range validation: out of bounds ---

@test "git::url::parse index 0 fails with out of range error" {
  run --separate-stderr git::url::parse 'git@github.com:rbuchss/git-friends.git' 0

  assert_failure
  assert_stderr --partial 'out of range'
}

@test "git::url::parse range 0:3 fails with out of bounds error" {
  run --separate-stderr git::url::parse 'git@github.com:rbuchss/git-friends.git' 0:3

  assert_failure
  assert_stderr --partial 'out of bounds'
}

@test "git::url::parse range 1:7 fails with out of bounds error" {
  run --separate-stderr git::url::parse 'git@github.com:rbuchss/git-friends.git' 1:7

  assert_failure
  assert_stderr --partial 'out of bounds'
}

# --- Range validation: bad syntax ---

@test "git::url::parse non-numeric index fails" {
  run --separate-stderr git::url::parse 'git@github.com:rbuchss/git-friends.git' abc

  assert_failure
  assert_stderr --partial 'not a valid index'
}

@test "git::url::parse inverted range 3:1 fails" {
  run --separate-stderr git::url::parse 'git@github.com:rbuchss/git-friends.git' 3:1

  assert_failure
  assert_stderr --partial 'empty or inverted'
}

@test "git::url::parse empty range 3:3 fails" {
  run --separate-stderr git::url::parse 'git@github.com:rbuchss/git-friends.git' 3:3

  assert_failure
  assert_stderr --partial 'empty or inverted'
}
