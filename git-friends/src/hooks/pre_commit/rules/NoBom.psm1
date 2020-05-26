#!/usr/bin/env pwsh

using namespace System.Diagnostics.CodeAnalysis
using module '..\Rule.psm1'

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
  [PreCommitRule]::new(
    'Has No BOM',
    'Please remove the BOM(s) and re-add the file(s) for commit',
    'no-bom',
    $Skip, {
      param([array] $files)

      [PreCommitRuleResult]::new({
        # TODO use delay-bind here?
        param($result)

        foreach ($file in $files) {
          if (Test-FileContainsBOM $file) {
            $result.Status = 1
            $result.Violations += $file
          }
        }
      })
    }
  ).RunAndReport()
}
