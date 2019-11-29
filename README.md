# MarkdownTest

[![Build Status](https://secure.travis-ci.org/MainShayne233/markdown_test.svg?branch=master "Build Status")](http://travis-ci.org/MainShayne233/markdown_test)
[![Coverage Status](https://coveralls.io/repos/github/MainShayne233/markdown_test/badge.svg?branch=master)](https://coveralls.io/github/MainShayne233/markdown_test?branch=master)
[![Hex Version](http://img.shields.io/hexpm/v/markdown_test.svg?style=flat)](https://hex.pm/packages/markdown_test)

Test the Elixir code in your markdown!

## Usage

Add `:markdown_test` as a dependency in your `mix.exs` file:

```elixir
# mix.exs

defp deps do
  [
    {:markdown_test, "0.1.1", only: :test}
  ]
end
```

In any test module, `use MarkdownTest` to pull in the `test_markdown/1` macro and call it for your markdown file:

```elixir
defmodule MyLibraryTest do
  use MarkdownTest

  test_markdown("README.md")
end
```

Then add some Elixir code to test in your markdown file.

The format roughly resembles that of a [`doctest`](https://elixir-lang.org/getting-started/mix-otp/docs-tests-and-with.html).

In order to be picked up, a code block must be between the following markdown comment tags:

`<!--- MARKDOWN_TEST_START -->`

...code

`<!--- MARKDOWN_TEST_END -->`.

### Examples

<!--- MARKDOWN_TEST_START -->
```elixir
iex> 1 + 2
3
```
<!--- MARKDOWN_TEST_END -->

The expression and expected values can span multiple lines:

<!--- MARKDOWN_TEST_START -->
```elixir
iex> a = %{cool: :beans}
...> b = %{beans: :cool}
...> Map.merge(a, b)
%{
  cool: :beans,
  beans: :cool
}
```
<!--- MARKDOWN_TEST_END -->

You can also include any setup code that needs to be run prior to testing the code:

<!--- MARKDOWN_TEST_START -->
```elixir
defmodule MyModule do
  def add(x, y), do: x + y
end

iex> MyModule.add(1, 2)
3
```
<!--- MARKDOWN_TEST_END -->

If you don't add any assertion code, `markdown_test` will just verify that the code snippit compiles, like:

<!--- MARKDOWN_TEST_START -->
```elixir
%{
  this: %{
    "should" => :compile
  }
}
```
<!--- MARKDOWN_TEST_END -->
