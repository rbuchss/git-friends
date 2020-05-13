using namespace System.Diagnostics.CodeAnalysis
. $PSScriptRoot/../git-friends/src/hooks/pre_commit/test.ps1

Describe 'PreCommitTestResult' {
  Context 'pre-commit test was skipped' {
    BeforeEach {
      [SuppressMessage('PSReviewUnusedParameter', 'result')]
      $result = [PreCommitTestResult]::new({
        $this.Status = $null
      })
    }

    It '#Passed' {
      $result.Passed() | Should -BeNullOrEmpty
    }

    It '#Failed' {
      $result.Failed() | Should -BeNullOrEmpty
    }

    It '#Skipped' {
      $result.Skipped() | Should -BeTrue
    }

    It '#Ran' {
      $result.Ran() | Should -BeFalse
    }

    It '#Violations' {
      $result.Violations | Should -BeNullOrEmpty
    }
  }

  Context 'pre-commit test was run' {
    Context 'and failed' {
      BeforeEach {
        [SuppressMessage('PSReviewUnusedParameter', 'result')]
        $result = [PreCommitTestResult]::new({
          $this.Status = 1
          $this.Violations = @('foo', 'bar', 'qux')
        })
      }

      It '#Passed' {
        $result.Passed() | Should -BeFalse
      }

      It '#Failed' {
        $result.Failed() | Should -BeTrue
      }

      It '#Skipped' {
        $result.Skipped() | Should -BeFalse
      }

      It '#Ran' {
        $result.Ran() | Should -BeTrue
      }

      It '#Violations' {
        $result.Violations | Should -Be @('foo', 'bar', 'qux')
      }
    }

    Context 'and passed' {
      BeforeEach {
        [SuppressMessage('PSReviewUnusedParameter', 'result')]
        $result = [PreCommitTestResult]::new({ })
      }

      It '#Passed' {
        $result.Passed() | Should -BeTrue
      }

      It '#Failed' {
        $result.Failed() | Should -BeFalse
      }

      It '#Skipped' {
        $result.Skipped() | Should -BeFalse
      }

      It '#Ran' {
        $result.Ran() | Should -BeTrue
      }

      It '#Violations' {
        $result.Violations | Should -BeNullOrEmpty
      }
    }
  }
}
