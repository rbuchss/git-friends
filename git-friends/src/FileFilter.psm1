#!/usr/bin/env pwsh

using module '.\Config.psm1'

class FileFilter {
  [string[]] $Inclusions
  [string[]] $Exclusions

  FileFilter() {
    $this.Inclusions = @()
    $this.Exclusions = @()
  }

  FileFilter([string[]] $inclusions, [string[]] $exclusions) {
    $this.Inclusions = $inclusions
    $this.Exclusions = $exclusions
  }

  [string[]] List() {
    return ($this.InclusionsFilter() +
      $this.ExclusionsFilter())
  }

  [int] Count() {
    return ($this.Inclusions.Count +
      $this.Exclusions.Count)
  }

  [string[]] InclusionsFilter() {
    $filter = @()

    foreach ($inclusion in $this.Inclusions) {
      $filter += ":$inclusion"
    }

    return @($filter)
  }

  [string[]] ExclusionsFilter() {
    $filter = @()

    foreach ($exclusion in $this.Exclusions) {
      $filter += ":!:$exclusion"
    }

    return @($filter)
  }

  [bool] Equals($other) {
    if ((Compare-Object -ReferenceObject $this.Inclusions `
          -DifferenceObject $other.Inclusions).Length -eq 0 `
        -and (Compare-Object -ReferenceObject $this.Exclusions `
          -DifferenceObject $other.Exclusions).Length -eq 0) {
      return $true
    }
    return $false
  }

  static [FileFilter] op_Addition([FileFilter] $lhs, [FileFilter] $rhs) {
    $include = $lhs.Inclusions
    $exclude = $lhs.Exclusions

    foreach ($element in $rhs.Inclusions) {
      if (-not $include.Contains($element)) {
        $include += $element
      }
    }

    foreach ($element in $rhs.Exclusions) {
      if (-not $exclude.Contains($element)) {
        $exclude += $element
      }
    }

    return [FileFilter]::new($include, $exclude)
  }
}
