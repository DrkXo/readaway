use std::path::Path;
use rbook::{Ebook, Epub};
use crate::api::models::{RustDocumentMetadata, RustTocItem};

pub struct EpubReader {
    epub: Epub,
    spine_hrefs: Vec<String>,
}

impl EpubReader {
    pub fn open<P: AsRef<Path>>(path: P) -> Result<Self, String> {
        let path_ref = path.as_ref();
        log::info!("Opening EPUB document at {:?}", path_ref);
        let epub = Epub::new(path_ref).map_err(|e| {
            log::error!("Failed to open EPUB {:?}: {}", path_ref, e);
            format!("Failed to open EPUB: {}", e)
        })?;

        // Extract ordered spine hrefs
        let mut spine_hrefs = Vec::new();
        for item in epub.spine().elements() {
            let idref = item.name();
            if let Some(manifest_item) = epub.manifest().by_id(idref) {
                spine_hrefs.push(manifest_item.value().to_string());
            }
        }
        log::debug!("Extracted {} spine items from EPUB", spine_hrefs.len());

        Ok(Self { epub, spine_hrefs })
    }

    pub fn metadata(&self) -> RustDocumentMetadata {
        let meta = self.epub.metadata();
        let cover_path = self.epub.cover_image().map(|c| c.value().to_string());

        RustDocumentMetadata {
            title: meta.title().map(|t| t.value().to_string()),
            author: meta.creators().first().map(|c| c.value().to_string()),
            language: meta.language().map(|l| l.value().to_string()),
            identifier: meta.elements().iter().find(|e| e.name().contains("identifier")).map(|i| i.value().to_string()),
            publisher: meta.publisher().first().map(|p| p.value().to_string()),
            description: meta.description().map(|d| d.value().to_string()),
            cover_image_path: cover_path,
        }
    }

    pub fn section_count(&self) -> usize {
        self.spine_hrefs.len()
    }

    pub fn spine_hrefs(&self) -> &[String] {
        &self.spine_hrefs
    }

    pub fn read_section_html(&self, index: usize) -> Result<String, String> {
        if index >= self.spine_hrefs.len() {
            log::warn!("Section index {} out of bounds (total {})", index, self.spine_hrefs.len());
            return Err(format!("Section index {} out of bounds (total {})", index, self.spine_hrefs.len()));
        }

        let reader = self.epub.reader();
        match reader.fetch_page(index) {
            Some(Ok(content)) => Ok(content.as_lossy_str().to_string()),
            Some(Err(e)) => {
                log::error!("Error reading EPUB page {}: {}", index, e);
                Err(format!("Error fetching page {}: {}", index, e))
            }
            None => Err(format!("Page {} not found", index)),
        }
    }

    pub fn read_resource_bytes(&self, path: &str) -> Result<Vec<u8>, String> {
        self.epub.read_bytes_file(path).map_err(|e| {
            log::error!("Failed to read EPUB resource '{}': {}", path, e);
            format!("Failed to read resource '{}': {}", path, e)
        })
    }

    pub fn read_resource_str(&self, path: &str) -> Result<String, String> {
        self.epub.read_file(path).map_err(|e| {
            log::error!("Failed to read EPUB resource string '{}': {}", path, e);
            format!("Failed to read string resource '{}': {}", path, e)
        })
    }

    /// Resolves an href (possibly with anchor or path differences) to a 0-based chapter/section index.
    pub fn resolve_section_index(&self, href: &str) -> Option<usize> {
        let clean_href = href.split('#').next().unwrap_or(href);
        let normalized = clean_href.trim_start_matches('/');

        // 1. Exact match
        if let Some(idx) = self.spine_hrefs.iter().position(|s| s == normalized || s == clean_href) {
            return Some(idx);
        }

        // 2. Basename match (e.g. "chapter_001.xhtml" inside "OEBPS/chapter_001.xhtml")
        let filename = Path::new(normalized).file_name()?.to_str()?;
        self.spine_hrefs.iter().position(|s| {
            Path::new(s).file_name().and_then(|f| f.to_str()) == Some(filename)
        })
    }

    /// Returns the hierarchical Table of Contents (TOC).
    pub fn toc(&self) -> Vec<RustTocItem> {
        let toc_elements = self.epub.toc().elements();
        toc_elements
            .iter()
            .map(|el| self.parse_toc_element(el, 0))
            .collect()
    }

    fn parse_toc_element(&self, element: &rbook::xml::Element, level: usize) -> RustTocItem {
        let title = element.name().trim().to_string();
        let href = element.value().trim().to_string();
        let chapter_index = self.resolve_section_index(&href).map(|i| i as i32);

        let children = element
            .children()
            .iter()
            .map(|child| self.parse_toc_element(child, level + 1))
            .collect();

        RustTocItem {
            title,
            href,
            level,
            chapter_index,
            children,
        }
    }
}
