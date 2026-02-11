#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/config.sh'

@test "git::config::exists 'git-friends.missing'" {
  run git::config::exists \
    'git-friends.missing' \
    --file "$(fixture 'gitconfig')"

  assert_failure
  refute_output
}

@test "git::config::exists 'git-friends.in-fixture'" {
  run git::config::exists \
    'git-friends.in-fixture' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_null 'git-friends.missing'" {
  run git::config::is_null \
    'git-friends.missing' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_null 'git-friends.in-fixture'" {
  run git::config::is_null \
    'git-friends.in-fixture' \
    --file "$(fixture 'gitconfig')"

  assert_failure
  refute_output
}

@test "git::config::is_true 'git-friends.literal-true'" {
  run git::config::is_true \
    'git-friends.literal-true' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_truthy 'git-friends.literal-true'" {
  run git::config::is_truthy \
    'git-friends.literal-true' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_false 'git-friends.literal-true'" {
  run git::config::is_false \
    'git-friends.literal-true' \
    --file "$(fixture 'gitconfig')"

  assert_failure 1
  refute_output
}

@test "git::config::is_falsey 'git-friends.literal-true'" {
  run git::config::is_falsey \
    'git-friends.literal-true' \
    --file "$(fixture 'gitconfig')"

  assert_failure
  refute_output
}

@test "git::config::is_true 'git-friends.literal-false'" {
  run git::config::is_true \
    'git-friends.literal-false' \
    --file "$(fixture 'gitconfig')"

  assert_failure 1
  refute_output
}

@test "git::config::is_truthy 'git-friends.literal-false'" {
  run git::config::is_truthy \
    'git-friends.literal-false' \
    --file "$(fixture 'gitconfig')"

  assert_failure
  refute_output
}

@test "git::config::is_false 'git-friends.literal-false'" {
  run git::config::is_false \
    'git-friends.literal-false' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_falsey 'git-friends.literal-false'" {
  run git::config::is_falsey \
    'git-friends.literal-false' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_true 'git-friends.literal-yes'" {
  run git::config::is_true \
    'git-friends.literal-yes' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_truthy 'git-friends.literal-yes'" {
  run git::config::is_truthy \
    'git-friends.literal-yes' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_false 'git-friends.literal-yes'" {
  run git::config::is_false \
    'git-friends.literal-yes' \
    --file "$(fixture 'gitconfig')"

  assert_failure 1
  refute_output
}

@test "git::config::is_falsey 'git-friends.literal-yes'" {
  run git::config::is_falsey \
    'git-friends.literal-yes' \
    --file "$(fixture 'gitconfig')"

  assert_failure
  refute_output
}

@test "git::config::is_true 'git-friends.literal-no'" {
  run git::config::is_true \
    'git-friends.literal-no' \
    --file "$(fixture 'gitconfig')"

  assert_failure 1
  refute_output
}

@test "git::config::is_truthy 'git-friends.literal-no'" {
  run git::config::is_truthy \
    'git-friends.literal-no' \
    --file "$(fixture 'gitconfig')"

  assert_failure
  refute_output
}

@test "git::config::is_false 'git-friends.literal-no'" {
  run git::config::is_false \
    'git-friends.literal-no' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_falsey 'git-friends.literal-no'" {
  run git::config::is_falsey \
    'git-friends.literal-no' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_true 'git-friends.literal-on'" {
  run git::config::is_true \
    'git-friends.literal-on' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_truthy 'git-friends.literal-on'" {
  run git::config::is_truthy \
    'git-friends.literal-on' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_false 'git-friends.literal-on'" {
  run git::config::is_false \
    'git-friends.literal-on' \
    --file "$(fixture 'gitconfig')"

  assert_failure 1
  refute_output
}

@test "git::config::is_falsey 'git-friends.literal-on'" {
  run git::config::is_falsey \
    'git-friends.literal-on' \
    --file "$(fixture 'gitconfig')"

  assert_failure
  refute_output
}

@test "git::config::is_true 'git-friends.literal-off'" {
  run git::config::is_true \
    'git-friends.literal-off' \
    --file "$(fixture 'gitconfig')"

  assert_failure 1
  refute_output
}

@test "git::config::is_truthy 'git-friends.literal-off'" {
  run git::config::is_truthy \
    'git-friends.literal-off' \
    --file "$(fixture 'gitconfig')"

  assert_failure
  refute_output
}

@test "git::config::is_false 'git-friends.literal-off'" {
  run git::config::is_false \
    'git-friends.literal-off' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_falsey 'git-friends.literal-off'" {
  run git::config::is_falsey \
    'git-friends.literal-off' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_true 'git-friends.num-1'" {
  run git::config::is_true \
    'git-friends.num-1' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_truthy 'git-friends.num-1'" {
  run git::config::is_truthy \
    'git-friends.num-1' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_false 'git-friends.num-1'" {
  run git::config::is_false \
    'git-friends.num-1' \
    --file "$(fixture 'gitconfig')"

  assert_failure 1
  refute_output
}

@test "git::config::is_falsey 'git-friends.num-1'" {
  run git::config::is_falsey \
    'git-friends.num-1' \
    --file "$(fixture 'gitconfig')"

  assert_failure
  refute_output
}

@test "git::config::is_true 'git-friends.num-0'" {
  run git::config::is_true \
    'git-friends.num-0' \
    --file "$(fixture 'gitconfig')"

  assert_failure 1
  refute_output
}

@test "git::config::is_truthy 'git-friends.num-0'" {
  run git::config::is_truthy \
    'git-friends.num-0' \
    --file "$(fixture 'gitconfig')"

  assert_failure
  refute_output
}

@test "git::config::is_false 'git-friends.num-0'" {
  run git::config::is_false \
    'git-friends.num-0' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_falsey 'git-friends.num-0'" {
  run git::config::is_falsey \
    'git-friends.num-0' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_true 'git-friends.implicit-true'" {
  run git::config::is_true \
    'git-friends.implicit-true' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_truthy 'git-friends.implicit-true'" {
  run git::config::is_truthy \
    'git-friends.implicit-true' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::is_false 'git-friends.implicit-true'" {
  run git::config::is_false \
    'git-friends.implicit-true' \
    --file "$(fixture 'gitconfig')"

  assert_failure 1
  refute_output
}

@test "git::config::is_falsey 'git-friends.implicit-true'" {
  run git::config::is_falsey \
    'git-friends.implicit-true' \
    --file "$(fixture 'gitconfig')"

  assert_failure
  refute_output
}

@test "git::config::is_true 'git-friends.blarg'" {
  local config

  config="$(fixture 'gitconfig')"

  run git::config::is_true \
    'git-friends.blarg' \
    --file "${config}"

  assert_failure 128
  assert_output "fatal: bad boolean config value 'blarg' for 'git-friends.blarg'"
}

@test "git::config::is_truthy 'git-friends.blarg'" {
  local config

  config="$(fixture 'gitconfig')"

  run git::config::is_truthy \
    'git-friends.blarg' \
    --file "${config}"

  assert_success
}

@test "git::config::is_false 'git-friends.blarg'" {
  local config

  config="$(fixture 'gitconfig')"

  run git::config::is_false \
    'git-friends.blarg' \
    --file "${config}"

  assert_failure 128
  assert_output "fatal: bad boolean config value 'blarg' for 'git-friends.blarg'"
}

@test "git::config::is_falsey 'git-friends.blarg'" {
  local config

  config="$(fixture 'gitconfig')"

  run git::config::is_falsey \
    'git-friends.blarg' \
    --file "${config}"

  assert_failure
}

@test "git::config::is_true 'git-friends.missing'" {
  run git::config::is_true \
    'git-friends.missing' \
    --file "$(fixture 'gitconfig')"

  assert_failure 2
  refute_output
}

@test "git::config::is_truthy 'git-friends.missing'" {
  run git::config::is_truthy \
    'git-friends.missing' \
    --file "$(fixture 'gitconfig')"

  assert_failure
  refute_output
}

@test "git::config::is_false 'git-friends.missing'" {
  run git::config::is_false \
    'git-friends.missing' \
    --file "$(fixture 'gitconfig')"

  assert_failure 2
  refute_output
}

@test "git::config::is_falsey 'git-friends.missing'" {
  run git::config::is_falsey \
    'git-friends.missing' \
    --file "$(fixture 'gitconfig')"

  assert_success
  refute_output
}

@test "git::config::get_all 'git-friends.single-value" {
  run git::config::get_all \
    'git-friends.single-value' \
    --file "$(fixture 'gitconfig')"

  assert_success
  assert_output 'yarp'
}

@test "git::config::get_all 'git-friends.multi-value" {
  run git::config::get_all \
    'git-friends.multi-value' \
    --file "$(fixture 'gitconfig')"

  assert_success
  assert_output <<TEXT
yarp
carp
narp
TEXT
}

@test "git::config::get 'git-friends.multi-value" {
  run git::config::get \
    'git-friends.multi-value' \
    --file "$(fixture 'gitconfig')"

  assert_success
  assert_output 'narp'
}

@test "git::config::get_all 'git-friends.missing'" {
  run git::config::get_all \
    'git-friends.missing' \
    --file "$(fixture 'gitconfig')"

  assert_failure
  refute_output
}

@test "git::config::get 'git-friends.missing'" {
  run git::config::get \
    'git-friends.missing' \
    --file "$(fixture 'gitconfig')"

  assert_failure
  refute_output
}

################################################################################
# git::config::group
################################################################################

# bats test_tags=git::config::group
@test "git::config::group returns matching config entries from fixture" {
  run git::config::group \
    'git-friends.literal' \
    --file "$(fixture 'gitconfig')"

  assert_success
  assert_line 'git-friends.literal-true true'
  assert_line 'git-friends.literal-false false'
  assert_line 'git-friends.literal-yes yes'
  assert_line 'git-friends.literal-no no'
  assert_line 'git-friends.literal-on on'
  assert_line 'git-friends.literal-off off'
}

# bats test_tags=git::config::group
@test "git::config::group returns nothing for missing prefix from fixture" {
  run git::config::group \
    'nonexistent' \
    --file "$(fixture 'gitconfig')"

  assert_failure
  refute_output
}

# bats test_tags=git::config::group
@test "git::config::group returns matching config entries from repo" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" config test-group.key-one 'value-one'
  git -C "${repo_dir}" config test-group.key-two 'value-two'
  cd "${repo_dir}"

  run git::config::group 'test-group'
  assert_success
  assert_line 'test-group.key-one value-one'
  assert_line 'test-group.key-two value-two'
}

# bats test_tags=git::config::group
@test "git::config::group returns nothing for missing prefix from repo" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::config::group 'nonexistent'
  assert_failure
  refute_output
}

################################################################################
# git::config::aliases
################################################################################

# bats test_tags=git::config::aliases
@test "git::config::aliases lists all aliases when no search term given" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" config alias.co 'checkout'
  git -C "${repo_dir}" config alias.br 'branch'
  git -C "${repo_dir}" config alias.st 'status'
  cd "${repo_dir}"

  run git::config::aliases
  assert_success
  assert_output --regexp 'ALIAS'
  assert_output --regexp 'co'
  assert_output --regexp 'br'
  assert_output --regexp 'st'
}

# bats test_tags=git::config::aliases
@test "git::config::aliases filters by search term in alias name" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" config alias.co 'checkout'
  git -C "${repo_dir}" config alias.br 'branch'
  git -C "${repo_dir}" config alias.st 'status'
  cd "${repo_dir}"

  run git::config::aliases 'co'
  assert_success
  assert_output --regexp 'co'
  refute_output --regexp 'br.*branch'
}

# bats test_tags=git::config::aliases
@test "git::config::aliases filters by search term in command value" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" config alias.co 'checkout'
  git -C "${repo_dir}" config alias.br 'branch'
  cd "${repo_dir}"

  run git::config::aliases 'branch'
  assert_success
  assert_output --regexp 'br'
  refute_output --regexp 'co.*checkout'
}

################################################################################
# git::dir
################################################################################

# bats test_tags=git::dir
@test "git::dir returns git directory without arguments" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::dir
  assert_success
  assert_output --regexp '\.git$'
}

# bats test_tags=git::dir
@test "git::dir resolves git path with arguments" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::dir 'hooks/pre-commit'
  assert_success
  assert_output --regexp '\.git/hooks/pre-commit$'
}

# bats test_tags=git::config::get
@test "git::config::get returns config value" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"
  git config --local test.key "hello-world"

  run git::config::get 'test.key'
  assert_success
  assert_output 'hello-world'
}

# bats test_tags=git::config::get
@test "git::config::get returns failure for missing key" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::config::get 'test.nonexistent'
  assert_failure
}

# bats test_tags=git::config::get
@test "git::config::get passes additional flags" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"
  git config --local test.flagkey "flag-value"

  run git::config::get 'test.flagkey' --local
  assert_success
  assert_output 'flag-value'
}

# bats test_tags=git::config::get_all
@test "git::config::get_all returns all values for multi-valued key" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"
  git config --local --add test.multi "value1"
  git config --local --add test.multi "value2"
  git config --local --add test.multi "value3"

  run git::config::get_all 'test.multi'
  assert_success
  assert_line --index 0 'value1'
  assert_line --index 1 'value2'
  assert_line --index 2 'value3'
}

# bats test_tags=git::config::get_all
@test "git::config::get_all returns failure for missing key" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::config::get_all 'test.nonexistent'
  assert_failure
}

# bats test_tags=git::config::get_all
@test "git::config::get_all passes additional flags" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"
  git config --local --add test.flagmulti "a"
  git config --local --add test.flagmulti "b"

  run git::config::get_all 'test.flagmulti' --local
  assert_success
  assert_line --index 0 'a'
  assert_line --index 1 'b'
}

# bats test_tags=git::config::group
@test "git::config::group returns matching config entries" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"
  git config --local mygroup.alpha "one"
  git config --local mygroup.beta "two"
  git config --local other.gamma "three"

  run git::config::group 'mygroup'
  assert_success
  assert_line --partial 'mygroup.alpha'
  assert_line --partial 'mygroup.beta'
  refute_line --partial 'other.gamma'
}

# bats test_tags=git::config::group
@test "git::config::group returns failure when no matches" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::config::group 'nonexistent'
  assert_failure
}

# bats test_tags=git::config::group
@test "git::config::group passes additional flags" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"
  git config --local flaggroup.item "val"

  run git::config::group 'flaggroup' --local
  assert_success
  assert_line --partial 'flaggroup.item'
}
