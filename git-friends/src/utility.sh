#!/bin/bash

function git::utility::ask() {
  local question="$1" \
    response_for_all_var_="$2" \
    response_for_all_

  if [[ -n "${response_for_all_var_}" ]]; then
    echo -n "${question} [yes/no/all/none (y/n/a/z)] ? "

    read -r response_for_all_ <<< "${!response_for_all_var_}"

    if [[ -n "${response_for_all_}" ]]; then
      (( response_for_all_ == 0 )) \
        && echo 'all' \
        || echo 'none'
      return "${response_for_all_}"
    fi

    read -r response

    case "${response}" in
      [yY]|[yY][eE][sS]) return 0 ;;
      [nN]|[nN][oO]) return 1 ;;
      [aA]|[aA][lL][lL])
        read -r "$2" <<< 0
        return 0
        ;;
      [zZ]|[nN][oO][nN][eE])
        read -r "$2" <<< 1
        return 1
        ;;
      *) return 1 ;;
    esac
  fi

  read -r -p "${question} [yes/no (y/n)] ? " response

  case "${response}" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}
