use rustler::{Encoder, Env, NifResult, Term};

// Define modules
mod common;
mod typst;
mod latex;
mod signature;

// Import from modules
use common::{TARGET_FILL_COLOR, TARGET_STROKE_COLOR, DocumentAnalysisResult};

pub fn analyze_pdf(path: &str, engine: Option<&str>) -> Result<DocumentAnalysisResult, String> {
    let engine_type = engine.unwrap_or("typst");

    match engine_type {
        "latex" => latex::analyze_pdf_latex(path, Some(TARGET_FILL_COLOR), Some(TARGET_STROKE_COLOR)),
        _ => typst::analyze_pdf_typst(path, Some(TARGET_FILL_COLOR), Some(TARGET_STROKE_COLOR)),
    }
}

#[rustler::nif(name = "analyze_pdf_nif")]
fn analyze_pdf_nif<'a>(env: Env<'a>, path: &str, _target_fill_color: Option<&str>, _target_stroke_color: Option<&str>, engine: Option<&str>) -> NifResult<Term<'a>> {
    // Ignore the color parameters and use the constants defined at the top of the file
    match analyze_pdf(path, engine) {
        Ok(result) => {
            // Serialize the result to JSON
            let json = serde_json::to_string(&result).map_err(|e| {
                rustler::Error::Term(Box::new(format!("JSON serialization error: {}", e)))
            })?;

            // Create a tuple manually
            let ok_atom = atoms::ok().encode(env);
            let json_string = json.encode(env);

            Ok((ok_atom, json_string).encode(env))
        },
        Err(e) => {
            let error_atom = atoms::error().encode(env);
            let error_string = e.encode(env);
            Ok((error_atom, error_string).encode(env))
        },
    }
}

#[rustler::nif(name = "place_signature_nif")]
fn place_signature_nif<'a>(
    env: Env<'a>,
    pdf_path: &str,
    signature_path: &str,
    x: f64,
    y: f64,
    page_number: u32,
    output_path: Option<&str>,
    signature_width: Option<f64>,
    signature_height: Option<f64>,
) -> NifResult<Term<'a>> {
    match signature::place_signature_at_coordinates(
        pdf_path,
        signature_path,
        x,
        y,
        page_number,
        output_path,
        signature_width,
        signature_height,
    ) {
        Ok(result) => {
            // Serialize the result to JSON
            let json = serde_json::to_string(&result).map_err(|e| {
                rustler::Error::Term(Box::new(format!("JSON serialization error: {}", e)))
            })?;

            // Create a tuple manually
            let ok_atom = atoms::ok().encode(env);
            let json_string = json.encode(env);

            Ok((ok_atom, json_string).encode(env))
        },
        Err(e) => {
            let error_atom = atoms::error().encode(env);
            let error_string = e.encode(env);
            Ok((error_atom, error_string).encode(env))
        },
    }
}

mod atoms {
    rustler::atoms! {
        ok,
        error
    }
}

rustler::init!("Elixir.WraftDoc.PdfAnalyzer", [analyze_pdf_nif, place_signature_nif]);

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_signature_placement() {
        println!("=== Testing Signature Placement from Rust ===");

        let pdf_path = "/home/ultimatum/workspace/wraft/organisations/653736e2-7c8f-4b57-bcad-ef3ed1056cc9/contents/VARZ0006/VARZ0006-v2.pdf";
        let signature_path = "/home/ultimatum/workspace/helpers/append_certificate/signature.png";
        let output_path = Some("/home/ultimatum/workspace/wraft/VARZ0006-v2_SIGNED_BY_RUST.pdf");

        println!("Step 1: Analyzing PDF to detect coordinates using typst engine...");
        println!("  PDF: {}", pdf_path);

        // First, analyze the PDF using the existing typst function
        match typst::analyze_pdf_typst(pdf_path, Some(TARGET_FILL_COLOR), Some(TARGET_STROKE_COLOR)) {
            Ok(analysis_result) => {
                println!("✓ PDF analysis successful!");
                println!("  Total pages: {}", analysis_result.total_pages);
                println!("  Total rectangles found: {}", analysis_result.total_rectangles);

                if analysis_result.rectangles.is_empty() {
                    println!("⚠ No rectangles detected, using manual coordinates...");
                    test_with_manual_coordinates(pdf_path, signature_path, output_path);
                } else {
                    println!("✓ Found {} rectangle(s) for signature placement:", analysis_result.rectangles.len());

                    // Print all detected rectangles
                    for (i, rect) in analysis_result.rectangles.iter().enumerate() {
                        println!("  {}. Page {}: ({}, {}) - {}x{}",
                            i + 1, rect.page, rect.position.x, rect.position.y,
                            rect.dimensions.width, rect.dimensions.height);
                    }

                    // Use the first detected rectangle
                    let first_rect = &analysis_result.rectangles[0];

                    // Use the full dimensions of the detected rectangle
                    let signature_width = Some(first_rect.dimensions.width);
                    let signature_height = Some(first_rect.dimensions.height);

                    println!("\nStep 2: Placing signature at detected coordinates...");
                    println!("  Selected rectangle: Page {} at ({}, {})",
                        first_rect.page, first_rect.position.x, first_rect.position.y);
                    println!("  Signature: {}", signature_path);
                    println!("  Calculated signature size: {}x{}",
                        signature_width.unwrap(), signature_height.unwrap());
                    println!("  Output: {:?}", output_path);

                    match signature::place_signature_at_coordinates(
                        pdf_path,
                        signature_path,
                        first_rect.position.x,
                        first_rect.position.y,
                        first_rect.page,
                        output_path,
                        signature_width,
                        signature_height,
                    ) {
                        Ok(result) => {
                            println!("✓ Signature placement successful!");
                            println!("  Message: {}", result.message);
                            println!("  Output file: {:?}", result.output_path);

                            // Verify the output file was created
                            if let Some(ref path) = result.output_path {
                                match std::fs::metadata(path) {
                                    Ok(metadata) => {
                                        println!("  File size: {} bytes", metadata.len());
                                        println!("✓ Output file verified!");
                                    },
                                    Err(e) => {
                                        println!("✗ Could not verify output file: {}", e);
                                    }
                                }
                            }
                        },
                        Err(e) => {
                            println!("✗ Signature placement failed: {}", e);
                            eprintln!("Signature placement error: {}", e);
                        }
                    }
                }
            },
            Err(e) => {
                println!("✗ PDF analysis failed: {}", e);
                println!("⚠ Falling back to manual coordinates...");
                test_with_manual_coordinates(pdf_path, signature_path, output_path);
            }
        }
    }

    fn test_with_manual_coordinates(pdf_path: &str, signature_path: &str, output_path: Option<&str>) {
        println!("\nStep 2: Testing with manual coordinates...");

        // Use manual coordinates as fallback
        let x = 100.0;
        let y = 200.0;
        let page_number = 1;
        let signature_width = Some(80.0);
        let signature_height = Some(40.0);

        println!("  Position: ({}, {})", x, y);
        println!("  Page: {}", page_number);
        println!("  Signature size: {}x{}", signature_width.unwrap(), signature_height.unwrap());

        match signature::place_signature_at_coordinates(
            pdf_path,
            signature_path,
            x,
            y,
            page_number,
            output_path,
            signature_width,
            signature_height,
        ) {
            Ok(result) => {
                println!("✓ Manual signature placement successful!");
                println!("  Message: {}", result.message);
                println!("  Output: {:?}", result.output_path);
            },
            Err(e) => {
                println!("✗ Manual signature placement failed: {}", e);
                eprintln!("Manual placement error: {}", e);
            }
        }
    }
}
