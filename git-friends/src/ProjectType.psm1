#!/usr/bin/env pwsh

class ProjectType {
  [string] $Name
  [string[]] $Parents
  [string[]] $Extensions

  ProjectType([PSObject] $obj) {
    $this.Name = $obj.Name
    $this.Parents = $obj.Parents
    $this.Extensions = $obj.Extensions
  }

  [string[]] GitFilesFilter() {
    $filters = @()

    foreach ($extension in $this.Extensions) {
      $filters += ":$extension"
    }

    return @($filters)
  }

  [array] GitListFiles() {
    return $this.GitListFiles(@())
  }

  [array] GitListFiles([string[]] $flags) {
    $files = @(git diff $flags --name-only -- $this.GitFilesFilter())
    return $files
  }

  [array] GitListCachedFiles() {
    return $this.GitListCachedFiles(@())
  }

  [array] GitListCachedFiles([string[]] $flags) {
    $flags += @('--cached', '--diff-filter=ACM')
    return $this.GitListFiles($flags)
  }
}
