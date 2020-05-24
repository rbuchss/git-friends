using namespace System.Diagnostics.CodeAnalysis
using module '.\HaveDeepEquality.psm1'

Describe 'Should -HaveDeepEquality' {
  It 'returns true if the 2 arguments are equal' {
    1 | Should HaveDeepEquality 1
    1 | Should -HaveDeepEquality 1
    1 | Should -DEQ 1
  }

  It 'returns true if the 2 arguments are equal and have different case' {
    'A' | Should HaveDeepEquality 'a'
    'A' | Should -HaveDeepEquality 'a'
    'A' | Should -DEQ 'a'
  }

  It 'returns false if the 2 arguments are not equal' {
    1 | Should Not HaveDeepEquality 2
    1 | Should -Not -HaveDeepEquality 2
    1 | Should -Not -DEQ 2
  }

  It 'Compares arrays properly' {
    $array = @(1, 2, 3, 4, 'I am a string', (New-Object psobject -Property @{ IAm = 'An Object' }))
    $array | Should HaveDeepEquality $array
    $array | Should -HaveDeepEquality $array
    $array | Should -DEQ $array
  }

  It 'Compares arrays with correct case-insensitive behavior' {
    $string = 'I am a string'
    $array = @(1, 2, 3, 4, $string)
    $arrayWithCaps = @(1, 2, 3, 4, $string.ToUpper())

    $array | Should HaveDeepEquality $arrayWithCaps
    $array | Should -HaveDeepEquality $arrayWithCaps
    $array | Should -DEQ $arrayWithCaps
  }

  It 'Compares arrays with similar values in different order' {
    [int32[]]$array = (1..10)
    $arrayoutoforder = (1, 10, 2, 3, 4, 5, 6, 7, 8, 9)

    $array | Should Not HaveDeepEquality $arrayOutOfOrder
    $array | Should -Not -HaveDeepEquality $arrayOutOfOrder
    $array | Should -Not -DEQ $arrayOutOfOrder
  }

  It 'Handles reference types properly' {
    $object1 = New-Object PSObject -Property @{ Value = 'Test' }
    $object2 = New-Object PSObject -Property @{ Value = 'Test' }

    $object1 | Should HaveDeepEquality $object1
    $object1 | Should HaveDeepEquality $object2
    $object1 | Should -HaveDeepEquality $object1
    $object1 | Should -HaveDeepEquality $object2
    $object1 | Should -DEQ $object1
    $object1 | Should -DEQ $object2
  }

  It 'Handles arrays with nested arrays' {
    $array1 = @(
      @(1, 2, 3, 4, 5),
      @(6, 7, 8, 9, 0)
    )

    $array2 = @(
      @(1, 2, 3, 4, 5),
      @(6, 7, 8, 9, 0)
    )

    $array1 | Should HaveDeepEquality $array2
    $array1 | Should -HaveDeepEquality $array2
    $array1 | Should -DEQ $array2

    $array3 = @(
      @(1, 2, 3, 4, 5),
      @(6, 7, 8, 9, 0, 'Oops!')
    )

    $array1 | Should Not HaveDeepEquality $array3
    $array1 | Should -Not -HaveDeepEquality $array3
    $array1 | Should -Not -DEQ $array3
  }

  # TODO add support for this
  It 'returns true if the actual value can be cast to the expected value and they are the same value' -Skip {
    {abc} | Should HaveDeepEquality 'aBc'
    {abc} | Should -HaveDeepEquality 'aBc'
    {abc} | Should -DEQ 'aBc'
  }

  It 'Does not overflow on IEnumerable' {
    # see https://github.com/pester/Pester/issues/785
    $doc = [xml]'<?xml version="1.0" encoding="UTF-8" standalone="no" ?><root></root>'
    $doc | Should -HaveDeepEquality $doc
  }

  # TODO add support for this
  # The test excluded on macOS due to issue https://github.com/PowerShell/PowerShell/issues/4268
  if (-not (Get-Variable -Name 'IsMacOS' -ErrorAction 'SilentlyContinue' -ValueOnly)) {
    It 'throws exception when self-imposed recursion limit is reached' -Skip {
      $a1 = @(0, 1)
      $a2 = @($a1, 2)
      $a1[0] = $a2

      { $a1 | Should -be $a2 } | Should -Throw 'recursion depth limit'
    }
  }

  It 'Compares empty hashtables properly' {
    $actual = @{}
    $expected = @{}
    $actual | Should HaveDeepEquality $expected
    $actual | Should -HaveDeepEquality $expected
    $actual | Should -DEQ $expected
    @{} | Should -HaveDeepEquality @{}
  }

  It 'Compares hashtables properly' {
    $actual = @{
      foo = 123
      bar = 333
      baz = 'aBc'
    }
    $expected = @{
      foo = 123
      bar = 333
      baz = 'AbC'
    }
    $actual | Should HaveDeepEquality $expected
    $actual | Should -HaveDeepEquality $expected
    $actual | Should -DEQ $expected
  }

  It 'Compares unordered hashtables properly' {
    $actual = @{
      foo = 123
      bar = 333
      baz = 'aBc'
    }
    $expected = @{
      bar = 333
      foo = 123
      baz = 'AbC'
    }
    $actual | Should HaveDeepEquality $expected
    $actual | Should -HaveDeepEquality $expected
    $actual | Should -DEQ $expected
  }

  # TODO add support for this
  It 'Compares ordered hashtables properly' -Skip {
    # System.Collections.Specialized.OrderedDictionary
    $actual = [ordered]@{
      foo = 123
      bar = 333
    }
    $expected = [ordered]@{
      bar = 333
      foo = 123
    }
    $actual | Should HaveDeepEquality $expected
    $actual | Should -HaveDeepEquality $expected
    $actual | Should -DEQ $expected
  }

  It 'Compares unequal hashtables properly' {
    $actual = @{
      foo = 123
    }
    $expected = @{
      foo = 123
      bar = 333
    }
    $actual | Should Not HaveDeepEquality $expected
    $actual | Should -Not -HaveDeepEquality $expected
    $actual | Should -Not -DEQ $expected

    $actual | Should -Not -HaveDeepEquality @{}
    @{} | Should -Not -HaveDeepEquality $expected

    @{ foo = 'aBc' } | Should -Not -HaveDeepEquality @{ foo = 'aB' }
    $actual | Should -Not -HaveDeepEquality @{ foo = 'aB' }
    $actual | Should -Not -HaveDeepEquality @{ foo = 1 }
  }

  It 'Compares arrays of hashtables properly' {
    $actual = @(
      @{
        foo = 123
        bar = 333
      },
      @{},
      @{
        qux = 'yip'
      }
    )
    $expected = @(
      @{
        foo = 123
        bar = 333
      },
      @{},
      @{
        qux = 'yip'
      }
    )
    $actual | Should HaveDeepEquality $expected
    $actual | Should -HaveDeepEquality $expected
    $actual | Should -DEQ $expected
  }

  It 'Compares arrays of with similar hashtables in different order' {
    $actual = @(
      @{
        qux = 'yip'
      },
      @{
        foo = 123
        bar = 333
      },
      @{}
    )
    $expected = @(
      @{
        foo = 123
        bar = 333
      },
      @{},
      @{
        qux = 'yip'
      }
    )
    $actual | Should Not HaveDeepEquality $expected
    $actual | Should -Not -HaveDeepEquality $expected
    $actual | Should -Not -DEQ $expected
  }

  It 'Compares nested hashtables properly' {
    $actual = @{
      'literal-off' = 'off'
      'literal-yes' = 'yes'
      'literal-on' = 'on'
      'multi-value' = @('yarp', 'carp', 'narp')
      'pre-commit' = @{
        'disable' = 'false'
        'skip' = @(
          'pom.xml',
          'junit.java',
          'Runit.java',
          'Runit2.java'
        )
      }
    }
    $expected = @{
      'literal-off' = 'off'
      'literal-yes' = 'yes'
      'literal-on' = 'on'
      'multi-value' = @('yarp', 'carp', 'narp')
      'pre-commit' = @{
        'disable' = 'false'
        'skip' = @(
          'pom.xml',
          'junit.java',
          'Runit.java',
          'Runit2.java'
        )
      }
    }
    $actual | Should HaveDeepEquality $expected
    $actual | Should -HaveDeepEquality $expected
    $actual | Should -DEQ $expected
  }

  It 'Compares unequal nested hashtables properly' {
    $actual = @{
      'literal-off' = 'off'
      'literal-yes' = 'yes'
      'literal-on' = 'on'
      'multi-value' = @('yarp', 'carp', 'narp')
      'pre-commit' = @{
        'disable' = 'false'
        'skip' = @(
          'pom.xml',
          'junit.java',
          'Runit.java',
          'Runit2.java'
        )
      }
    }
    $expected = @{
      'literal-off' = 'off'
      'literal-yes' = 'yes'
      'literal-on' = 'on'
      'multi-value' = @('yarp', 'carp', 'narp')
      'pre-commit' = @{
        'disable' = 'false'
        'skip' = @(
          'pom2.xml',
          'junit.java',
          'Runit.java',
          'Runit2.java'
        )
      }
    }
    $expected2 = @{
      'literal-yes' = 'yes'
      'literal-on' = 'on'
      'multi-value' = @('yarp', 'carp', 'narp')
      'pre-commit' = @{
        'disable' = 'false'
        'skip' = @(
          'pom.xml',
          'junit.java',
          'Runit.java',
          'Runit2.java'
        )
      }
    }
    $expected3 = @{
      'literal-off' = 'off'
      'literal-yes' = 'yes'
      'literal-on' = 'on'
      'multi-value' = @('yarp', 3, 'narp')
      'pre-commit' = @{
        'disable' = 'false'
        'skip' = @(
          'pom2.xml',
          'junit.java',
          'Runit.java',
          'Runit2.java'
        )
      }
    }
    $expected4 = @{
      'literal-off' = 'off'
      'literal-yes' = 'yes'
      'literal-on' = 'on'
      'multi-value' = @('yarp', 'narp')
      'pre-commit' = @{
        'disable' = 'false'
        'skip' = @(
          'pom2.xml',
          'junit.java',
          'Runit.java',
          'Runit2.java'
        )
      }
    }
    $actual | Should Not HaveDeepEquality $expected
    $actual | Should -Not -HaveDeepEquality $expected
    $actual | Should -Not -DEQ $expected

    $actual | Should Not HaveDeepEquality $expected2
    $actual | Should -Not -HaveDeepEquality $expected2
    $actual | Should -Not -DEQ $expected2

    $actual | Should Not HaveDeepEquality $expected3
    $actual | Should -Not -HaveDeepEquality $expected3
    $actual | Should -Not -DEQ $expected3

    $actual | Should Not HaveDeepEquality $expected4
    $actual | Should -Not -HaveDeepEquality $expected4
    $actual | Should -Not -DEQ $expected4
  }

  It 'Compares PSCustomObjects properly' {
    $actual = [PSCustomObject]@{ Name = 'foo'; Value = 'bar' }
    $expected = [PSCustomObject]@{ Name = 'foo'; Value = 'bar' }

    $actual | Should HaveDeepEquality $expected
    $actual | Should -HaveDeepEquality $expected
    $actual | Should -DEQ $expected
  }

  It 'Compares unequal PSCustomObjects properly' {
    $actual = [PSCustomObject]@{ Name = 'foo'; Value = 'bar' }
    $expected = [PSCustomObject]@{ Name = 'baz'; Value = 'bar' }

    $actual | Should Not HaveDeepEquality $expected
    $actual | Should -Not -HaveDeepEquality $expected
    $actual | Should -Not -DEQ $expected
  }

  It 'Compares arrays with PSCustomObjects properly' {
    $actual = @(
      [PSCustomObject]@{ Name = 'foo'; Value = 'foo' },
      [PSCustomObject]@{ Name = 'baz'; Value = 'baz' }
    )
    $expected = @(
      [PSCustomObject]@{ Name = 'foo'; Value = 'foo' },
      [PSCustomObject]@{ Name = 'baz'; Value = 'baz' }
    )
    $expected2 = @(
      [PSCustomObject]@{ Name = '123'; Value = 'foo' },
      [PSCustomObject]@{ Name = 'baz'; Value = 'baz' }
    )
    $expected3 = @(
      [PSCustomObject]@{ Value = 'foo' },
      [PSCustomObject]@{ Name = 'baz'; Value = 'baz' }
    )

    $actual | Should HaveDeepEquality $expected
    $actual | Should -HaveDeepEquality $expected
    $actual | Should -DEQ $expected

    $actual | Should Not HaveDeepEquality $expected2
    $actual | Should -Not -HaveDeepEquality $expected2
    $actual | Should -Not -DEQ $expected2

    $actual | Should Not HaveDeepEquality $expected3
    $actual | Should -Not -HaveDeepEquality $expected3
    $actual | Should -Not -DEQ $expected3
  }

  It 'Compares hashtables with PSCustomObjects properly' {
    $actual = @{ a = 1; b = [PSCustomObject]@{ c = 2 } }
    $expected = @{ a = 1; b = [PSCustomObject]@{ c = 2 } }
    $expected2 = @{ a = 1; b = @{ c = 2 } }
    $expected3 = @{ a = 1; b = [PSCustomObject]@{ c = 3 } }

    $actual | Should HaveDeepEquality $expected
    $actual | Should -HaveDeepEquality $expected
    $actual | Should -DEQ $expected

    $actual | Should Not HaveDeepEquality $expected2
    $actual | Should -Not -HaveDeepEquality $expected2
    $actual | Should -Not -DEQ $expected2

    $actual | Should Not HaveDeepEquality $expected3
    $actual | Should -Not -HaveDeepEquality $expected3
    $actual | Should -Not -DEQ $expected3
  }

  It 'throws if the 2 arguments are not equal' {
    { 1 | Should -HaveDeepEquality 2 } `
      | Should -Throw "- Context: '[0]' Expected 2, but got 1"

    { 'a' | Should -HaveDeepEquality 'b' } `
      | Should -Throw "- Context: '[0]' Expected 'b', but got 'a'"

    { @('a') | Should -HaveDeepEquality @('b') } `
      | Should -Throw "- Context: '[0]' Expected 'b', but got 'a'"

    { @('a') | Should -HaveDeepEquality @('b', 'a') } `
      | Should -Throw "- Expected a collection with size 2, but got collection with size 1"

    { @{ foo = 'a' } | Should -HaveDeepEquality @{} } `
      | Should -Throw "- Context: 'foo' Expected `$null, but got 'a'"

    { @{ foo = 'a' } | Should -HaveDeepEquality @{ foo = 1 } } `
      | Should -Throw "- Context: 'foo' Expected 1, but got 'a'"

    { @{ foo = 'a' } | Should -HaveDeepEquality @{ bar = 'a' } } `
      | Should -Throw "- Context: 'foo' Expected `$null, but got 'a'"

    { @{ foo = 'a'; bar = @('b') } | Should -HaveDeepEquality @{ foo = 1; bar = @('b') } } `
      | Should -Throw "- Context: 'foo' Expected 1, but got 'a'"
  }

  It 'throws if the 2 arguments are equal' {
    { 1 | Should -Not -HaveDeepEquality 1 } `
      | Should -Throw '- Expected a collection with size different from 1, but got collection with that size 1'
    { 1 | Should -Not -HaveDeepEquality 1 } `
      | Should -Throw "- Context: '[0]' Expected 1 to be different from the actual value, but got the same value"

    { 'a' | Should -Not -HaveDeepEquality 'a' } `
      | Should -Throw "- Expected a collection with size different from 1, but got collection with that size a"
    { 'a' | Should -Not -HaveDeepEquality 'a' } `
      | Should -Throw "- Context: '[0]' Expected 'a' to be different from the actual value, but got the same value"

    { @('a') | Should -Not -HaveDeepEquality @('a') } `
      | Should -Throw "- Expected a collection with size different from 1, but got collection with that size a"
    { @('a') | Should -Not -HaveDeepEquality @('a') } `
      | Should -Throw "- Context: '[0]' Expected 'a' to be different from the actual value, but got the same value"

    { @{} | Should -Not -HaveDeepEquality @{} } `
      | Should -Throw `
        '- Expected a collection with size different from 1, but got collection with that size @(System.Collections.Hashtable)'

    { @{ foo = 'a' } | Should -Not -HaveDeepEquality @{ foo = 'a' } } `
      | Should -Throw `
        '- Expected a collection with size different from 1, but got collection with that size @(System.Collections.Hashtable)'
    { @{ foo = 'a' } | Should -Not -HaveDeepEquality @{ foo = 'a' } } `
      | Should -Throw "- Context: 'foo' Expected 'a' to be different from the actual value, but got the same value"
  }
}

Describe 'Should -HaveExactDeepEquality' {
  It 'passes if letter case matches' {
    'a' | Should HaveExactDeepEquality 'a'
    'a' | Should -HaveExactDeepEquality 'a'
    'a' | Should -DCEQ 'a'
  }

  It 'fails if letter case does not match' {
    'A' | Should Not HaveExactDeepEquality 'a'
    'A' | Should -Not -HaveExactDeepEquality 'a'
    'A' | Should -Not -DCEQ 'a'
  }

  It 'passes for numbers' {
    1 | Should HaveExactDeepEquality 1
    2.15 | Should HaveExactDeepEquality 2.15
    1 | Should -HaveExactDeepEquality 1
    2.15 | Should -HaveExactDeepEquality 2.15
    1 | Should -DCEQ 1
    2.15 | Should -DCEQ 2.15
  }

  It 'Compares arrays properly' {
    $array = @(1, 2, 3, 4, 'I am a string', (New-Object psobject -Property @{ IAm = 'An Object' }))
    $array | Should HaveExactDeepEquality $array
    $array | Should -HaveExactDeepEquality $array
    $array | Should -DCEQ $array
  }

  # TODO add support for this
  It 'returns true if the actual value can be cast to the expected value and they are the same value (case sensitive)' -Skip {
    {abc} | Should HaveExactDeepEquality 'abc'
    {abc} | Should -HaveExactDeepEquality 'abc'
    {abc} | Should -DCEQ 'abc'
  }

  It 'Compares arrays with correct case-sensitive behavior' {
    $string = 'I am a string'
    $array = @(1, 2, 3, 4, $string)
    $arrayWithCaps = @(1, 2, 3, 4, $string.ToUpper())

    $array | Should Not HaveExactDeepEquality $arrayWithCaps
    $array | Should -Not -HaveExactDeepEquality $arrayWithCaps
    $array | Should -Not -DCEQ $arrayWithCaps
  }

  It 'Compares hashtables with correct case-sensitive behavior' {
    $actual = @{ baz = 'aBc' }
    $caseSensitiveExpected = @{ baz = 'aBc' }
    $caseInsensitiveExpected = @{ baz = 'AbC' }

    $actual | Should HaveExactDeepEquality $caseSensitiveExpected
    $actual | Should -HaveExactDeepEquality $caseSensitiveExpected
    $actual | Should -DCEQ $caseSensitiveExpected

    $actual | Should Not HaveExactDeepEquality $caseInsensitiveExpected
    $actual | Should -Not -HaveExactDeepEquality $caseInsensitiveExpected
    $actual | Should -Not -DCEQ $caseInsensitiveExpected
  }
}
