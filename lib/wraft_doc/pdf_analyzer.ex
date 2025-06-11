defmodule WraftDoc.PdfAnalyzer do
  @moduledoc """
  Elixir wrapper for the PDF analyzer and signature placement NIF.

  This module provides functions to:
  - Analyze PDF documents to detect coordinates and rectangles
  - Place signature images at specific coordinates in PDFs
  """

  use Rustler,
    otp_app: :wraft_doc,
    crate: "pdf_analyzer",
    mode: :release,
    load_from: {:wraft_doc, "priv/native/libpdf_analyzer"}

  @doc """
  Analyzes a PDF document to detect rectangles and coordinates.

  ## Parameters
  - `path`: Path to the PDF file
  - `target_fill_color`: Optional target fill color to filter rectangles (currently ignored, uses predefined colors)
  - `target_stroke_color`: Optional target stroke color to filter rectangles (currently ignored, uses predefined colors)
  - `engine`: Analysis engine to use ("typst" or "latex", defaults to "typst")

  ## Returns
  - `{:ok, json_result}` on success with analysis results as JSON string
  - `{:error, reason}` on failure

  ## Example
      iex> WraftDoc.PdfAnalyzer.analyze_pdf("/path/to/document.pdf", nil, nil, "typst")
      {:ok, "{\"total_pages\":1,\"total_rectangles\":2,\"rectangles\":[...]}"}
  """
  def analyze_pdf(path, target_fill_color \\ nil, target_stroke_color \\ nil, engine \\ "typst") do
    analyze_pdf_nif(path, target_fill_color, target_stroke_color, engine)
  end

  @doc """
  Places a signature image at specific coordinates in a PDF.

  ## Parameters
  - `pdf_path`: Path to the input PDF file
  - `signature_path`: Path to the signature image file (PNG, JPEG, etc.)
  - `x`: X coordinate for signature placement (in PDF points)
  - `y`: Y coordinate for signature placement (in PDF points, from top-left)
  - `page_number`: Page number to place signature on (1-based)
  - `output_path`: Optional output path for the signed PDF (defaults to input_signed.pdf)
  - `signature_width`: Optional width to resize signature to (in PDF points)
  - `signature_height`: Optional height to resize signature to (in PDF points)

  ## Returns
  - `{:ok, json_result}` on success with placement result as JSON string
  - `{:error, reason}` on failure

  ## Example
      iex> WraftDoc.PdfAnalyzer.place_signature("/path/to/document.pdf", "/path/to/signature.png", 100.0, 200.0, 1, nil, 80.0, 40.0)
      {:ok, "{\"success\":true,\"message\":\"Signature placed successfully...\",\"output_path\":\"/path/to/document_signed.pdf\"}"}
  """
  def place_signature(pdf_path, signature_path, x, y, page_number, output_path \\ nil, signature_width \\ nil, signature_height \\ nil) do
    place_signature_nif(pdf_path, signature_path, x, y, page_number, output_path, signature_width, signature_height)
  end

  @doc """
  Analyzes a PDF using the typst engine and returns parsed results.

  ## Parameters
  - `path`: Path to the PDF file

  ## Returns
  - `{:ok, %{rectangles: [...], total_pages: n, total_rectangles: n}}` on success
  - `{:error, reason}` on failure
  """
  def analyze_pdf_typst(path) do
    case analyze_pdf(path, nil, nil, "typst") do
      {:ok, json_string} ->
        case Jason.decode(json_string) do
          {:ok, data} -> {:ok, data}
          {:error, _} = error -> error
        end
      {:error, _} = error -> error
    end
  end

  @doc """
  Analyzes a PDF using the latex engine and returns parsed results.

  ## Parameters
  - `path`: Path to the PDF file

  ## Returns
  - `{:ok, %{rectangles: [...], total_pages: n, total_rectangles: n}}` on success
  - `{:error, reason}` on failure
  """
  def analyze_pdf_latex(path) do
    case analyze_pdf(path, nil, nil, "latex") do
      {:ok, json_string} ->
        case Jason.decode(json_string) do
          {:ok, data} -> {:ok, data}
          {:error, _} = error -> error
        end
      {:error, _} = error -> error
    end
  end

  @doc """
  Places a signature and returns parsed results.

  ## Parameters
  - Same as place_signature/8

  ## Returns
  - `{:ok, %{success: boolean, message: string, output_path: string}}` on success
  - `{:error, reason}` on failure
  """
  def place_signature_parsed(pdf_path, signature_path, x, y, page_number, output_path \\ nil, signature_width \\ nil, signature_height \\ nil) do
    case place_signature(pdf_path, signature_path, x, y, page_number, output_path, signature_width, signature_height) do
      {:ok, json_string} ->
        case Jason.decode(json_string) do
          {:ok, data} -> {:ok, data}
          {:error, _} = error -> error
        end
      {:error, _} = error -> error
    end
  end

  @doc """
  Detects signature placement coordinates using the typst engine.

  This function analyzes a PDF to find rectangles that match the target colors
  and returns their coordinates for potential signature placement.

  ## Parameters
  - `path`: Path to the PDF file

  ## Returns
  - `{:ok, coordinates_list}` where coordinates_list is a list of maps with x, y, page, width, height
  - `{:error, reason}` on failure
  """
  def detect_signature_coordinates(path) do
    case analyze_pdf_typst(path) do
      {:ok, %{"rectangles" => rectangles}} ->
        coordinates = Enum.map(rectangles, fn rect ->
          %{
            x: rect["position"]["x"],
            y: rect["position"]["y"],
            page: rect["page"],
            width: rect["dimensions"]["width"],
            height: rect["dimensions"]["height"]
          }
        end)
        {:ok, coordinates}
      {:error, _} = error -> error
    end
  end

  # NIF function stubs - these will be replaced by the actual NIF implementations
  defp analyze_pdf_nif(_path, _target_fill_color, _target_stroke_color, _engine) do
    :erlang.nif_error(:nif_not_loaded)
  end

  defp place_signature_nif(_pdf_path, _signature_path, _x, _y, _page_number, _output_path, _signature_width, _signature_height) do
    :erlang.nif_error(:nif_not_loaded)
  end
end
