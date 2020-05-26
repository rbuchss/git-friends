#!/usr/bin/env pwsh

using module '.\Config.psm1'
using module '.\FileFilter.psm1'

class Repo {
  [Config] $Config

  Repo() {
    $this.Config = [Config]::new()
  }

  [array] ModifiedFiles() {
    return $this.ModifiedFiles(@(), $null)
  }

  [array] ModifiedFiles([FileFilter] $filter) {
    return $this.ModifiedFiles(@(), $filter)
  }

  [array] ModifiedFiles([string[]] $flags, [FileFilter] $filter) {
    return ($null -ne $filter -and $filter.Count() -gt 0) `
      ? @(git diff $flags --name-only -- $filter.List())
      : @(git diff $flags --name-only)
  }

  [array] CachedFiles() {
    return $this.CachedFiles(@(), $null)
  }

  [array] CachedFiles([FileFilter] $filter) {
    return $this.CachedFiles(@(), $filter)
  }

  [array] CachedFiles([string[]] $flags, [FileFilter] $filter) {
    $flags += @('--cached', '--diff-filter=ACM')
    return $this.ModifiedFiles($flags, $filter)
  }
}
