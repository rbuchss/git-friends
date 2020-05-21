using namespace System.Diagnostics.CodeAnalysis
using module '..\git-friends\src\Utility.psm1'

Describe 'Utility' {
  Context 'Merge-Hashtables' {
    BeforeEach {
      [SuppressMessage('PSReviewUnusedParameter', 'h1')]
      $h1 = @{a = 9; b = 8; c = 7}

      [SuppressMessage('PSReviewUnusedParameter', 'h2')]
      $h2 = @{b = 6; c = 5; d = 4}

      [SuppressMessage('PSReviewUnusedParameter', 'h3')]
      $h3 = @{c = 3; d = 2; e = 1}

      [SuppressMessage('PSReviewUnusedParameter', 'h4')]
      $h4 = @{ b = @(1, 2, 3) }
    }

    It 'merges two hashtables' {
      $expected = @{
        a = 9;
        b = @(8, 6);
        c = @(7, 5);
        d = 4;
      }
      $result = ($h1, $h2 | Merge-Hashtables)
      # TODO add custom test for Hashtable equality
      # since the default only compares the memory location
      # $result | Should -Be $expected
      $result.Keys | Should -HaveCount $expected.Keys.Count
      $result.Keys | ForEach-Object { $result[$_] | Should -Be $expected[$_] }
    }

    It 'merges three hashtables' {
      $expected = @{
        a = 9;
        b = @(8, 6);
        c = @(7, 5, 3);
        d = @(4, 2);
        e = 1;
      }
      $result = ($h1, $h2, $h3 | Merge-Hashtables)
      # TODO add custom test for Hashtable equality
      # since the default only compares the memory location
      # $result | Should -Be $expected
      $result.Keys | Should -HaveCount $expected.Keys.Count
      $result.Keys | ForEach-Object { $result[$_] | Should -Be $expected[$_] }
    }

    It 'merges four hashtables' {
      $expected = @{
        a = 9;
        b = @(8, 6, 1, 2, 3);
        c = @(7, 5, 3);
        d = @(4, 2);
        e = 1;
      }
      $result = ($h1, $h2, $h3, $h4 | Merge-Hashtables)
      # TODO add custom test for Hashtable equality
      # since the default only compares the memory location
      # $result | Should -Be $expected
      $result.Keys | Should -HaveCount $expected.Keys.Count
      $result.Keys | ForEach-Object { $result[$_] | Should -Be $expected[$_] }
    }

    It 'merges and sorts four hashtables' {
      $expected = @{
        a = 9;
        b = @(1, 2, 3, 6, 8);
        c = @(3, 5, 7);
        d = @(2, 4);
        e = 1;
      }
      $result = ($h1, $h2, $h3, $h4 | Merge-Hashtables { $args | Sort-Object })
      # TODO add custom test for Hashtable equality
      # since the default only compares the memory location
      # $result | Should -Be $expected
      $result.Keys | Should -HaveCount $expected.Keys.Count
      $result.Keys | ForEach-Object { $result[$_] | Should -Be $expected[$_] }
    }

    It 'merges four hashtables into strings' {
      $expected = @{
        a = '9';
        b = '86123';
        c = '753';
        d = '42';
        e = '1';
      }
      $result = ($h1, $h2, $h3, $h4 | Merge-Hashtables { -join $args })
      # TODO add custom test for Hashtable equality
      # since the default only compares the memory location
      # $result | Should -Be $expected
      $result.Keys | Should -HaveCount $expected.Keys.Count
      $result.Keys | ForEach-Object { $result[$_] | Should -Be $expected[$_] }
    }
  }
}
