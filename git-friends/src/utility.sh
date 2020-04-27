#!/bin/bash

function git::utility::ask() {
  echo -n "$@" '[y/n] '
  read -r response
  case "${response}" in
    y*|Y*) return 0 ;;
    *) return 1 ;;
  esac
}
