defmodule MarkdownTest do
  defmodule TestBlock do
    defstruct [:preface_code, cases: []]
  end

  @test_block_start "<!--- MARKDOWN_TEST_START -->"
  @test_block_end "<!--- MARKDOWN_TEST_END -->"

  @markdown_code_delimiter_pattern ~r/```(elixir)?/

  defmacro __using__([]) do
    quote do
      import MarkdownTest, only: [test_markdown: 1]
    end
  end

  defmacro test_markdown(path) do
    file = fetch_file!(path)

    test_blocks = parse_test_blocks!(file)

    describes =
      test_blocks
      |> Enum.with_index()
      |> Enum.map(fn {test_block, index} ->
        tests =
          test_block.cases
          |> Enum.with_index()
          |> Enum.map(fn {{expression, expected}, index} ->
            quote do
              test "case: #{unquote(index)}" do
                assert unquote(expression) === unquote(expected)
              end
            end
          end)

        quote do
          describe "block #{unquote(index)}" do
            unquote(test_block.preface_code)

            unquote_splicing(tests)
          end
        end
      end)

    quote do
      (unquote_splicing(describes))
    end
  end

  defp parse_test_blocks!(file) do
    file
    |> parse_raw_code_blocks!()
    |> Enum.map(&parse_code_block!/1)
  end

  defp parse_raw_code_blocks!(file) do
    file
    |> String.split(@test_block_start)
    |> Enum.drop(1)
    |> Enum.map(&(String.split(&1, @test_block_end) |> hd()))
    |> Enum.map(&String.replace(&1, @markdown_code_delimiter_pattern, ""))
  end

  defp parse_code_block!(raw_code_block) do
    preface_code = parse_preface_code!(raw_code_block)
    test_cases = parse_test_cases!(raw_code_block)

    %TestBlock{
      preface_code: preface_code,
      cases: test_cases
    }
  end

  defp parse_preface_code!(raw_code_block) do
    raw_code_block
    |> String.split("iex>")
    |> hd()
    |> String.trim()
    |> Code.string_to_quoted!()
  end

  defp parse_test_cases!(raw_code_block) do
    {raw_test_cases, _} =
      raw_code_block
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reduce({[], :init}, fn
        "iex> " <> expression_start, {cases, :init} ->
          {[{expression_start, nil} | cases], :expression}

        _, {cases, :init} ->
          {cases, :init}

        "...> " <> expression_chunk, {[{current_expression, nil} | cases], :expression} ->
          {[{current_expression <> "\n" <> expression_chunk, nil} | cases], :expression}

        expected_start, {[{current_expression, nil} | cases], :expression} ->
          {[{current_expression, expected_start} | cases], :expected}

        "" <> _, {cases, :expected} ->
          {cases, :init}

        expected_chunk, {[{current_expression, current_expected} | cases], :expected} ->
          {[{current_expression, current_expected <> "\n" <> expected_chunk} | cases]}
      end)

    raw_test_cases
    |> Enum.map(fn {raw_expression, raw_expected} ->
      {Code.string_to_quoted!(raw_expression), Code.string_to_quoted!(raw_expected)}
    end)
    |> Enum.reverse()
  end

  defp fetch_file!(path) do
    File.read(path)
    |> unwrap_or_raise("No file at path: #{path}")
  end

  defp unwrap_or_raise({:ok, term}, _message), do: term
  defp unwrap_or_raise(_, message), do: raise(%RuntimeError{message: message})
end
