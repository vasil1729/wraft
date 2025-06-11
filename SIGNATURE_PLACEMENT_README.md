# PDF Signature Placement Feature

This document describes the new PDF signature placement functionality added to the WraftDoc PDF analyzer.

## Overview

The signature placement feature allows you to:

1. **Analyze PDFs** to detect coordinates using the existing typst engine
2. **Place signature images** at specific coordinates in PDF documents
3. **Automatically detect** signature placement locations based on colored rectangles
4. **Transform coordinates** properly between different coordinate systems

## Files Added/Modified

### Rust NIF (Native Implementation)

1. **`native/pdf_analyzer/src/signature.rs`** - New module for signature placement
   - `place_signature_at_coordinates()` - Main function for placing signatures
   - `load_and_encode_image()` - Image processing and resizing
   - `add_signature_to_page()` - PDF manipulation for adding images
   - Coordinate transformation logic

2. **`native/pdf_analyzer/src/lib.rs`** - Updated to include signature module
   - Added `place_signature_nif()` NIF function
   - Updated rustler init to export new function

3. **`native/pdf_analyzer/Cargo.toml`** - Added dependencies
   - `image = "0.24"` - For image processing
   - `base64 = "0.21"` - For image encoding

### Elixir Wrapper

4. **`lib/wraft_doc/pdf_analyzer.ex`** - New Elixir module
   - `analyze_pdf()` - Wrapper for existing PDF analysis
   - `place_signature()` - Wrapper for signature placement
   - `detect_signature_coordinates()` - Helper to extract coordinates
   - `place_signature_parsed()` - Returns parsed JSON results

### Test Files

5. **`test_signature_placement.exs`** - Comprehensive test script
6. **`build_and_test.sh`** - Build and test automation script

## API Reference

### Rust Functions

```rust
pub fn place_signature_at_coordinates(
    pdf_path: &str,              // Path to input PDF
    signature_path: &str,        // Path to signature image
    x: f64,                      // X coordinate (PDF points)
    y: f64,                      // Y coordinate (PDF points, top-left origin)
    page_number: u32,            // Page number (1-based)
    output_path: Option<&str>,   // Optional output path
    signature_width: Option<f64>, // Optional signature width
    signature_height: Option<f64>, // Optional signature height
) -> Result<SignaturePlacementResult, String>
```

### Elixir Functions

```elixir
# Analyze PDF and detect coordinates
WraftDoc.PdfAnalyzer.detect_signature_coordinates(pdf_path)
# Returns: {:ok, [%{x: float, y: float, page: int, width: float, height: float}]}

# Place signature at coordinates
WraftDoc.PdfAnalyzer.place_signature(
  pdf_path, signature_path, x, y, page_number, 
  output_path \\ nil, signature_width \\ nil, signature_height \\ nil
)
# Returns: {:ok, json_string} | {:error, reason}

# Place signature with parsed results
WraftDoc.PdfAnalyzer.place_signature_parsed(...)
# Returns: {:ok, %{success: boolean, message: string, output_path: string}}
```

## Usage Examples

### Basic Usage

```elixir
# 1. Detect coordinates in PDF
{:ok, coordinates} = WraftDoc.PdfAnalyzer.detect_signature_coordinates("/path/to/document.pdf")

# 2. Use first detected coordinate
coord = List.first(coordinates)

# 3. Place signature
{:ok, result} = WraftDoc.PdfAnalyzer.place_signature_parsed(
  "/path/to/document.pdf",
  "/path/to/signature.png",
  coord.x,
  coord.y,
  coord.page,
  "/path/to/output.pdf",
  80.0,  # width
  40.0   # height
)

IO.puts("Signature placed: #{result.message}")
IO.puts("Output file: #{result.output_path}")
```

### Manual Coordinate Placement

```elixir
# Place signature at specific coordinates
{:ok, result} = WraftDoc.PdfAnalyzer.place_signature_parsed(
  "/path/to/document.pdf",
  "/path/to/signature.png",
  100.0,  # x coordinate
  200.0,  # y coordinate
  1,      # page number
  nil,    # auto-generate output path
  80.0,   # signature width
  40.0    # signature height
)
```

## Coordinate System

The system uses **top-left origin** coordinates for input (consistent with most UI systems), but internally transforms them to PDF's **bottom-left origin** system.

- **Input coordinates**: (0,0) is top-left of page
- **PDF coordinates**: (0,0) is bottom-left of page
- **Transformation**: `pdf_y = page_height - input_y - signature_height`

## File Paths for Testing

As specified in the requirements:

- **Test PDF**: `/home/ultimatum/workspace/wraft/organisations/653736e2-7c8f-4b57-bcad-ef3ed1056cc9/contents/VARZ0006/VARZ0006-v2.pdf`
- **Signature Image**: `/home/ultimatum/workspace/helpers/append_certificate/signature.png`

## Building and Testing

1. **Build the Rust NIF**:
   ```bash
   cd native/pdf_analyzer
   cargo build --release
   ```

2. **Compile Elixir project**:
   ```bash
   mix deps.get
   mix compile
   ```

3. **Run tests**:
   ```bash
   elixir test_signature_placement.exs
   ```

   Or use the automated script:
   ```bash
   chmod +x build_and_test.sh
   ./build_and_test.sh
   ```

## Features

### Automatic Coordinate Detection
- Uses existing typst engine to detect colored rectangles
- Filters rectangles by target colors (RGB(214, 255, 244) fill, RGB(0, 184, 148) stroke)
- Returns coordinates suitable for signature placement

### Image Processing
- Supports multiple image formats (PNG, JPEG, etc.)
- Automatic resizing with aspect ratio preservation
- Converts images to PNG format for PDF embedding

### PDF Manipulation
- Adds images as XObjects to PDF structure
- Properly updates PDF Resources dictionary
- Appends content streams without overwriting existing content
- Maintains PDF structure integrity

### Error Handling
- Comprehensive error messages
- File existence validation
- Page number validation
- Coordinate bounds checking

## Integration with Existing Code

The signature placement functionality integrates seamlessly with the existing PDF analysis code:

1. **Uses same coordinate system** as the typst engine analysis
2. **Leverages existing** PDF parsing and page detection
3. **Maintains compatibility** with current NIF structure
4. **Extends functionality** without breaking existing features

## Future Enhancements

Potential improvements for future versions:

1. **Multiple signatures** on single page
2. **Signature templates** with predefined sizes
3. **Digital signature** integration (cryptographic signatures)
4. **Batch processing** for multiple PDFs
5. **Signature positioning** relative to detected text or elements
6. **Custom coordinate systems** and transformations
