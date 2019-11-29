defmodule MarkdownTest do
  @moduledoc File.read!("README.md")

  defmodule TestBlock do
    defstruct [:preface_code, cases: []]
  end

  @test_block_start "<!--- MARKDOWN_TEST_START -->"
  @test_block_end "<!--- MARKDOWN_TEST_END -->"
  @iex_prompt "iex> "
  @iex_prompt_cont "...> "
  @markdown_code_ticks "```"

  defmacro __using__([]) do
    quote do
      import MarkdownTest, only: [test_markdown: 1]
    end
  end

  @doc """
  This macro will test the assertions defined in the markdown file
  located at the given path.
  """
  @spec test_markdown(path :: Path.t()) :: Macro.t()
  defmacro test_markdown(path) do
    file = fetch_file!(path)

    lines =
      file
      |> String.split("\n")
      |> Enum.with_index()
      |> Enum.map(fn {code, index} -> {String.trim(code), index + 1} end)

    test_blocks = parse_test_blocks!(lines)

    sections =
      test_blocks
      |> Enum.map(fn test_block ->
        tests =
          case test_block do
            %TestBlock{cases: [_ | _] = cases} ->
              Enum.map(cases, fn {expression, expected} ->
                quoted_expression = compile_block(expression, path)
                display_expression = display_block(expression)
                quoted_expected = compile_block(expected, path)
                starting_line = starting_line(expression)

                quote do
                  test "markdown assertion starting at #{unquote(starting_line)} in #{
                         unquote(path)
                       }" do
                    actual = unquote(quoted_expression)
                    expected = unquote(quoted_expected)

                    assert actual === expected, """
                    Markdown test assertion failed for case in #{unquote(path)} starting on line #{
                      unquote(starting_line)
                    }

                    I was expecting the following expression:

                    #{unquote(display_expression)}

                    To exactly equal:

                    #{inspect(expected)}

                    But instead I got:

                    #{inspect(actual)}
                    """
                  end
                end
              end)

            %TestBlock{cases: [], preface_code: [{_, starting_line} | _]} ->
              [
                quote do
                  test "markdown compile-check starting at #{unquote(starting_line)} in #{
                         unquote(path)
                       }" do
                    assert true
                  end
                end
              ]
          end

        quote do
          defmodule unquote(test_module_name(__CALLER__.module, test_block, path)) do
            use ExUnit.Case

            unquote(compile_block(test_block.preface_code, path))
            unquote_splicing(tests)
          end
        end
      end)

    quote do
      (unquote_splicing(sections))
    end
  rescue
    error in RuntimeError ->
      raise %CompileError{
        description: """


        Something went wrong when testing the markdown in #{path}.

        Underyling error:

        #{error.message}
        """
      }
  end

  defp test_module_name(parent_module, test_block, path) do
    starting_line =
      case test_block do
        %TestBlock{cases: [{block, _} | _]} ->
          starting_line(block)

        %TestBlock{preface_code: [{_, line_number} | _], cases: []} ->
          line_number
      end

    path_module_chunk =
      path
      |> String.split(".")
      |> hd()
      |> Macro.camelize()

    module_subname =
      String.to_atom("MarkdownTest.#{path_module_chunk}.BlockAtLine#{starting_line}")

    Module.concat([parent_module, module_subname])
  end

  defp display_block(block) do
    block
    |> Enum.map(&elem(&1, 0))
    |> Enum.join("\n")
  end

  defp compile_block([], _path), do: :ok

  defp compile_block(block, path) do
    code_string = display_block(block)

    starting_line = starting_line(block)

    Code.string_to_quoted!(code_string, file: path, line: starting_line)
  end

  defp starting_line(block) do
    block
    |> Enum.map(&elem(&1, 1))
    |> Enum.min()
  end

  defp parse_test_blocks!(lines) do
    lines
    |> parse_raw_code_blocks!()
    |> Enum.map(&parse_code_block!/1)
  end

  defp parse_raw_code_blocks!(lines) do
    {raw_blocks, :init} =
      Enum.reduce(lines, {[], :init}, fn
        {@test_block_start <> _, _}, {blocks, :init} ->
          {blocks, :in_block}

        {@markdown_code_ticks <> _, _}, {blocks, :in_block} ->
          {[[] | blocks], :in_block}

        {@test_block_end <> _, _}, {blocks, :in_block} ->
          {blocks, :init}

        line, {[block | blocks], :in_block} ->
          {[[line | block] | blocks], :in_block}

        _, {blocks, :init} ->
          {blocks, :init}
      end)

    raw_blocks
    |> Enum.reject(&Enum.empty?/1)
    |> Enum.map(&Enum.reverse/1)
    |> Enum.reverse()
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
    Enum.take_while(raw_code_block, fn {code, _} ->
      not match?(@iex_prompt <> _, code)
    end)
  end

  defp parse_test_cases!(raw_code_block) do
    {raw_test_cases, _} =
      raw_code_block
      |> Enum.reduce({[], :init}, fn
        {@iex_prompt <> expression_start, line_number}, {cases, :init} ->
          {[{[{expression_start, line_number}], nil} | cases], :expression}

        _, {cases, :init} ->
          {cases, :init}

        {@iex_prompt_cont <> expression_chunk, line_number},
        {[{current_expression, nil} | cases], :expression} ->
          {[{[{expression_chunk, line_number} | current_expression], nil} | cases], :expression}

        expected_start, {[{current_expression, nil} | cases], :expression} ->
          {[{current_expression, [expected_start]} | cases], :expected}

        {"", _}, {cases, :expected} ->
          {cases, :init}

        expected_chunk, {[{current_expression, current_expected} | cases], :expected} ->
          {[{current_expression, [expected_chunk | current_expected]} | cases], :expected}
      end)

    raw_test_cases
    |> Enum.map(fn
      {expression, nil} ->
        raise %RuntimeError{
          message: """
          Could not determine expected value for example starting on
          line #{starting_line(expression)} of the markdown file.
          """
        }

      {expression, expected} ->
        {Enum.reverse(expression), Enum.reverse(expected)}
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
