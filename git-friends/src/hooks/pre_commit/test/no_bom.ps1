#!/usr/bin/env pwsh

using namespace System.Diagnostics.CodeAnalysis
. ~/.git-friends/src/hooks/pre_commit/test.ps1

function Test-FileContainsBOM {
  [CmdletBinding()]
  [OutputType([bool])]
  param (
    [Parameter()]
    [string]
    $Path
  )
  $fullPath = (Get-Item -Force $Path)
  $contents = new-object byte[] 3
  $stream = [System.IO.File]::OpenRead($fullPath.FullName)
  $stream.Read($contents, 0, 3) | Out-Null
  $stream.Close()
  return $contents[0] -eq 0xEF -and $contents[1] -eq 0xBB -and $contents[2] -eq 0xBF
}

function Test-CommitHasNoBOM {
  [SuppressMessage('PSReviewUnusedParameter', 'files')]
  param (
    [Parameter()]
    [Alias('n')]
    [switch]
    $Skip
  )
  [PreCommitTest]::new(
    'Has No BOM',
    'Please remove the BOM(s) and re-add the file(s) for commit',
    $Skip, {
      param([array] $files)

      [PreCommitTestResult]::new({
        foreach ($file in $files) {
          if (Test-FileContainsBOM $file) {
            $this.Status = 1
            $this.Violations += $file
          }
        }
      })
    }
  ).RunAndReport()
}
