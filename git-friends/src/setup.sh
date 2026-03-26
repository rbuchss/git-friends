#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/protocol.sh"

git::__module__::load || return 0

# Installs a config template to a target path.
#
# Usage:
#   git setup-config <template_name> [target_path] [--force]
#
# Templates:
#   gitconfig-local  SSH rewrite config    (default: ~/.gitconfig.local)
#   agent-env        Agent env vars        (default: ./.env)
#
# Options:
#   --force, -f   Overwrite existing files without warning
#   --merge, -m   Append template content to existing file
function git::setup::config {
  local \
    arg \
    config_dir="${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/../config" \
    default_target \
    force=0 \
    merge=0 \
    template_file \
    template_name="" \
    target_path=""

  for arg in "$@"; do
    case "${arg}" in
      --help | -h)
        git::setup::config::usage
        return 0
        ;;
      --force | -f) force=1 ;;
      --merge | -m) merge=1 ;;
      *)
        if [[ -z "${template_name}" ]]; then
          template_name="${arg}"
        else
          target_path="${arg}"
        fi
        ;;
    esac
  done

  if [[ -z "${template_name}" ]]; then
    git::setup::config::usage
    return 1
  fi

  if ((force == 1)) && ((merge == 1)); then
    git::logger::error "Cannot use --force and --merge together"
    return 1
  fi

  case "${template_name}" in
    gitconfig-local)
      template_file="${config_dir}/templates/gitconfig.local"
      default_target="${HOME}/.gitconfig.local"
      ;;
    agent-env)
      template_file="${config_dir}/templates/agent.env"
      default_target="./.env"
      ;;
    *)
      git::logger::error "Unknown template: ${template_name}"
      git::setup::config::usage
      return 1
      ;;
  esac

  target_path="${target_path:-${default_target}}"

  if [[ ! -f "${template_file}" ]]; then
    git::logger::error "Template not found: ${template_file}"
    return 1
  fi

  local target_dir
  target_dir="$(dirname "${target_path}")"

  if [[ ! -d "${target_dir}" ]]; then
    git::logger::error "Target directory does not exist: ${target_dir}"
    return 1
  fi

  if [[ -f "${target_path}" ]]; then
    if ((merge == 1)); then
      printf '\n' >>"${target_path}"
      cat "${template_file}" >>"${target_path}"
      git::logger::info "Merged ${template_name} into ${target_path}"
      return 0
    fi

    if ((force == 0)); then
      git::logger::warning "File already exists: ${target_path}"
      git::logger::info "Use --force to overwrite or --merge to append"
      return 1
    fi
  fi

  cp "${template_file}" "${target_path}"
  git::logger::info "Installed ${template_name} to ${target_path}"

  # Post-install: offer to switch SSH remotes to HTTPS
  if [[ "${template_name}" == "agent-env" ]] && ! git::protocol::is_https; then
    git::logger::warning "Token-based auth requires HTTPS to use the credential helper"
    git::protocol::set 'https' || :
  fi
}

function git::setup::config::usage {
  cat <<USAGE_TEXT
Usage: git setup-config <template> [target_path] [OPTIONS]

Templates:
  gitconfig-local   SSH rewrite config    (default: ~/.gitconfig.local)
  agent-env         Agent env vars        (default: ./.env)

Options:
  -f, --force   Overwrite existing files without warning
  -m, --merge   Append template content to existing file
USAGE_TEXT
}

function git::setup::__export__ {
  export -f git::setup::config
  export -f git::setup::config::usage
}

# KCOV_EXCL_START
function git::setup::__recall__ {
  export -fn git::setup::config
  export -fn git::setup::config::usage
}
# KCOV_EXCL_STOP

git::__module__::export
