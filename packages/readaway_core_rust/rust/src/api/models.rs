#[derive(Debug, Clone)]
pub struct RustTtsChunk {
    pub id: String,
    pub section_index: i32,
    pub sentence_index: i32,
    pub display_text: String,
    pub spoken_text: String,
    pub start_offset: usize,
    pub end_offset: usize,
    pub estimated_duration_ms: u32,
}

#[derive(Debug, Clone)]
pub struct RustFootnote {
    pub id: String,
    pub content_html: String,
    pub footnote_type: String,
}

#[derive(Debug, Clone)]
pub struct RustExtractedContent {
    pub display_text: String,
    pub speech_text: String,
    pub footnotes: Vec<RustFootnote>,
}

#[flutter_rust_bridge::frb(dart_metadata=("freezed"))]
#[derive(Debug, Clone)]
pub struct RustDocumentMetadata {
    pub title: Option<String>,
    pub author: Option<String>,
    pub language: Option<String>,
    pub identifier: Option<String>,
    pub publisher: Option<String>,
    pub description: Option<String>,
    pub cover_image_path: Option<String>,
}

#[derive(Debug, Clone)]
pub struct RustTocItem {
    pub title: String,
    pub href: String,
    pub level: usize,
    pub chapter_index: Option<i32>,
    pub children: Vec<RustTocItem>,
}
