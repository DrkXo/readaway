use crate::api::models::{RustDocumentMetadata, RustTocItem};
use crate::document::cbz::CbzReader;
use crate::document::epub::EpubReader;

/// Opens an EPUB document and reads its metadata.
pub fn get_epub_metadata(path: String) -> Result<RustDocumentMetadata, String> {
    let reader = EpubReader::open(&path)?;
    Ok(reader.metadata())
}

/// Returns the total number of sections (spine items) in the EPUB.
pub fn get_epub_section_count(path: String) -> Result<usize, String> {
    let reader = EpubReader::open(&path)?;
    Ok(reader.section_count())
}

/// Returns the ordered list of spine item hrefs in the EPUB.
pub fn get_epub_spine_hrefs(path: String) -> Result<Vec<String>, String> {
    let reader = EpubReader::open(&path)?;
    Ok(reader.spine_hrefs().to_vec())
}

/// Reads the HTML content of a specific section from the EPUB (async).
pub fn read_epub_section(path: String, section_index: usize) -> Result<String, String> {
    read_epub_section_sync(path, section_index)
}

/// Reads the HTML content of a specific section from the EPUB synchronously.
#[flutter_rust_bridge::frb(sync)]
pub fn read_epub_section_sync(path: String, section_index: usize) -> Result<String, String> {
    let reader = EpubReader::open(&path)?;
    reader.read_section_html(section_index)
}

/// Reads an arbitrary resource (e.g. image, stylesheet) from the EPUB archive (async).
pub fn read_epub_resource(path: String, resource_path: String) -> Result<Vec<u8>, String> {
    read_epub_resource_sync(path, resource_path)
}

/// Reads an arbitrary resource from the EPUB archive synchronously.
#[flutter_rust_bridge::frb(sync)]
pub fn read_epub_resource_sync(path: String, resource_path: String) -> Result<Vec<u8>, String> {
    let reader = EpubReader::open(&path)?;
    reader.read_resource_bytes(&resource_path)
}

/// Returns the hierarchical Table of Contents (TOC) of the EPUB.
pub fn get_epub_toc(path: String) -> Result<Vec<RustTocItem>, String> {
    let reader = EpubReader::open(&path)?;
    Ok(reader.toc())
}

/// Resolves an internal link target [href] to a section index, if found.
pub fn resolve_epub_spine_href(path: String, href: String) -> Result<Option<i32>, String> {
    let reader = EpubReader::open(&path)?;
    Ok(reader.resolve_section_index(&href).map(|i| i as i32))
}

/// Opens a CBZ comic and returns the total page count.
pub fn get_cbz_page_count(path: String) -> Result<usize, String> {
    let reader = CbzReader::open(&path)?;
    Ok(reader.page_count())
}

/// Returns all image page entry paths in the CBZ archive.
#[flutter_rust_bridge::frb(sync)]
pub fn get_cbz_page_paths(path: String) -> Result<Vec<String>, String> {
    let reader = CbzReader::open(&path)?;
    Ok(reader.page_paths().to_vec())
}

/// Reads a specific page image bytes from the CBZ archive (async).
pub fn read_cbz_page_image(path: String, page_index: usize) -> Result<Vec<u8>, String> {
    read_cbz_page_image_sync(path, page_index)
}

/// Reads a specific page image bytes from the CBZ archive synchronously.
#[flutter_rust_bridge::frb(sync)]
pub fn read_cbz_page_image_sync(path: String, page_index: usize) -> Result<Vec<u8>, String> {
    let reader = CbzReader::open(&path)?;
    reader.read_page_image(page_index)
}

/// Reads an arbitrary asset from the CBZ archive synchronously.
#[flutter_rust_bridge::frb(sync)]
pub fn read_cbz_asset_sync(path: String, asset_path: String) -> Result<Vec<u8>, String> {
    let reader = CbzReader::open(&path)?;
    reader.read_asset(&asset_path)
}
