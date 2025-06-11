use lopdf::{Document, Object, Stream, Dictionary};
use std::path::Path;
use image::ImageFormat;

#[derive(Debug)]
pub struct SignaturePlacementResult {
    pub success: bool,
    pub message: String,
    pub output_path: Option<String>,
}

impl serde::Serialize for SignaturePlacementResult {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        use serde::ser::SerializeStruct;
        let mut state = serializer.serialize_struct("SignaturePlacementResult", 3)?;
        state.serialize_field("success", &self.success)?;
        state.serialize_field("message", &self.message)?;
        state.serialize_field("output_path", &self.output_path)?;
        state.end()
    }
}

pub fn place_signature_at_coordinates(
    pdf_path: &str,
    signature_path: &str,
    x: f64,
    y: f64,
    page_number: u32,
    output_path: Option<&str>,
    signature_width: Option<f64>,
    signature_height: Option<f64>,
) -> Result<SignaturePlacementResult, String> {
    // Load the PDF document
    let mut doc = Document::load(pdf_path).map_err(|e| format!("Failed to load PDF: {}", e))?;
    
    // Load and process the signature image
    let signature_data = load_and_encode_image(signature_path, signature_width, signature_height)?;
    
    // Get the page to modify
    let pages = doc.get_pages();
    let page_ids: Vec<_> = pages.into_iter().collect();

    if page_number == 0 || page_number as usize > page_ids.len() {
        return Err(format!("Invalid page number: {}. PDF has {} pages.", page_number, page_ids.len()));
    }

    let (_, page_id) = page_ids[(page_number - 1) as usize];
    
    // Get page height for coordinate transformation
    let page_height = get_page_height(&doc, page_id).unwrap_or(792.0);

    // Transform coordinates to PDF coordinate system (bottom-left origin)
    // The input y is from top-left, PDF uses bottom-left
    let pdf_y = page_height - y - signature_data.height;

    println!("Coordinate transformation:");
    println!("  Page height: {}", page_height);
    println!("  Input coordinates: ({}, {})", x, y);
    println!("  PDF coordinates: ({}, {})", x, pdf_y);
    println!("  Signature size: {}x{}", signature_data.width, signature_data.height);
    
    // Add the signature image to the PDF
    // Pass the target dimensions for proper scaling
    let target_width = signature_width.unwrap_or(signature_data.width);
    let target_height = signature_height.unwrap_or(signature_data.height);
    add_signature_to_page(&mut doc, page_id, &signature_data, x, pdf_y, target_width, target_height)?;
    
    // Determine output path
    let final_output_path = match output_path {
        Some(path) => path.to_string(),
        None => {
            let input_path = Path::new(pdf_path);
            let stem = input_path.file_stem().unwrap().to_str().unwrap();
            let extension = input_path.extension().unwrap().to_str().unwrap();
            let parent = input_path.parent().unwrap();
            parent.join(format!("{}_signed.{}", stem, extension)).to_str().unwrap().to_string()
        }
    };
    
    // Save the modified PDF
    doc.save(&final_output_path).map_err(|e| format!("Failed to save PDF: {}", e))?;
    
    Ok(SignaturePlacementResult {
        success: true,
        message: format!("Signature placed successfully at coordinates ({}, {}) on page {}", x, y, page_number),
        output_path: Some(final_output_path),
    })
}

struct SignatureImageData {
    data: Vec<u8>,
    width: f64,
    height: f64,
    format: String,
}

fn load_and_encode_image(
    image_path: &str,
    target_width: Option<f64>,
    target_height: Option<f64>,
) -> Result<SignatureImageData, String> {
    // Load the image
    let img = image::open(image_path).map_err(|e| format!("Failed to load image: {}", e))?;

    // Resize if dimensions are specified
    let processed_img = match (target_width, target_height) {
        (Some(w), Some(h)) => img.resize_exact(w as u32, h as u32, image::imageops::FilterType::Lanczos3),
        (Some(w), None) => {
            let aspect_ratio = img.height() as f64 / img.width() as f64;
            let h = (w * aspect_ratio) as u32;
            img.resize_exact(w as u32, h, image::imageops::FilterType::Lanczos3)
        },
        (None, Some(h)) => {
            let aspect_ratio = img.width() as f64 / img.height() as f64;
            let w = (h * aspect_ratio) as u32;
            img.resize_exact(w, h as u32, image::imageops::FilterType::Lanczos3)
        },
        (None, None) => img,
    };

    // Convert to RGB format and get raw pixel data for PDF
    let rgb_img = processed_img.to_rgb8();
    let raw_data = rgb_img.as_raw().clone();

    // Compress the raw RGB data using flate2
    use flate2::Compression;
    use flate2::write::ZlibEncoder;
    use std::io::Write;

    let mut encoder = ZlibEncoder::new(Vec::new(), Compression::default());
    encoder.write_all(&raw_data).map_err(|e| format!("Failed to compress image data: {}", e))?;
    let compressed_data = encoder.finish().map_err(|e| format!("Failed to finish compression: {}", e))?;

    Ok(SignatureImageData {
        data: compressed_data,
        width: processed_img.width() as f64,
        height: processed_img.height() as f64,
        format: "RGB".to_string(),
    })
}

fn get_page_height(doc: &Document, page_id: lopdf::ObjectId) -> Option<f64> {
    if let Ok(Object::Dictionary(page_dict)) = doc.get_object(page_id) {
        if let Ok(media_box) = page_dict.get(b"MediaBox") {
            if let Object::Array(coords) = media_box {
                if coords.len() >= 4 {
                    let y1 = match &coords[1] {
                        Object::Real(n) => *n as f64,
                        Object::Integer(n) => *n as f64,
                        _ => return None,
                    };
                    let y2 = match &coords[3] {
                        Object::Real(n) => *n as f64,
                        Object::Integer(n) => *n as f64,
                        _ => return None,
                    };
                    return Some(y2 - y1);
                }
            }
        }
    }
    None
}

fn add_signature_to_page(
    doc: &mut Document,
    page_id: lopdf::ObjectId,
    signature_data: &SignatureImageData,
    x: f64,
    y: f64,
    target_width: f64,
    target_height: f64,
) -> Result<(), String> {
    // Create image object with proper RGB handling
    let image_id = doc.new_object_id();
    let mut image_dict = Dictionary::new();
    image_dict.set("Type", Object::Name(b"XObject".to_vec()));
    image_dict.set("Subtype", Object::Name(b"Image".to_vec()));
    image_dict.set("Width", Object::Integer(signature_data.width as i64));
    image_dict.set("Height", Object::Integer(signature_data.height as i64));
    image_dict.set("ColorSpace", Object::Name(b"DeviceRGB".to_vec()));
    image_dict.set("BitsPerComponent", Object::Integer(8));
    image_dict.set("Filter", Object::Name(b"FlateDecode".to_vec()));
    image_dict.set("Length", Object::Integer(signature_data.data.len() as i64));

    let image_stream = Stream::new(image_dict, signature_data.data.clone());
    doc.objects.insert(image_id, Object::Stream(image_stream));
    
    // Get the page object and add the image
    if let Ok(Object::Dictionary(mut page_dict)) = doc.get_object(page_id).cloned() {
        // Create or update Resources dictionary
        let resources_id = if let Ok(Object::Reference(res_id)) = page_dict.get(b"Resources") {
            *res_id
        } else {
            let new_resources_id = doc.new_object_id();
            page_dict.set("Resources", Object::Reference(new_resources_id));
            doc.objects.insert(page_id, Object::Dictionary(page_dict.clone()));
            new_resources_id
        };
        
        // Update or create Resources dictionary
        let mut resources_dict = if let Ok(Object::Dictionary(dict)) = doc.get_object(resources_id).cloned() {
            dict
        } else {
            Dictionary::new()
        };
        
        // Add XObject to resources
        let mut xobject_dict = if let Ok(Object::Dictionary(dict)) = resources_dict.get(b"XObject") {
            dict.clone()
        } else {
            Dictionary::new()
        };
        
        xobject_dict.set("Sig1", Object::Reference(image_id));
        resources_dict.set("XObject", Object::Dictionary(xobject_dict));
        doc.objects.insert(resources_id, Object::Dictionary(resources_dict));
        
        // Create content stream to place the image with target dimensions
        // Use positive width and negative height (only vertical flip)
        let content_stream = format!(
            "q {} 0 0 {} {} {} cm /Sig1 Do Q",
            target_width, -target_height, x, y + target_height
        );

        println!("Content stream (vertical flip only): {}", content_stream);
        println!("Target dimensions: {}x{}", target_width, target_height);
        println!("Original image dimensions: {}x{}", signature_data.width, signature_data.height);
        println!("Position: ({}, {})", x, y + target_height);
        
        // Add content stream to page
        add_content_to_page(doc, page_id, &content_stream)?;
    }
    
    Ok(())
}

fn add_content_to_page(doc: &mut Document, page_id: lopdf::ObjectId, content: &str) -> Result<(), String> {
    let content_stream_id = doc.new_object_id();
    let mut content_dict = Dictionary::new();
    content_dict.set("Length", Object::Integer(content.len() as i64));
    
    let stream = Stream::new(content_dict, content.as_bytes().to_vec());
    doc.objects.insert(content_stream_id, Object::Stream(stream));
    
    // Update page to reference the new content stream
    if let Ok(Object::Dictionary(mut page_dict)) = doc.get_object(page_id).cloned() {
        let new_contents = if let Ok(existing_contents) = page_dict.get(b"Contents") {
            match existing_contents {
                Object::Reference(ref_id) => {
                    Object::Array(vec![Object::Reference(*ref_id), Object::Reference(content_stream_id)])
                },
                Object::Array(arr) => {
                    let mut new_arr = arr.clone();
                    new_arr.push(Object::Reference(content_stream_id));
                    Object::Array(new_arr)
                },
                _ => Object::Reference(content_stream_id),
            }
        } else {
            Object::Reference(content_stream_id)
        };
        
        page_dict.set("Contents", new_contents);
        doc.objects.insert(page_id, Object::Dictionary(page_dict));
    }
    
    Ok(())
}
