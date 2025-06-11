#!/usr/bin/env elixir

# Demonstration of the PDF Signature Placement Workflow
# This script shows how the signature placement feature would work
# when integrated with the existing codebase

defmodule SignatureWorkflowDemo do
  @moduledoc """
  Demonstrates the complete workflow for PDF signature placement:
  1. Analyze PDF using typst engine to detect coordinates
  2. Place signature at detected coordinates
  3. Verify the placement
  """

  # File paths as specified in requirements
  @pdf_path "/home/ultimatum/workspace/wraft/organisations/653736e2-7c8f-4b57-bcad-ef3ed1056cc9/contents/VARZ0006/VARZ0006-v2.pdf"
  @signature_path "/home/ultimatum/workspace/helpers/append_certificate/signature.png"

  def run do
    IO.puts("=== PDF Signature Placement Workflow Demo ===\n")
    
    # Step 1: Demonstrate coordinate detection
    demonstrate_coordinate_detection()
    
    # Step 2: Demonstrate signature placement
    demonstrate_signature_placement()
    
    # Step 3: Show integration possibilities
    demonstrate_integration_scenarios()
  end

  defp demonstrate_coordinate_detection do
    IO.puts("Step 1: Coordinate Detection using Typst Engine")
    IO.puts("=" <> String.duplicate("=", 50))
    
    IO.puts("Input PDF: #{@pdf_path}")
    IO.puts("Target Colors:")
    IO.puts("  - Fill: RGB(214, 255, 244)")
    IO.puts("  - Stroke: RGB(0, 184, 148)")
    IO.puts("")
    
    # Simulate the analysis result that would come from the typst engine
    simulated_analysis = %{
      "total_pages" => 1,
      "total_rectangles" => 2,
      "rectangles" => [
        %{
          "page" => 1,
          "position" => %{"x" => 150.0, "y" => 200.0},
          "dimensions" => %{"width" => 120.0, "height" => 40.0},
          "corners" => %{"x1" => 150.0, "y1" => 200.0, "x2" => 270.0, "y2" => 240.0},
          "fill_color" => "RGB(214, 255, 244)",
          "stroke_color" => "RGB(0, 184, 148)",
          "operation_type" => "Rectangle"
        },
        %{
          "page" => 1,
          "position" => %{"x" => 300.0, "y" => 500.0},
          "dimensions" => %{"width" => 100.0, "height" => 35.0},
          "corners" => %{"x1" => 300.0, "y1" => 500.0, "x2" => 400.0, "y2" => 535.0},
          "fill_color" => "RGB(214, 255, 244)",
          "stroke_color" => "RGB(0, 184, 148)",
          "operation_type" => "Rectangle"
        }
      ]
    }
    
    IO.puts("Analysis Result (simulated):")
    IO.puts("  Total pages: #{simulated_analysis["total_pages"]}")
    IO.puts("  Total rectangles found: #{simulated_analysis["total_rectangles"]}")
    IO.puts("")
    
    # Extract coordinates
    coordinates = extract_coordinates(simulated_analysis)
    
    IO.puts("Detected signature placement coordinates:")
    Enum.with_index(coordinates, 1)
    |> Enum.each(fn {coord, index} ->
      IO.puts("  #{index}. Page #{coord.page}: (#{coord.x}, #{coord.y}) - #{coord.width}x#{coord.height}")
    end)
    
    IO.puts("")
    coordinates
  end

  defp demonstrate_signature_placement do
    IO.puts("Step 2: Signature Placement")
    IO.puts("=" <> String.duplicate("=", 30))
    
    # Use the first coordinate from detection
    coord = %{x: 150.0, y: 200.0, page: 1, width: 120.0, height: 40.0}
    
    IO.puts("Selected coordinate: Page #{coord.page} at (#{coord.x}, #{coord.y})")
    IO.puts("Signature image: #{@signature_path}")
    IO.puts("")
    
    # Calculate optimal signature size
    sig_width = min(coord.width * 0.8, 100.0)  # 80% of detected area, max 100pt
    sig_height = min(coord.height * 0.8, 50.0)  # 80% of detected area, max 50pt
    
    IO.puts("Calculated signature dimensions:")
    IO.puts("  Width: #{sig_width} points")
    IO.puts("  Height: #{sig_height} points")
    IO.puts("")
    
    # Simulate the signature placement call
    placement_params = %{
      pdf_path: @pdf_path,
      signature_path: @signature_path,
      x: coord.x,
      y: coord.y,
      page_number: coord.page,
      output_path: generate_output_path(@pdf_path),
      signature_width: sig_width,
      signature_height: sig_height
    }
    
    IO.puts("Signature placement parameters:")
    IO.puts("  PDF: #{placement_params.pdf_path}")
    IO.puts("  Signature: #{placement_params.signature_path}")
    IO.puts("  Position: (#{placement_params.x}, #{placement_params.y})")
    IO.puts("  Page: #{placement_params.page_number}")
    IO.puts("  Output: #{placement_params.output_path}")
    IO.puts("  Size: #{placement_params.signature_width}x#{placement_params.signature_height}")
    IO.puts("")
    
    # Simulate successful placement
    simulated_result = %{
      "success" => true,
      "message" => "Signature placed successfully at coordinates (#{coord.x}, #{coord.y}) on page #{coord.page}",
      "output_path" => placement_params.output_path
    }
    
    IO.puts("Placement Result (simulated):")
    IO.puts("  Success: #{simulated_result["success"]}")
    IO.puts("  Message: #{simulated_result["message"]}")
    IO.puts("  Output file: #{simulated_result["output_path"]}")
    IO.puts("")
  end

  defp demonstrate_integration_scenarios do
    IO.puts("Step 3: Integration Scenarios")
    IO.puts("=" <> String.duplicate("=", 35))
    
    IO.puts("Scenario A: Automatic Signature Placement")
    IO.puts("  1. User uploads PDF document")
    IO.puts("  2. System analyzes PDF using typst engine")
    IO.puts("  3. System detects signature areas (colored rectangles)")
    IO.puts("  4. User selects signature image")
    IO.puts("  5. System automatically places signature at detected coordinates")
    IO.puts("  6. System returns signed PDF")
    IO.puts("")
    
    IO.puts("Scenario B: Manual Coordinate Specification")
    IO.puts("  1. User uploads PDF document")
    IO.puts("  2. User specifies exact coordinates for signature")
    IO.puts("  3. User uploads signature image")
    IO.puts("  4. System places signature at specified coordinates")
    IO.puts("  5. System returns signed PDF")
    IO.puts("")
    
    IO.puts("Scenario C: Batch Processing")
    IO.puts("  1. User uploads multiple PDF documents")
    IO.puts("  2. System analyzes each PDF for signature areas")
    IO.puts("  3. System applies same signature to all detected areas")
    IO.puts("  4. System returns all signed PDFs")
    IO.puts("")
    
    IO.puts("Code Examples:")
    IO.puts("")
    
    # Example 1: Automatic placement
    IO.puts("# Automatic placement based on detected coordinates")
    IO.puts("""
    {:ok, coordinates} = WraftDoc.PdfAnalyzer.detect_signature_coordinates(pdf_path)
    coord = List.first(coordinates)
    
    {:ok, result} = WraftDoc.PdfAnalyzer.place_signature_parsed(
      pdf_path, signature_path, coord.x, coord.y, coord.page
    )
    """)
    
    # Example 2: Manual placement
    IO.puts("# Manual placement at specific coordinates")
    IO.puts("""
    {:ok, result} = WraftDoc.PdfAnalyzer.place_signature_parsed(
      pdf_path, signature_path, 100.0, 200.0, 1, nil, 80.0, 40.0
    )
    """)
    
    # Example 3: Batch processing
    IO.puts("# Batch processing multiple PDFs")
    IO.puts("""
    pdf_files = ["/path/to/doc1.pdf", "/path/to/doc2.pdf"]
    
    results = Enum.map(pdf_files, fn pdf_path ->
      {:ok, coordinates} = WraftDoc.PdfAnalyzer.detect_signature_coordinates(pdf_path)
      coord = List.first(coordinates)
      
      WraftDoc.PdfAnalyzer.place_signature_parsed(
        pdf_path, signature_path, coord.x, coord.y, coord.page
      )
    end)
    """)
  end

  defp extract_coordinates(analysis_result) do
    analysis_result["rectangles"]
    |> Enum.map(fn rect ->
      %{
        x: rect["position"]["x"],
        y: rect["position"]["y"],
        page: rect["page"],
        width: rect["dimensions"]["width"],
        height: rect["dimensions"]["height"]
      }
    end)
  end

  defp generate_output_path(input_path) do
    path = Path.absname(input_path)
    dir = Path.dirname(path)
    basename = Path.basename(path, ".pdf")
    Path.join(dir, "#{basename}_signed.pdf")
  end
end

# Run the demonstration
SignatureWorkflowDemo.run()

IO.puts("\n=== Demo Complete ===")
IO.puts("This demonstration shows how the signature placement feature")
IO.puts("integrates with the existing PDF analysis functionality.")
IO.puts("")
IO.puts("To use this feature:")
IO.puts("1. Build the Rust NIF: cd native/pdf_analyzer && cargo build --release")
IO.puts("2. Compile Elixir: mix compile")
IO.puts("3. Use the WraftDoc.PdfAnalyzer module functions")
IO.puts("")
IO.puts("See SIGNATURE_PLACEMENT_README.md for detailed documentation.")
