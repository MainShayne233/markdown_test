defmodule MarkdownTestTest do
  use ExUnit.Case
  doctest MarkdownTest

  test "greets the world" do
    assert MarkdownTest.hello() == :world
  end
end
