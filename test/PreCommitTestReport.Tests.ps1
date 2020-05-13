using namespace System.Diagnostics.CodeAnalysis
. $PSScriptRoot/../git-friends/src/hooks/pre_commit/test.ps1

Describe 'PreCommitTestReport' {
  BeforeAll {
    $ESC = [char]0x1B

    [SuppressMessage('PSReviewUnusedParameter', 'colorRegexp')]
    $colorRegexp = @{
      Error = "$ESC\[0;91m";
      Warning = "$ESC\[0;93m";
      Information = "$ESC\[0;92m";
      Violation = "$ESC\[0;31m";
      Off = "$ESC\[0m"
    }
  }

  Context 'pre-commit test was skipped' {
    BeforeEach {
      $result = [PreCommitTestResult]::new({
        $this.Status = $null
      })

      [SuppressMessage('PSReviewUnusedParameter', 'report')]
      $report = [PreCommitTestReport]::new('name', $result, 'how-to-fix')
    }

    It '#Name' {
      $report.Name | Should -Be 'name'
    }

    It '#Result' {
      $report.Result | Should -Be $result
      # NOTE: custom type checking not currently supported:
      #   see: https://github.com/pester/Pester/issues/1315
      # $report.Result | Should -BeOfType PreCommitTestResult
    }

    It '#Fix' {
      $report.Fix | Should -BeNullOrEmpty
    }

    It '#Summary' {
      $report.Summary | Should -Match "^name $($colorRegexp['Warning'])\.+ Skipped$($colorRegexp['Off'])$"
    }

    It '#Details' {
      $report.Details | Should -BeNullOrEmpty
    }

    It '#Show' {
      Mock Write-Host { }
      $report.Show() | Should -Be 0
      Assert-MockCalled Write-Host -Exactly 1
    }
  }

  Context 'pre-commit test was run' {
    Context 'and failed' {
      BeforeEach {
        $result = [PreCommitTestResult]::new({
          $this.Status = 1
          $this.Violations = @('foo', 'bar', 'qux')
        })

        [SuppressMessage('PSReviewUnusedParameter', 'report')]
        $report = [PreCommitTestReport]::new('name', $result, 'how-to-fix')
      }

      It '#Name' {
        $report.Name | Should -Be 'name'
      }

      It '#Result' {
        $report.Result | Should -Be $result
      }

      It '#Fix' {
        $report.Fix | Should -Match "^\n$($colorRegexp['Error'])how-to-fix$($colorRegexp['Off'])$"
      }

      It '#Summary' {
        $report.Summary | Should -Match "^name $($colorRegexp['Error'])\.+ Failed$($colorRegexp['Off'])$"
      }

      It '#Details' {
        $regexp = '^{0}{1}{2}\n{3}\nfoo\nbar\nqux$' -f
          $colorRegexp['Error'],
          '3 violations found:',
          $colorRegexp['Off'],
          $colorRegexp['Violation']

        $report.Details | Should -Match $regexp
      }

      It '#Show' {
        Mock Write-Host { }
        $report.Show() | Should -Be 1
        Assert-MockCalled Write-Host -Exactly 3
      }
    }

    Context 'and passed' {
      BeforeEach {
        $result = [PreCommitTestResult]::new({ })

        [SuppressMessage('PSReviewUnusedParameter', 'report')]
        $report = [PreCommitTestReport]::new('name', $result, 'how-to-fix')
      }

      It '#Name' {
        $report.Name | Should -Be 'name'
      }

      It '#Result' {
        $report.Result | Should -Be $result
      }

      It '#Fix' {
        $report.Fix | Should -BeNullOrEmpty
      }

      It '#Summary' {
        $report.Summary | Should -Match "^name $($colorRegexp['Information'])\.+ Passed$($colorRegexp['Off'])$"
      }

      It '#Details' {
        $report.Details | Should -BeNullOrEmpty
      }

      It '#Show' {
        Mock Write-Host { }
        $report.Show() | Should -Be 0
        Assert-MockCalled Write-Host -Exactly 1
      }
    }
  }
}
