# MarkdownTest

Test the Elixir code in your markdown!

## Usage

Add `:markdown_test` as a dependency in your `mix.exs` file:

```elixir
# mix.exs

defp deps do
  [
    {:markdown_test, "0.1.0", only: :test}
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
