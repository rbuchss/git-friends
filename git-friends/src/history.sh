#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/exec.sh"

git::__module__::load || return 0

function git::history::recent {
  # show local branches
  # (change to "ref/heads"
  # to include both local + remote branches)
  local count="${1:-0}" \
    branch \
    spacer \
    format \
    lessopts

  branch='%(color:yellow)%(refname:short)%(color:reset)'
  spacer='%(color:black) %(color:reset)'

  printf -v format '  %s   %s|  %s   %s   %s   %s\n   %s|  %s\n  %s|' \
    '%(HEAD)' \
    "${branch}" \
    '%(color:bold red)%(objectname:short)%(color:reset)' \
    '%(color:bold green)(%(committerdate:relative))%(color:reset)' \
    '%(color:bold blue)%(authorname)%(color:reset)' \
    '%(color:yellow)%(upstream:track)%(color:reset)' \
    "${spacer}|" \
    '%(contents:subject)' \
    "${spacer}|"

  lessopts=(
    '--tabs=4'
    --quit-if-one-screen
    --RAW-CONTROL-CHARS
    --no-init
  )

  git::exec for-each-ref \
    --color=always \
    --count="${count}" \
    --sort=-committerdate \
    'refs/heads/' \
    --format="${format}" \
    | column -ts '|' \
    | less "${lessopts[@]}"
}

function git::history::churn {
  git::exec log --all -M -C --name-only --format='format:' "$@" \
    | sort \
    | grep -v '^$' \
    | uniq -c \
    | sort \
    | awk 'BEGIN { print "count file" } { print $1 " " $2 }'
}

function git::history::__export__ {
  export -f git::history::recent
  export -f git::history::churn
}

function git::history::__recall__ {
  export -fn git::history::recent
  export -fn git::history::churn
}

git::__module__::export
