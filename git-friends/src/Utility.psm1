#!/usr/bin/env pwsh

function Merge-Hashtables {
  [OutputType([hashtable])]
  [CmdletBinding()]
  param (
    [ScriptBlock]
    $Block,

    [Parameter(ValueFromPipeLine = $true)]
    [Object[]]
    $Dictionary
  )

  begin {
    $output = @{}
  }

  process {
    $Dictionary | ForEach-Object {
      if ($_ -is [System.Collections.IDictionary]) {
        foreach ($key in $_.Keys) {
          $output.$key = ($output.ContainsKey($key)) `
            ?  @($output.$key) + $_.$key
            :  $_.$key
        }
      } else {
        Write-Error("'$_' can't be converted to a hashtable")
      }
    }
  }

  end {
    if ($Block) {
      foreach ($key in @($output.Keys)) {
        $output.$key = $Block.InvokeReturnAsIs($output.$key)
      }
    }
    $output
  }
}
