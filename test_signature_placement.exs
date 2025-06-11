#!/usr/bin/env elixir

# Test script for PDF signature placement functionality
# This script demonstrates how to:
# 1. Analyze a PDF to detect coordinates using the typst engine
# 2. Place a signature image at detected coordinates
# 3. Validate the placement

defmodule SignaturePlacementTest do
  @moduledoc """
  Test module for signature placement functionality.
  """

  # File paths as specified by the user
  @pdf_path "/home/ultimatum/workspace/wraft/organisations/653736e2-7c8f-4b57-bcad-ef3ed1056cc9/contents/VARZ0006/VARZ0006-v2.pdf"
  @signature_path "/home/ultimatum/workspace/helpers/append_certificate/signature.png"

  # Alternative local paths for testing if the above don't exist
  @local_pdf_path "./test_files/sample.pdf"
  @local_signature_path "./test_files/signature.png"

  def run do
    IO.puts("=== PDF Signature Placement Test ===\n")

    # Determine which files to use
    {pdf_path, signature_path} = determine_file_paths()

    IO.puts("Using PDF: #{pdf_path}")
    IO.puts("Using Signature: #{signature_path}")
    IO.puts("")

    # Step 1: Analyze PDF to detect coordinates
    IO.puts("Step 1: Analyzing PDF to detect coordinates...")
    case analyze_pdf_coordinates(pdf_path) do
      {:ok, coordinates} ->
        IO.puts("✓ Found #{length(coordinates)} coordinate(s)")
        print_coordinates(coordinates)

        # Step 2: Place signature at detected coordinates
        if length(coordinates) > 0 do
          test_signature_placement(pdf_path, signature_path, coordinates)
        else
          IO.puts("⚠ No coordinates detected, testing with manual coordinates...")
          test_manual_placement(pdf_path, signature_path)
        end

      {:error, reason} ->
        IO.puts("✗ Failed to analyze PDF: #{reason}")
        IO.puts("Testing with manual coordinates...")
        test_manual_placement(pdf_path, signature_path)
    end
  end

  defp determine_file_paths do
    pdf_path = if File.exists?(@pdf_path), do: @pdf_path, else: @local_pdf_path
    signature_path = if File.exists?(@signature_path), do: @signature_path, else: @local_signature_path

    # Create test files if they don't exist
    unless File.exists?(pdf_path) do
      create_sample_pdf(pdf_path)
    end

    unless File.exists?(signature_path) do
      create_sample_signature(signature_path)
    end

    {pdf_path, signature_path}
  end

  defp analyze_pdf_coordinates(pdf_path) do
    try do
      case WraftDoc.PdfAnalyzer.detect_signature_coordinates(pdf_path) do
        {:ok, coordinates} -> {:ok, coordinates}
        {:error, reason} -> {:error, reason}
      end
    rescue
      e -> {:error, "Exception: #{inspect(e)}"}
    end
  end

  defp print_coordinates(coordinates) do
    IO.puts("\nDetected coordinates:")
    Enum.with_index(coordinates, 1)
    |> Enum.each(fn {coord, index} ->
      IO.puts("  #{index}. Page #{coord.page}: (#{coord.x}, #{coord.y}) - #{coord.width}x#{coord.height}")
    end)
    IO.puts("")
  end

  defp test_signature_placement(pdf_path, signature_path, coordinates) do
    IO.puts("Step 2: Testing signature placement at detected coordinates...")

    # Use the first detected coordinate
    coord = List.first(coordinates)

    # Calculate signature size (use detected rectangle size or default)
    sig_width = min(coord.width, 100.0)  # Max 100 points wide
    sig_height = min(coord.height, 50.0)  # Max 50 points high

    output_path = Path.dirname(pdf_path) <> "/#{Path.basename(pdf_path, ".pdf")}_signed.pdf"

    IO.puts("Placing signature at: (#{coord.x}, #{coord.y}) on page #{coord.page}")
    IO.puts("Signature size: #{sig_width}x#{sig_height}")
    IO.puts("Output: #{output_path}")

    case place_signature(pdf_path, signature_path, coord.x, coord.y, coord.page, output_path, sig_width, sig_height) do
      {:ok, result} ->
        IO.puts("✓ Signature placed successfully!")
        IO.puts("  Message: #{result["message"]}")
        IO.puts("  Output file: #{result["output_path"]}")

        # Verify the output file exists
        if File.exists?(result["output_path"]) do
          IO.puts("✓ Output file created successfully")

          # Analyze the signed PDF to verify placement
          verify_signature_placement(result["output_path"])
        else
          IO.puts("✗ Output file not found")
        end

      {:error, reason} ->
        IO.puts("✗ Failed to place signature: #{reason}")
    end
  end

  defp test_manual_placement(pdf_path, signature_path) do
    IO.puts("Step 2: Testing signature placement with manual coordinates...")

    # Use manual coordinates for testing
    x = 100.0
    y = 200.0
    page = 1
    sig_width = 80.0
    sig_height = 40.0

    output_path = Path.dirname(pdf_path) <> "/#{Path.basename(pdf_path, ".pdf")}_manual_signed.pdf"

    IO.puts("Placing signature at: (#{x}, #{y}) on page #{page}")
    IO.puts("Signature size: #{sig_width}x#{sig_height}")
    IO.puts("Output: #{output_path}")

    case place_signature(pdf_path, signature_path, x, y, page, output_path, sig_width, sig_height) do
      {:ok, result} ->
        IO.puts("✓ Signature placed successfully!")
        IO.puts("  Message: #{result["message"]}")
        IO.puts("  Output file: #{result["output_path"]}")

      {:error, reason} ->
        IO.puts("✗ Failed to place signature: #{reason}")
    end
  end

  defp place_signature(pdf_path, signature_path, x, y, page, output_path, width, height) do
    try do
      case WraftDoc.PdfAnalyzer.place_signature_parsed(pdf_path, signature_path, x, y, page, output_path, width, height) do
        {:ok, result} -> {:ok, result}
        {:error, reason} -> {:error, reason}
      end
    rescue
      e -> {:error, "Exception: #{inspect(e)}"}
    end
  end

  defp verify_signature_placement(signed_pdf_path) do
    IO.puts("\nStep 3: Verifying signature placement...")

    case analyze_pdf_coordinates(signed_pdf_path) do
      {:ok, coordinates} ->
        IO.puts("✓ Signed PDF analyzed successfully")
        IO.puts("  Found #{length(coordinates)} elements in signed PDF")

      {:error, reason} ->
        IO.puts("⚠ Could not analyze signed PDF: #{reason}")
    end
  end

  defp create_sample_pdf(path) do
    IO.puts("Creating sample PDF at #{path}...")
    File.mkdir_p!(Path.dirname(path))

    # Create a simple PDF content (this is a minimal PDF structure)
    pdf_content = """
    %PDF-1.4
    1 0 obj
    <<
    /Type /Catalog
    /Pages 2 0 R
    >>
    endobj
    2 0 obj
    <<
    /Type /Pages
    /Kids [3 0 R]
    /Count 1
    >>
    endobj
    3 0 obj
    <<
    /Type /Page
    /Parent 2 0 R
    /MediaBox [0 0 612 792]
    /Contents 4 0 R
    >>
    endobj
    4 0 obj
    <<
    /Length 44
    >>
    stream
    BT
    /F1 12 Tf
    100 700 Td
    (Sample PDF for testing) Tj
    ET
    endstream
    endobj
    xref
    0 5
    0000000000 65535 f
    0000000009 00000 n
    0000000058 00000 n
    0000000115 00000 n
    0000000206 00000 n
    trailer
    <<
    /Size 5
    /Root 1 0 R
    >>
    startxref
    300
    %%EOF
    """

    File.write!(path, pdf_content)
    IO.puts("✓ Sample PDF created")
  end

  defp create_sample_signature(path) do
    IO.puts("Creating sample signature image at #{path}...")
    File.mkdir_p!(Path.dirname(path))

    # Create a simple PNG (1x1 pixel red image)
    # This is a minimal PNG file in base64
    png_data = Base.decode64!("""
    iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==
    """)

    File.write!(path, png_data)
    IO.puts("✓ Sample signature image created")
  end
end

# Run the test
SignaturePlacementTest.run()
