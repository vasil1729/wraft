defmodule WraftDoc.ProsemirrorToMarkdown do
  @moduledoc """
  Prosemirror2Md is a library that converts ProseMirror Node JSON to Markdown.
  """

  @doc """
  Converts a ProseMirror Node JSON to Markdown.
  ## Examples
      iex> WraftDoc.ProsemirrorToMarkdown.convert(%{"type" => "doc", "content" => []})
      ""
      iex> WraftDoc.ProsemirrorToMarkdown.convert(%{"type" => "invalid"})
      ** (WraftDoc.ProsemirrorToMarkdown.InvalidJsonError) Invalid ProseMirror JSON format.
  """
  def convert(%{"type" => "doc", "content" => content}, opts \\ []) do
    Enum.map_join(content, "\n\n", &convert_node(&1, opts))
  end

  defp convert_node(%{"type" => "paragraph", "content" => content}, opts) do
    Enum.map_join(content, "", &convert_node(&1, opts))
  end

  defp convert_node(%{"type" => "paragraph"}, _opts), do: "\n"

  defp convert_node(
         %{"type" => "heading", "attrs" => %{"level" => level}, "content" => content},
         opts
       ) do
    heading = Enum.map_join(content, "", &convert_node(&1, opts))
    String.duplicate("#", level) <> " " <> heading
  end

  defp convert_node(%{"type" => "heading"}, _opts),
    do: raise(InvalidJsonError, "Invalid heading format.")

  defp convert_node(%{"type" => "text", "text" => text, "marks" => marks}, opts) do
    Enum.reduce(Enum.reverse(marks), text, &convert_mark(&2, &1, opts))
  end

  defp convert_node(%{"type" => "text", "text" => text}, _opts), do: text

  defp convert_node(%{"type" => "bulletList", "content" => content}, opts) do
    Enum.map_join(content, "\n", &convert_node(&1, opts))
  end

  defp convert_node(%{"type" => "image", "attrs" => %{"src" => src, "alt" => alt}}, _opts) do
    "![#{alt}](#{src})"
  end

  defp convert_node(%{"type" => "image"}, _opts),
    do: raise(InvalidJsonError, "Invalid image format.")

  defp convert_node(%{"type" => "holder", "attrs" => %{"named" => named}} = _attrs, _opts)
       when named != "" do
    named
  end

  defp convert_node(%{"type" => "holder", "attrs" => %{"name" => name}}, _opts) do
    "[#{name}]"
  end

  defp convert_node(%{"type" => "holder"}, _opts),
    do: raise(InvalidJsonError, "Invalid holder format.")

  defp convert_node(%{"type" => "table", "content" => rows}, opts) do
    header = convert_table_row(hd(rows), opts, true)
    separator = create_table_separator(hd(rows))
    body = Enum.map_join(tl(rows), "\n", &convert_table_row(&1, opts, false))

    Enum.join([header, separator, body], "\n")
  end

  defp convert_node(%{"type" => "orderedList", "content" => content}, opts) do
    content
    |> Enum.with_index(1)
    |> Enum.map_join("\n", fn {node, index} -> "#{index}. " <> convert_node(node, opts) end)
  end

  defp convert_node(%{"type" => "listItem", "content" => content}, opts) do
    Enum.map_join(content, "", &convert_node(&1, opts))
  end

  defp convert_node(%{"type" => "blockquote", "content" => content}, opts) do
    content
    |> Enum.map_join("\n", &convert_node(&1, opts))
    |> wrap_lines("> ")
  end

  defp convert_node(%{"type" => "codeBlock", "content" => content}, opts) do
    content = Enum.map_join(content, "", &convert_node(&1, opts))
    "```\n#{content}\n```"
  end

  defp convert_node(%{"type" => "hardBreak"}, _opts), do: "  \n"
  defp convert_node(%{"type" => "horizontalRule"}, _opts), do: "---"

  defp convert_node(%{"type" => type}, _opts),
    do: raise(InvalidJsonError, "Invalid node type: #{type}")

  defp convert_mark(text, %{"type" => "bold"}, _opts), do: "**#{text}**"
  defp convert_mark(text, %{"type" => "italic"}, _opts), do: "*#{text}*"
  defp convert_mark(text, %{"type" => "code"}, _opts), do: "`#{text}`"

  defp convert_mark(text, %{"type" => "link", "attrs" => %{"href" => href}}, _opts),
    do: "[#{text}](#{href})"

  defp convert_mark(text, %{"type" => "strike"}, _opts), do: "~~#{text}~~"

  defp convert_mark(_text, %{"type" => type}, _opts),
    do: raise(InvalidJsonError, "Invalid mark type: #{type}")

  defp wrap_lines(text, prefix) do
    Enum.map_join(String.split(text, "\n"), "\n", &(prefix <> &1))
  end

  # Table utility functions
  defp convert_table_row(%{"content" => cells}, opts, is_header) do
    cells
    |> Enum.map_join(" | ", &convert_table_cell(&1, opts, is_header))
    |> wrap_table_row
  end

  defp convert_table_cell(%{"type" => "tableCell", "content" => content}, opts, is_header) do
    cell_content = Enum.map_join(content, " ", &convert_node(&1, opts))
    if is_header, do: cell_content, else: String.trim(cell_content)
  end

  defp convert_table_cell(%{"type" => "tableControllerCell"}, _opts, _is_header), do: ""

  defp create_table_separator(%{"content" => cells}) do
    cells
    |> Enum.map_join(" | ", fn
      %{"type" => "tableCell"} -> "---"
      %{"type" => "tableControllerCell"} -> ""
    end)
    |> wrap_table_row
  end

  defp wrap_table_row(row) do
    "| " <> row <> " |"
  end
end

defmodule InvalidJsonError do
  defexception [:message]
end
