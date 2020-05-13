#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/utility.sh"

function git::hooks::pre_commit() {
  local exit_status=0 \
    config_section='git-friends.pre-commit' \
    disabled \
    rule_name \
    rule_name_regexp='^.*pre-commit-test-([^\.]+).*$' \
    rule_flags \
    rules_to_skip=()

  if disabled="$(git config --get "${config_section}.disabled")" \
    && [[ "${disabled}" == 'true' ]]; then
      # Disabled so exit
      return "${exit_status}"
  fi

  if git diff --cached --quiet --exit-code; then
    # Nothing to commit so exit
    return "${exit_status}"
  fi

  local rules=(.git/hooks/pre-commit-test-*)

  # No rules exist so exit
  (( "${#rules[@]}" == 0 )) && return "${exit_status}"

  while IFS= read -r rule; do
    rules_to_skip+=("${rule//[[:blank:]]/}")
  done < <(git config --get "${config_section}.skip" | tr ',' '\n')

  echo 'Running pre-commit tests:'

  for rule in "${rules[@]}"; do
    rule_flags=()

    if [[ "${rule}" =~ $rule_name_regexp ]]; then
      rule_name="${BASH_REMATCH[1]}"
      git::utility::array_contains "${rule_name}" "${rules_to_skip[@]}" \
        && rule_flags+=('-n')
    fi

    "${rule}" "${rule_flags[@]}" || exit_status=$?
  done

  return "${exit_status}"
}
