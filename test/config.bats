#!/usr/bin/env bats

load test_helper

source "$(repo_root)/git-friends/src/config.sh"

@test "git::config::exists 'git-friends.missing'" {
  run git::config::exists 'git-friends.missing' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_no_output_exists
}

@test "git::config::exists 'git-friends.in-fixture'" {
  run git::config::exists 'git-friends.in-fixture' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_null 'git-friends.missing'" {
  run git::config::is_null 'git-friends.missing' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_null 'git-friends.in-fixture'" {
  run git::config::is_null 'git-friends.in-fixture' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_no_output_exists
}

@test "git::config::is_true 'git-friends.literal-true'" {
  run git::config::is_true 'git-friends.literal-true' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_truthy 'git-friends.literal-true'" {
  run git::config::is_truthy 'git-friends.literal-true' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_false 'git-friends.literal-true'" {
  run git::config::is_false 'git-friends.literal-true' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_exit_status 1
  assert_no_output_exists
}

@test "git::config::is_falsey 'git-friends.literal-true'" {
  run git::config::is_falsey 'git-friends.literal-true' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_no_output_exists
}

@test "git::config::is_true 'git-friends.literal-false'" {
  run git::config::is_true 'git-friends.literal-false' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_exit_status 1
  assert_no_output_exists
}

@test "git::config::is_truthy 'git-friends.literal-false'" {
  run git::config::is_truthy 'git-friends.literal-false' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_no_output_exists
}

@test "git::config::is_false 'git-friends.literal-false'" {
  run git::config::is_false 'git-friends.literal-false' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_falsey 'git-friends.literal-false'" {
  run git::config::is_falsey 'git-friends.literal-false' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_true 'git-friends.literal-yes'" {
  run git::config::is_true 'git-friends.literal-yes' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_truthy 'git-friends.literal-yes'" {
  run git::config::is_truthy 'git-friends.literal-yes' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_false 'git-friends.literal-yes'" {
  run git::config::is_false 'git-friends.literal-yes' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_exit_status 1
  assert_no_output_exists
}

@test "git::config::is_falsey 'git-friends.literal-yes'" {
  run git::config::is_falsey 'git-friends.literal-yes' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_no_output_exists
}

@test "git::config::is_true 'git-friends.literal-no'" {
  run git::config::is_true 'git-friends.literal-no' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_exit_status 1
  assert_no_output_exists
}

@test "git::config::is_truthy 'git-friends.literal-no'" {
  run git::config::is_truthy 'git-friends.literal-no' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_no_output_exists
}

@test "git::config::is_false 'git-friends.literal-no'" {
  run git::config::is_false 'git-friends.literal-no' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_falsey 'git-friends.literal-no'" {
  run git::config::is_falsey 'git-friends.literal-no' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_true 'git-friends.literal-on'" {
  run git::config::is_true 'git-friends.literal-on' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_truthy 'git-friends.literal-on'" {
  run git::config::is_truthy 'git-friends.literal-on' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_false 'git-friends.literal-on'" {
  run git::config::is_false 'git-friends.literal-on' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_exit_status 1
  assert_no_output_exists
}

@test "git::config::is_falsey 'git-friends.literal-on'" {
  run git::config::is_falsey 'git-friends.literal-on' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_no_output_exists
}

@test "git::config::is_true 'git-friends.literal-off'" {
  run git::config::is_true 'git-friends.literal-off' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_exit_status 1
  assert_no_output_exists
}

@test "git::config::is_truthy 'git-friends.literal-off'" {
  run git::config::is_truthy 'git-friends.literal-off' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_no_output_exists
}

@test "git::config::is_false 'git-friends.literal-off'" {
  run git::config::is_false 'git-friends.literal-off' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_falsey 'git-friends.literal-off'" {
  run git::config::is_falsey 'git-friends.literal-off' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_true 'git-friends.num-1'" {
  run git::config::is_true 'git-friends.num-1' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_truthy 'git-friends.num-1'" {
  run git::config::is_truthy 'git-friends.num-1' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_false 'git-friends.num-1'" {
  run git::config::is_false 'git-friends.num-1' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_exit_status 1
  assert_no_output_exists
}

@test "git::config::is_falsey 'git-friends.num-1'" {
  run git::config::is_falsey 'git-friends.num-1' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_no_output_exists
}

@test "git::config::is_true 'git-friends.num-0'" {
  run git::config::is_true 'git-friends.num-0' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_exit_status 1
  assert_no_output_exists
}

@test "git::config::is_truthy 'git-friends.num-0'" {
  run git::config::is_truthy 'git-friends.num-0' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_no_output_exists
}

@test "git::config::is_false 'git-friends.num-0'" {
  run git::config::is_false 'git-friends.num-0' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_falsey 'git-friends.num-0'" {
  run git::config::is_falsey 'git-friends.num-0' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_true 'git-friends.implicit-true'" {
  run git::config::is_true 'git-friends.implicit-true' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_truthy 'git-friends.implicit-true'" {
  run git::config::is_truthy 'git-friends.implicit-true' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::is_false 'git-friends.implicit-true'" {
  run git::config::is_false 'git-friends.implicit-true' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_exit_status 1
  assert_no_output_exists
}

@test "git::config::is_falsey 'git-friends.implicit-true'" {
  run git::config::is_falsey 'git-friends.implicit-true' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_no_output_exists
}

@test "git::config::is_true 'git-friends.blarg'" {
  local config="$(fixture 'gitconfig')"
  run git::config::is_true 'git-friends.blarg' \
    --file "${config}"
  assert_failure
  assert_exit_status 128
  assert_output "fatal: bad boolean config value 'blarg' for 'git-friends.blarg'"
}

@test "git::config::is_truthy 'git-friends.blarg'" {
  local config="$(fixture 'gitconfig')"
  run git::config::is_truthy 'git-friends.blarg' \
    --file "${config}"
  assert_success
}

@test "git::config::is_false 'git-friends.blarg'" {
  local config="$(fixture 'gitconfig')"
  run git::config::is_false 'git-friends.blarg' \
    --file "${config}"
  assert_failure
  assert_exit_status 128
  assert_output "fatal: bad boolean config value 'blarg' for 'git-friends.blarg'"
}

@test "git::config::is_falsey 'git-friends.blarg'" {
  local config="$(fixture 'gitconfig')"
  run git::config::is_falsey 'git-friends.blarg' \
    --file "${config}"
  assert_failure
}

@test "git::config::is_true 'git-friends.missing'" {
  run git::config::is_true 'git-friends.missing' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_exit_status 2
  assert_no_output_exists
}

@test "git::config::is_truthy 'git-friends.missing'" {
  run git::config::is_truthy 'git-friends.missing' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_no_output_exists
}

@test "git::config::is_false 'git-friends.missing'" {
  run git::config::is_false 'git-friends.missing' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_exit_status 2
  assert_no_output_exists
}

@test "git::config::is_falsey 'git-friends.missing'" {
  run git::config::is_falsey 'git-friends.missing' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_no_output_exists
}

@test "git::config::get_all 'git-friends.single-value" {
  run git::config::get_all 'git-friends.single-value' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_output 'yarp'
}

@test "git::config::get_all 'git-friends.multi-value" {
  run git::config::get_all 'git-friends.multi-value' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_output <<TEXT
yarp
carp
narp
TEXT
}

@test "git::config::get 'git-friends.multi-value" {
  run git::config::get 'git-friends.multi-value' \
    --file "$(fixture 'gitconfig')"
  assert_success
  assert_output 'narp'
}

@test "git::config::get_all 'git-friends.missing'" {
  run git::config::get_all 'git-friends.missing' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_no_output_exists
}

@test "git::config::get 'git-friends.missing'" {
  run git::config::get 'git-friends.missing' \
    --file "$(fixture 'gitconfig')"
  assert_failure
  assert_no_output_exists
}
