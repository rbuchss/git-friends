#!/usr/bin/env pwsh

class PreCommitTest {
  [string] $Name
  [string] $Fix
  [bool] $Skip
  [ScriptBlock] $Test

  PreCommitTest([string] $name, [string] $fix, [bool] $skip, [ScriptBlock] $test) {
    $this.Name = $name
    $this.Fix = $fix
    $this.Skip = $skip
    $this.Test = $test
  }

  [PreCommitTestReport] Run() {
    $result = $this.Skip `
      ? [PreCommitTestResult]::new({ $this.Status = $null }) `
      : $this.Test.Invoke((,$this.StagedFiles()))

    return [PreCommitTestReport]::new($this.Name, $result, $this.Fix)
  }

  [int] RunAndReport() {
    return $this.Run().Show()
  }

  [string[]] StagedFiles() {
    # TODO have param/lookup for this?
    $extensions = @(
      '*.cs', '*.csx', '*.vb', '*.vbx',
      '*.sln',
      '*.csproj', '*.vbproj', '*.vcxproj', '*.vcxproj.filters', '*.proj', '*.projitems', '*.shproj',
      '*.json', '*.yml', '*.config', '*.props', '*.targets', '*.nuspec', '*.resx', '*.ruleset',
      '*.xml', '*.axml', '*.xaml',
      '*.md',
      '*.htm', '*.html', '*.js', '*.ts', '*.css', '*.scss', '*.less',
      '.editorconfig',
      '.gitignore',
      '*.ps1',
      '*.plist',
      '*.storyboard'
    )

    $extensionsRegex = "^($($extensions -join '|' -replace '\.', '\.' -replace '\*', '.*'))$"
    # TODO use git filtering here?
    $stagedFiles = @(git diff --cached --name-only --diff-filter=ACM | Get-Item -Force)
    return @($stagedFiles.Where( { $_.Name -match $extensionsRegex }) | `
      Select-Object -ExpandProperty FullName | `
      Resolve-Path -Relative)
  }
}

class PreCommitTestReport {
  [string] $Name
  [PreCommitTestResult] $Result
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

  PreCommitTestReport([string] $name, [PreCommitTestResult] $result, [string] $fix) {
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
}

class PreCommitTestResult {
  [Nullable[int]] $Status = 0
  [string[]] $Violations = @()

  PreCommitTestResult([ScriptBlock] $block) {
    $block.Invoke()
  }

  PreCommitTestResult([System.Collections.ObjectModel.Collection[PSObject]] $obj) {
    $this.Status = $obj.Status
    $this.Violations = $obj.Violations
  }

  [Nullable[bool]] Passed() {
    return $null -eq $this.Status ? $null : $this.Status -eq 0
  }

  [Nullable[bool]] Failed() {
    return $null -eq $this.Status ? $null : ! $this.Passed()
  }

  [bool] Skipped() {
    return $null -eq $this.Status
  }

  [bool] Ran() {
    return ! $this.Skipped()
  }
}
