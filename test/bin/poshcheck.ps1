#!/usr/bin/env pwsh

$format = @{Expression={$_.Location}; Label="In"},
  @{Expression={$_.Context}; Label="Line"},
  @{Expression={$_.Rule}; Label="Rule"},
  @{Expression={$_.Message}; Label="Message"}

$ESC = [char]0x1B

$color = @{
  Extent = @{
    Error = "$ESC[0;91m";
    Warning = "$ESC[0;93m";
    Information = "$ESC[0;92m";
  };
  Rule = @{
    Error = "$ESC[0;31m";
    Warning = "$ESC[0;33m";
    Information = "$ESC[0;32m";
  };
  Location = "$ESC[0;97m";
  Off = "$ESC[0m"
}

$report = @{
  Violations = 0;
  Error = 0;
  Warning = 0;
  Information = 0;
}

foreach ($file in $args) {
  $failures = Invoke-ScriptAnalyzer -Path $file | Sort-Object Line, Column

  if ($failures.Count -eq 0) {
    continue
  }

  $report['Violations'] += $failures.Count

  $fileContent = Get-Content $file

  $failures | Foreach-Object {
    $location = "{0}{1}{2}{3}:{4}" -f `
      $color['Location'],
      ($_.ScriptPath | Resolve-Path -Relative),
      ($null -ne $_.Line ? " line $($_.Line)" : '' ),
      ($null -ne $_.Column ? " , column: $($_.Column)" : ''),
      $color['Off']

    $_ | Add-Member -MemberType NoteProperty `
      -Name "Location" `
      -Value $location

    if ($null -ne $_.Line) {
      $line = $fileContent | Select-Object -Index ($_.Line - 1)
      $line = $line.Replace(
        $_.Extent,
        ('{0}{1}{2}' -f `
          $color['Extent'][$_.Severity.toString()],
          $_.Extent,
          $color['Off'])
      )

      $_ | Add-Member -MemberType NoteProperty `
        -Name "Context" `
        -Value $line
    }

    $rule = '{0}{1}^-- {2} [{3}]{4}' -f `
      $color['Rule'][$_.Severity.toString()],
      ($null -ne $_.Column ? ''.PadLeft($_.Column - 1) : ''),
      $_.RuleName,
      $_.Severity,
      $color['Off']

    $_ | Add-Member -MemberType NoteProperty `
      -Name "Rule" `
      -Value $rule

    $report[$_.Severity.toString()]++
  }

  $failures |
    Format-List -Property $format
}

$reportColor = $report['Violations'] -gt 0 ? $color['Extent']['Error'] : $color['Extent']['Information']

$reportMessage = `
  "{0}{1} rule {2} found.    Severity distribution:  Error = {3}, Warning = {4}, Information = {5}{6}" -f `
  $reportColor,
  $report['Violations'],
  ($report['Violations'] -eq 0 -or $report['Violations'] -gt 1 ? 'violations' : 'violation'),
  $report['Error'],
  $report['Warning'],
  $report['Information'],
  $color['Off']

Write-Output $reportMessage

exit $report['Violations'] -eq 0 ? 0 : 1
