#!/bin/bash

# Bash source guard - prevents sourcing this file multiple times
[[ -n "${GIT_FRIENDS__MODULE__LOADED}" ]] && return
readonly GIT_FRIENDS__MODULE__LOADED=1

# Allow environment to override (e.g., Docker/CI can pre-set GIT_FRIENDS_MODULE_SRC_DIR)
if [[ -z "${GIT_FRIENDS_MODULE_SRC_DIR}" ]]; then
  if [[ -n "${BASH_SOURCE[0]}" && "${BASH_SOURCE[0]}" != '/' ]]; then
    export GIT_FRIENDS_MODULE_SRC_DIR="${BASH_SOURCE[0]%/*}"
  fi
fi

# Derive home directory (parent of project dir) for module name resolution.
# e.g., /Users/russ/.git-friends/src → /Users/russ
if [[ -z "${GIT_FRIENDS_MODULE_HOME_DIR}" ]]; then
  GIT_FRIENDS_MODULE_HOME_DIR="${GIT_FRIENDS_MODULE_SRC_DIR%/*/*}"
  export GIT_FRIENDS_MODULE_HOME_DIR
fi

GIT_FRIENDS_MODULES_LOADED=()
GIT_FRIENDS_MODULES_EXPORTED=()
GIT_FRIENDS_MODULES_ENABLED=()

GIT_FRIENDS_MODULE_LOAD_ACTION='__load__'
GIT_FRIENDS_MODULE_UNLOAD_ACTION='__unload__'
GIT_FRIENDS_MODULE_EXPORT_ACTION='__export__'
GIT_FRIENDS_MODULE_RECALL_ACTION='__recall__'
GIT_FRIENDS_MODULE_ENABLE_ACTION='__enable__'
GIT_FRIENDS_MODULE_DISABLE_ACTION='__disable__'

# Bash source guard helper like c #pragma once - will skip sourcing a file again if already sourced.
#
# Usage:
#   git::__module__::load || return 0 # File guard name defaults to the filepath derived module name
#   git::__module__::load MY_AWESOME_LIB || return 0 # File guard name is MY_AWESOME_LIB
#
# Returns:
#   0 - file should be sourced
#   1 - file should not be sourced
#
# Note this requires the `|| return 0` logical compound since bash source must exit early.
#
function git::__module__::load {
  local \
    module="$1" \
    should_source_status=0 \
    should_not_source_status=1

  # Generates module based on filename if none specified
  if [[ -z "${module}" ]]; then
    # When caller info is unavailable, e.g. Claude Code shells where BASH_SOURCE
    # is empty, allow the file to be sourced anyway. We just can't track it.
    if ! git::__module__::__get_module_name__ module "$(caller)"; then
      return "${should_source_status}"
    fi
  fi

  if git::__module__::__action__ \
    "${module}" \
    "${GIT_FRIENDS_MODULE_LOAD_ACTION}"; then
    GIT_FRIENDS_MODULES_LOADED+=("${module}")

    if git::__module__::__function_exists__ 'git::logger::trace'; then
      local trace_message
      printf -v trace_message '  %s\n' "${GIT_FRIENDS_MODULES_LOADED[@]}"
      git::logger::trace -- "-> GIT_FRIENDS_MODULES_LOADED: [\n${trace_message}]"
    fi

    return "${should_source_status}"
  else
    return "${should_not_source_status}"
  fi
}

function git::__module__::is_loaded {
  local module="$1"

  git::__module__::__is_in_state__ \
    "${module}" \
    "${GIT_FRIENDS_MODULE_LOAD_ACTION}" \
    3
}

function git::__module__::unload {
  local \
    module \
    modules=("$@")

  # Generates module based on filename if none specified
  if ((${#modules[@]} == 0)); then
    # Fail-safe to source file if BASH_SOURCE stack only points to this file
    if ! git::__module__::__get_module_name__ module "$(caller)"; then
      return 1
    fi

    modules=("${module}")
  fi

  for module in "${modules[@]}"; do
    if git::__module__::__action__ \
      "${module}" \
      "${GIT_FRIENDS_MODULE_UNLOAD_ACTION}"; then
      for index in "${!GIT_FRIENDS_MODULES_LOADED[@]}"; do
        if [[ "${GIT_FRIENDS_MODULES_LOADED[index]}" == "${module}" ]]; then
          unset 'GIT_FRIENDS_MODULES_LOADED[index]'
          break # no duplicates should exist so exit early is fine
        fi
      done
    fi
  done
}

function git::__module__::unload_all {
  git::__module__::unload "${GIT_FRIENDS_MODULES_LOADED[@]}"
}

function git::__module__::is_unloaded {
  local module="$1"

  git::__module__::__is_in_state__ \
    "${module}" \
    "${GIT_FRIENDS_MODULE_UNLOAD_ACTION}" \
    3
}

function git::__module__::export {
  local \
    module \
    modules=("$@")

  # Generates module based on filename if none specified
  if ((${#modules[@]} == 0)); then
    if ! git::__module__::__get_module_name__ module "$(caller)"; then
      return 1
    fi

    modules=("${module}")
  fi

  for module in "${modules[@]}"; do
    if git::__module__::__action__ \
      "${module}" \
      "${GIT_FRIENDS_MODULE_EXPORT_ACTION}" \
      'git::__module__::__action__::__module_action_handler__'; then
      GIT_FRIENDS_MODULES_EXPORTED+=("${module}")

      if git::__module__::__function_exists__ 'git::logger::trace'; then
        local trace_message
        printf -v trace_message '  %s\n' "${GIT_FRIENDS_MODULES_EXPORTED[@]}"
        git::logger::trace -- "-> GIT_FRIENDS_MODULES_EXPORTED: [\n${trace_message}]"
      fi
    fi
  done
}

function git::__module__::is_exported {
  local module="$1"

  git::__module__::__is_in_state__ \
    "${module}" \
    "${GIT_FRIENDS_MODULE_EXPORT_ACTION}" \
    3
}

function git::__module__::recall {
  local \
    module \
    modules=("$@")

  # Generates module based on filename if none specified
  if ((${#modules[@]} == 0)); then
    if ! git::__module__::__get_module_name__ module "$(caller)"; then
      return 1
    fi

    modules=("${module}")
  fi

  for module in "${modules[@]}"; do
    if git::__module__::__action__ \
      "${module}" \
      "${GIT_FRIENDS_MODULE_RECALL_ACTION}" \
      'git::__module__::__action__::__module_action_handler__'; then
      for index in "${!GIT_FRIENDS_MODULES_EXPORTED[@]}"; do
        if [[ "${GIT_FRIENDS_MODULES_EXPORTED[index]}" == "${module}" ]]; then
          unset 'GIT_FRIENDS_MODULES_EXPORTED[index]'
          break # no duplicates should exist so exit early is fine
        fi
      done
    fi
  done
}

function git::__module__::recall_all {
  git::__module__::recall "${GIT_FRIENDS_MODULES_EXPORTED[@]}"
}

function git::__module__::is_recalled {
  local module="$1"

  git::__module__::__is_in_state__ \
    "${module}" \
    "${GIT_FRIENDS_MODULE_RECALL_ACTION}" \
    3
}

function git::__module__::enable {
  local \
    module \
    modules=("$@")

  # Generates module based on filename if none specified
  if ((${#modules[@]} == 0)); then
    if ! git::__module__::__get_module_name__ module "$(caller)"; then
      return 1
    fi

    modules=("${module}")
  fi

  for module in "${modules[@]}"; do
    if git::__module__::__action__ \
      "${module}" \
      "${GIT_FRIENDS_MODULE_ENABLE_ACTION}" \
      'git::__module__::__action__::__module_action_handler__'; then
      GIT_FRIENDS_MODULES_ENABLED+=("${module}")

      if git::__module__::__function_exists__ 'git::logger::trace'; then
        local trace_message
        printf -v trace_message '  %s\n' "${GIT_FRIENDS_MODULES_ENABLED[@]}"
        git::logger::trace -- "-> GIT_FRIENDS_MODULES_ENABLED: [\n${trace_message}]"
      fi
    fi
  done
}

function git::__module__::is_enabled {
  local module="$1"

  git::__module__::__is_in_state__ \
    "${module}" \
    "${GIT_FRIENDS_MODULE_ENABLE_ACTION}" \
    3
}

function git::__module__::disable {
  local \
    module \
    modules=("$@")

  # Generates module based on filename if none specified
  if ((${#modules[@]} == 0)); then
    if ! git::__module__::__get_module_name__ module "$(caller)"; then
      return 1
    fi

    modules=("${module}")
  fi

  for module in "${modules[@]}"; do
    if git::__module__::__action__ \
      "${module}" \
      "${GIT_FRIENDS_MODULE_DISABLE_ACTION}" \
      'git::__module__::__action__::__module_action_handler__'; then
      for index in "${!GIT_FRIENDS_MODULES_ENABLED[@]}"; do
        if [[ "${GIT_FRIENDS_MODULES_ENABLED[index]}" == "${module}" ]]; then
          unset 'GIT_FRIENDS_MODULES_ENABLED[index]'
          break # no duplicates should exist so exit early is fine
        fi
      done
    fi
  done
}

function git::__module__::disable_all {
  git::__module__::disable "${GIT_FRIENDS_MODULES_ENABLED[@]}"
}

function git::__module__::is_disabled {
  local module="$1"

  git::__module__::__is_in_state__ \
    "${module}" \
    "${GIT_FRIENDS_MODULE_DISABLE_ACTION}" \
    3
}

function git::__module__::__action__ {
  local \
    module="$1" \
    action="$2" \
    handler="$3" \
    module_action_function

  case "${action}" in
    "${GIT_FRIENDS_MODULE_LOAD_ACTION}") ;;
    "${GIT_FRIENDS_MODULE_UNLOAD_ACTION}") ;;
    "${GIT_FRIENDS_MODULE_EXPORT_ACTION}") ;;
    "${GIT_FRIENDS_MODULE_RECALL_ACTION}") ;;
    "${GIT_FRIENDS_MODULE_ENABLE_ACTION}") ;;
    "${GIT_FRIENDS_MODULE_DISABLE_ACTION}") ;;
    *)
      git::__module__::__invoke_function_if_exists__ \
        'git::logger::error' -c 2 \
        "Action: '${action}' is not valid"
      return 2
      ;;
  esac

  # Guard to do module action only if not already in desired state
  if git::__module__::__is_in_state__ "${module}" "${action}"; then
    git::__module__::__invoke_function_if_exists__ \
      'git::logger::trace' -c 3 \
      "Skipping: '${module}' since it is already in ${action} state"

    return 1
  fi

  if [[ -n "${handler}" ]]; then
    "${handler}" "${module}" "${action}"
  fi
}

function git::__module__::__action__::__module_action_handler__ {
  local \
    module="$1" \
    action="$2" \
    module_action_function

  module_action_function="${module}::${action}"

  if ! git::__module__::__function_exists__ "${module_action_function}"; then
    git::__module__::__invoke_function_if_exists__ \
      'git::logger::warning' -c 4 \
      "Skipping: '${module}' since it has no ${module_action_function} function defined"

    return 2
  fi

  git::__module__::__invoke_function_if_exists__ \
    'git::logger::trace' -c 4 "Invoking: '${module_action_function}'"

  "${module_action_function}"
}

function git::__module__::__is_in_state__ {
  local \
    module="$1" \
    action="$2" \
    log_caller_level="${3:-4}" \
    in_cache_response=0 \
    not_in_cache_response=1 \
    cache_element \
    cache=()

  case "${action}" in
    "${GIT_FRIENDS_MODULE_LOAD_ACTION}")
      cache=("${GIT_FRIENDS_MODULES_LOADED[@]}")
      ;;
    "${GIT_FRIENDS_MODULE_UNLOAD_ACTION}")
      cache=("${GIT_FRIENDS_MODULES_LOADED[@]}")
      in_cache_response=1
      not_in_cache_response=0
      ;;
    "${GIT_FRIENDS_MODULE_EXPORT_ACTION}")
      cache=("${GIT_FRIENDS_MODULES_EXPORTED[@]}")
      ;;
    "${GIT_FRIENDS_MODULE_RECALL_ACTION}")
      cache=("${GIT_FRIENDS_MODULES_EXPORTED[@]}")
      in_cache_response=1
      not_in_cache_response=0
      ;;
    "${GIT_FRIENDS_MODULE_ENABLE_ACTION}")
      cache=("${GIT_FRIENDS_MODULES_ENABLED[@]}")
      ;;
    "${GIT_FRIENDS_MODULE_DISABLE_ACTION}")
      cache=("${GIT_FRIENDS_MODULES_ENABLED[@]}")
      in_cache_response=1
      not_in_cache_response=0
      ;;
    *)
      git::__module__::__invoke_function_if_exists__ \
        'git::logger::error' -c "${log_caller_level}" \
        "Action: '${action}' is not valid"
      return 2
      ;;
  esac

  for cache_element in "${cache[@]}"; do
    if [[ "${module}" == "${cache_element}" ]]; then
      return "${in_cache_response}"
    fi
  done

  return "${not_in_cache_response}"
}

function git::__module__::__function_exists__ {
  declare -F "$1" >/dev/null 2>&1
}

function git::__module__::__invoke_function_if_exists__ {
  if git::__module__::__function_exists__ "$1"; then
    "$1" "${@:2}"
  fi
}

function git::__module__::__get_module_name__ {
  local \
    __output_var__="$1" \
    caller_info="$2" \
    source_filepath \
    relative_filepath \
    __module_name__

  source_filepath="${caller_info#* *}"

  if [[ -z "${source_filepath}" || "${source_filepath}" == 'NULL' ]]; then
    return 1
  fi

  # Strip home directory prefix to get project-relative path
  relative_filepath="${source_filepath/${GIT_FRIENDS_MODULE_HOME_DIR}/}"

  # Remove .sh extension
  __module_name__="${relative_filepath%.sh}"

  # Remove dots (e.g., .git-friends → git-friends)
  __module_name__="${__module_name__//./}"

  # Replace hyphens with underscores (e.g., git-friends → git_friends)
  __module_name__="${__module_name__//-/_}"

  # Replace directory separators with :: (e.g., /git_friends/src/ → ::git_friends::src::)
  __module_name__="${__module_name__//\//::}"

  # Strip leading ::
  __module_name__="${__module_name__#::}"

  # Remove ::src namespace
  __module_name__="${__module_name__/::src/}"

  # Map project name to namespace (git_friends:: → git::)
  __module_name__="${__module_name__/#git_friends::/git::}"

  printf -v "${__output_var__}" '%s' "${__module_name__}"
}
