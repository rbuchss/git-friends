#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/config.sh"
source "${BASH_SOURCE[0]%/*/*}/utility.sh"

function git::hooks::pre_commit() {
  local exit_status=0 \
    config_section='git-friends.pre-commit' \
    rule_name_regexp='^.*pre-commit-test-([^\.]+).*$' \
    rule_flags \
    rules_to_skip=()

  if git diff --cached --quiet --exit-code \
    || git::config::is_true "${config_section}.disabled"; then
      # Nothing to commit or disabled so exit
      return "${exit_status}"
  fi

  local rules=("$(git::dir)"/hooks/pre-commit-test-*)

  # No rules exist so exit
  (( "${#rules[@]}" == 0 )) && return "${exit_status}"

  while IFS= read -r rule; do
    rules_to_skip+=("${rule//[[:blank:]]/}")
  done < <(git::config::get_array "${config_section}.skip")

  echo 'Running pre-commit tests:'

  for rule in "${rules[@]}"; do
    rule_flags=()

    if [[ "${rule}" =~ $rule_name_regexp ]]; then
      git::utility::array_contains "${BASH_REMATCH[1]}" "${rules_to_skip[@]}" \
        && rule_flags+=('-n')
    fi

    "${rule}" "${rule_flags[@]}" || exit_status=$?
  done

  return "${exit_status}"
}
