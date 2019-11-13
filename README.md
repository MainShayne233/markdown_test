# MarkdownTest

Test the Elixir code in your markdown!

<!--- MARKDOWN_TEST_START -->
```elixir
iex> 1 + 2
3
```
<!--- MARKDOWN_TEST_END -->

<!--- MARKDOWN_TEST_START -->
```elixir
defmodule MyModule do
  def add(x, y), do: x + y
end

iex> x = 1
...> y = 2
...> MyModule.add(x, y)
3

iex> MyModule.add(1, 2)
4
```
<!--- MARKDOWN_TEST_END -->

