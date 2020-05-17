using namespace System.Diagnostics.CodeAnalysis
. $PSScriptRoot/../git-friends/src/hooks/pre_commit/test.ps1

Describe 'PreCommitTest' {
  function Test-DummyBlock { }

  Mock Write-Host { }

  BeforeEach {
    [SuppressMessage('PSReviewUnusedParameter', 'rule')]
    $rule = [PreCommitTest]::new(
      'name',
      'how-to-fix',
      $false, { Test-DummyBlock }
    )
  }

  Context 'was skipped' {
    BeforeEach {
      $result = [PreCommitTestResult]::new({
        $this.Status = $null
      })

      [SuppressMessage('PSReviewUnusedParameter', 'report')]
      $report = [PreCommitTestReport]::new('name', $result, 'how-to-fix')

      Mock Test-DummyBlock {
        return $result
      }

      $rule.Skip = $true
    }

    It '#Run' {
      $rule.Run() | Should -Be $report
      Assert-MockCalled Test-DummyBlock 0 -Scope It
    }

    It '#RunAndReport' {
      $rule.RunAndReport() | Should -Be 0
      Assert-MockCalled Test-DummyBlock 0 -Scope It
      Assert-MockCalled Write-Host -Exactly 1 -Scope It
    }
  }

  Context 'was run' {
    Context 'and failed' {
      BeforeEach {
        $result = [PreCommitTestResult]::new({
          $this.Status = 1
        })

        [SuppressMessage('PSReviewUnusedParameter', 'report')]
        $report = [PreCommitTestReport]::new('name', $result, 'how-to-fix')

        Mock Test-DummyBlock {
          return $result
        }
      }

      It '#Run' {
        $rule.Run() | Should -Be $report
        Assert-MockCalled Test-DummyBlock -Exactly 1 -Scope It
      }

      It '#RunAndReport' {
        $rule.RunAndReport() | Should -Be 1
        Assert-MockCalled Test-DummyBlock -Exactly 1 -Scope It
        Assert-MockCalled Write-Host -Exactly 3 -Scope It
      }
    }

    Context 'and passed' {
      BeforeEach {
        $result = [PreCommitTestResult]::new({
          $this.Status = 0
        })

        [SuppressMessage('PSReviewUnusedParameter', 'report')]
        $report = [PreCommitTestReport]::new('name', $result, 'how-to-fix')

        Mock Test-DummyBlock {
          return $result
        }
      }

      It '#Run' {
        $rule.Run() | Should -Be $report
        Assert-MockCalled Test-DummyBlock -Exactly 1 -Scope It
      }

      It '#RunAndReport' {
        $rule.RunAndReport() | Should -Be 0
        Assert-MockCalled Test-DummyBlock -Exactly 1 -Scope It
        Assert-MockCalled Write-Host -Exactly 1 -Scope It
      }
    }
  }
}
