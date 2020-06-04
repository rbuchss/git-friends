#!/usr/bin/env pwsh

using module '..\..\FileFilter.psm1'
using module '..\..\FileFilterTemplate.psm1'
using module '..\..\Repo.psm1'

class PreCommitRule {
  [string] $Name
  [string] $Fix
  [string] $Key
  [bool] $Skip
  [ScriptBlock] $Block
  [Repo] $Repo
  [FileFilter] $FileFilter

  PreCommitRule([string] $name, [string] $fix, [string] $key, [bool] $skip, [ScriptBlock] $block) {
    $this.Name = $name
    $this.Fix = $fix
    $this.Key = $key
    $this.Skip = $skip
    $this.Block = $block
    $this.Repo = [Repo]::new()
    $this.FileFilter = $this.CreateFileFilter()
  }

  [PreCommitRuleReport] Run() {
    $result = $this.Skip `
      ? [PreCommitRuleResult]::new({ $this.Status = $null }) `
      : $this.Block.Invoke((,$this.StagedFiles()))

    return [PreCommitRuleReport]::new($this.Name, $result, $this.Fix)
  }

  [int] RunAndReport() {
    return $this.Run().Show()
  }

  [string[]] StagedFiles() {
    return $this.Repo.CachedFiles($this.FileFilter)
  }

  hidden [FileFilter] CreateFileFilter() {
    $filter = [FileFilter]::new()

    foreach ($template in @($this.Repo.Config.Get(@('git-friends', 'pre-commit', 'filter')),
          $this.Repo.Config.Get(@('git-friends', 'pre-commit', $this.Key, 'filter')))) {
      if ($null -ne $template) {
        $filter += [FileFilterTemplate]::Factory($template)
      }
    }

    $include = ($this.Repo.Config.Get(@('git-friends', 'pre-commit', 'include')) ?? @()) +
      ($this.Repo.Config.Get(@('git-friends', 'pre-commit', $this.Key, 'include')) ?? @())

    $exclude = ($this.Repo.Config.Get(@('git-friends', 'pre-commit', 'exclude')) ?? @()) +
      ($this.Repo.Config.Get(@('git-friends', 'pre-commit', $this.Key, 'exclude')) ?? @())

    $filter += [FileFilter]::new($include, $exclude)

    return $filter
  }
}

class PreCommitRuleReport {
  [string] $Name
  [PreCommitRuleResult] $Result
  [string] $Fix
  [string] $Summary
  [string] $Details
  [char] $ESC = [char]0x1B
  $Color = @{
    Error = "$($this.ESC)[0;91m";
    Warning = "$($this.ESC)[0;93m";
    Information = "$($this.ESC)[0;92m";
    Violation = "$($this.ESC)[0;31m";
    Off = "$($this.ESC)[0m"
  }

  PreCommitRuleReport([string] $name, [PreCommitRuleResult] $result, [string] $fix) {
    $this.Name = $name
    $this.Result = $result
    $this.CreateSummary()
    $this.CreateDetails()
    $this.CreateFix($fix)
  }

  [int] Show() {
    Write-Host $this.Summary

    if ($this.Result.Failed()) {
      Write-Host $this.Details
      Write-Host $this.Fix
    }

    return $this.Result.Status
  }

  [void] CreateSummary() {
    if ($this.Result.Skipped()) {
      $messageColor = $this.Color['Warning']
      $grade = ' Skipped'
    } else {
      $messageColor = $this.Result.Passed() ? $this.Color['Information'] : $this.Color['Error']
      $grade = $this.Result.Passed() ? ' Passed' : ' Failed'
    }

    $this.Summary = '{0} {1}{2}{3}' -f `
      $this.Name,
      $messageColor,
      $grade.PadLeft($this.OutputWidth(), '.'),
      $this.Color['Off']
  }

  [void] CreateDetails() {
    if ($this.Result.Failed()) {
      $this.Details = "{0}{1} {2} found:{3}`n{4}" -f `
        $this.Color['Error'],
        $this.Result.Violations.Count,
        ($this.Result.Violations.Count -gt 1 ? 'violations' : 'violation'),
        $this.Color['Off'],
        $this.Color['Violation']

      foreach ($violation in $this.Result.Violations) {
        $this.Details += "`n{0}" -f $violation
      }
    }
  }

  [void] CreateFix([string] $fix) {
    if ($this.Result.Failed()) {
      $this.Fix = "`n{0}{1}{2}" -f `
        $this.Color['Error'],
        $fix,
        $this.Color['Off']
    }
  }

  [int] OutputWidth() {
    return 80 - $this.Name.Length
  }

  [bool] Equals($other) {
    if ($this.Name -eq $other.Name `
      -and $this.Result -eq $this.Result `
      -and $this.Fix -eq $this.Fix `
      -and $this.Summary -eq $this.Summary `
      -and $this.Details -eq $this.Details) {
        return $true
    }
    return $false
  }
}

class PreCommitRuleResult {
  [Nullable[int]] $Status = 0
  [string[]] $Violations = @()

  PreCommitRuleResult([ScriptBlock] $block) {
    $block.Invoke($this)
  }

  PreCommitRuleResult([System.Collections.ObjectModel.Collection[PSObject]] $obj) {
    $this.Status = $obj.Status
    $this.Violations = $obj.Violations
  }

  [Nullable[bool]] Passed() {
    return $null -eq $this.Status ? $null : $this.Status -eq 0
  }

  [Nullable[bool]] Failed() {
    return $null -eq $this.Status ? $null : -not $this.Passed()
  }

  [bool] Skipped() {
    return $null -eq $this.Status
  }

  [bool] Ran() {
    return -not $this.Skipped()
  }
}
