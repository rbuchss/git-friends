#!/usr/bin/env pwsh

# Hacky way to resuse the pester formatters
# too lazy to write these myself ;P
$pesterPath = (Get-Item (Get-Module -ListAvailable Pester).Path).Directory
Import-Module $pesterPath/Dependencies/Format/Format.psm1

enum TypeOfReport {
  Equality
  Inequality
}

class DeepComparator {
  [object[]] $Actual
  [object[]] $Expected
  [bool] $CaseSensitive
  [string] $Because
  [TypeOfReport] $ReportType
  [hashtable] $Report = @{
    [TypeOfReport]::Equality = @()
    [TypeOfReport]::Inequality = @()
  }

  static [PSObject] Verify($actualValue,
      $expectedValue,
      [bool] $negate,
      [bool] $caseSensitive,
      [string] $because) {
    $comparator = [DeepComparator]::new($actualValue, $expectedValue, $caseSensitive, $because)

    [bool] $succeeded = ($negate) `
      ? $comparator.VerifyInequality()
      : $comparator.VerifyEquality()

    $failureMessage = (-not $succeeded) `
      ? $comparator.GetReport()
      : $null

    return New-Object PSObject -Property @{
      Succeeded = $succeeded
      FailureMessage = $failureMessage
    }
  }

  DeepComparator($actual, $expected, $caseSensitive, $because) {
    $this.Actual = $actual
    $this.Expected = $expected
    $this.CaseSensitive = $caseSensitive
    $this.Because = $because
  }

  [bool] VerifyEquality() {
    $this.ResetReport()
    $this.ReportType = [TypeOfReport]::Equality
    return $this.HasRecursiveEquality($this.Actual, $this.Expected, $null)
  }

  [bool] VerifyInequality() {
    $this.ResetReport()
    $this.ReportType = [TypeOfReport]::Inequality
    return (-not $this.HasRecursiveEquality($this.Actual, $this.Expected, $null))
  }

  [string] GetReport() {
    return ($this.Report[$this.ReportType] -join "`n")
  }

  hidden [void] ResetReport() {
    $this.Report = @{
      [TypeOfReport]::Equality = @()
      [TypeOfReport]::Inequality = @()
    }
  }

  hidden [void] AddToReport([TypeOfReport] $type, [string] $message) {
    $this.Report.$type += $message
  }

  hidden [bool] HasRecursiveEquality($lhs, $rhs, $context) {
    if ($lhs -is [System.Collections.IList] `
        -and $rhs -is [System.Collections.IList]) {
      if ($lhs.Count -ne $rhs.Count) {
        $this.AddToReport(
          [TypeOfReport]::Equality,
          ('- {0}Expected a collection with size {1},{2} but got collection with size {3}' -f `
            (($context) ? "Context: $(Format-Nicely $context) " : ''),
            $rhs.Count,
            $this.FormatBecause(),
            $lhs.Count)
        )

        $this.AddToReport(
          [TypeOfReport]::Equality,
          ('  Actual:   {0}' -f (Format-Nicely $lhs))
        )

        $this.AddToReport(
          [TypeOfReport]::Equality,
          ('  Expected: {0}' -f (Format-Nicely $rhs))
        )

        return $false
      } else {
        $this.AddToReport(
          [TypeOfReport]::Inequality,
          ('- {0}Expected a collection with size different from {1},{2} but got collection with that size {3}' -f `
            (($context) ? "Context: $(Format-Nicely $context) " : ''),
            $lhs.Count,
            $this.FormatBecause(),
            (Format-Nicely $lhs))
        )
      }

      $inequalIndexes = 0..($lhs.Count - 1) `
        | Where-Object { -not $this.HasRecursiveEquality($lhs[$_], $rhs[$_], "$context[$_]") }
      return $inequalIndexes.Count -eq 0
    }

    if ($lhs -is [hashtable] -and $rhs -is [hashtable]) {
      $inequalKeys = $lhs.Keys + $rhs.Keys `
      | Sort-Object -Unique `
      | Where-Object { -not $this.HasRecursiveEquality($lhs[$_], $rhs[$_], $_) }
      return $inequalKeys.Count -eq 0
    }

    if (($lhs -is [PSCustomObject]) -and ($rhs -is [PSCustomObject])) {
      $inequalKeys = $lhs.PSObject.Properties + $rhs.PSObject.Properties `
      | ForEach-Object Name `
      | Sort-Object -Unique `
      | Where-Object { -not $this.HasRecursiveEquality($lhs.$_, $rhs.$_, $_) }
      return $inequalKeys.Count -eq 0
    }

    if ($this.HasBasicEquality($lhs, $rhs)) {
      $this.AddToReport(
        [TypeOfReport]::Inequality,
        ('- {0}Expected {1} to be different from the actual value,{2} but got the same value' -f `
          (($context) ? "Context: $(Format-Nicely $context) " : ''),
          (Format-Nicely $lhs),
          $this.FormatBecause())
      )
      return $true
    } else {
      $this.AddToReport(
        [TypeOfReport]::Equality,
        ('- {0}Expected {1},{2} but got {3}' -f `
          (($context) ? "Context: $(Format-Nicely $context) " : ''),
          (Format-Nicely $rhs),
          $this.FormatBecause(),
          (Format-Nicely $lhs))
      )
      return $false
    }
  }

  hidden [bool] HasBasicEquality($lhs, $rhs) {
    if ($null -eq $lhs -and $null -eq $rhs) {
      return $true
    }

    if (-not ($null -ne $lhs `
          -and $null -ne $rhs `
          -and $lhs.GetType() -eq $rhs.GetType())) {
      return $false
    }

    if ($this.CaseSensitive) {
      return ($lhs -ceq $rhs)
    }

    return ($lhs -eq $rhs)
  }

  hidden [string] FormatBecause() {
    if ($null -eq $this.Because) {
      return ''
    }

    $bcs = $this.Because.Trim()

    if ([string]::IsNullOrEmpty($bcs)) {
      return ''
    }

    return " because $($bcs -replace 'because\s'),"
  }
}

function Test-DeepEquality {
  param (
    $ActualValue,
    $ExpectedValue,
    [switch] $Negate,
    [string] $Because
  )
  return [DeepComparator]::Verify(
    $ActualValue,
    $ExpectedValue,
    $Negate,
    $false,
    $Because
  )
}

Add-AssertionOperator -Name HaveDeepEquality `
  -InternalName Test-DeepEquality `
  -Test ${function:Test-DeepEquality} `
  -Alias 'DEQ' `
  -SupportsArrayInput

function Test-ExactDeepEquality {
  param (
    $ActualValue,
    $ExpectedValue,
    [switch] $Negate,
    [string] $Because
  )
  return [DeepComparator]::Verify(
    $ActualValue,
    $ExpectedValue,
    $Negate,
    $true,
    $Because
  )
}

Add-AssertionOperator -Name HaveExactDeepEquality `
  -InternalName Test-ExactDeepEquality `
  -Test ${function:Test-ExactDeepEquality} `
  -Alias 'DCEQ' `
  -SupportsArrayInput
