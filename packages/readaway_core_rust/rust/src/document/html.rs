use once_cell::sync::Lazy;
use regex::Regex;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RustFootnoteItem {
    pub id: String,
    pub content_html: String,
    pub footnote_type: String,
}

static IGNORED_TAGS_RE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"(?is)<script\b[^>]*>.*?</script>|<style\b[^>]*>.*?</style>|<noscript\b[^>]*>.*?</noscript>|<head\b[^>]*>.*?</head>|<svg\b[^>]*>.*?</svg>|<canvas\b[^>]*>.*?</canvas>").unwrap()
});

static FOOTNOTE_ASIDE_RE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#"(?is)<aside\b([^>]*id=["']([^"']+)["'][^>]*)>(.*?)</aside>"#).unwrap()
});

static DUOKAN_FOOTNOTE_RE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#"(?is)<(?:div|p|span)\b([^>]*(?:duokan-footnote|data-wr-footnote|zy-footnote)[^>]*id=["']([^"']+)["'][^>]*)>(.*?)</(?:div|p|span)>"#).unwrap()
});

static CITATION_ANCHOR_RE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"^[\[\(]?[\*\d]+[\)\]]?$").unwrap()
});

static A_TAG_RE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#"(?is)<a\b[^>]*>(.*?)</a>"#).unwrap()
});

static SUP_TAG_RE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#"(?is)<sup\b[^>]*>(.*?)</sup>"#).unwrap()
});

static RUBY_RE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#"(?is)<ruby\b[^>]*>(?:(?P<base>.*?)<rt\b[^>]*>(?P<rt>.*?)</rt>|(?P<only_base>.*?))</ruby>"#).unwrap()
});

static KANA_RE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"[\u3040-\u309f\u30a0-\u30ff]").unwrap()
});

static BLOCK_END_RE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"(?i)</(h[1-6]|p|blockquote|li|dt|dd|pre|div|section|article)>|<br\s*/?>").unwrap()
});

static ALL_TAGS_RE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"<[^>]+>").unwrap()
});

static WHITESPACE_RE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"\s+").unwrap()
});

/// Extracts clean display or spoken text from HTML/XHTML.
///
/// When `for_speech` is true:
/// - Strips footnote content and numeric citation links (`[1]`, `*`).
/// - Swaps Japanese `<ruby>` kanji with `<rt>` kana readings if kana is present.
/// - Converts block boundaries to newlines.
pub fn extract_page_text(html: &str, for_speech: bool) -> String {
    if html.is_empty() {
        return String::new();
    }

    // 1. Remove non-content tags (scripts, styles, svg)
    let cleaned = IGNORED_TAGS_RE.replace_all(html, "");

    // 2. Strip footnote blocks and citation numbers if for speech
    let cleaned = if for_speech {
        let without_asides = FOOTNOTE_ASIDE_RE.replace_all(&cleaned, "");
        let without_duokan = DUOKAN_FOOTNOTE_RE.replace_all(&without_asides, "");
        let without_a = A_TAG_RE.replace_all(&without_duokan, |caps: &regex::Captures| {
            let inner = caps.get(1).map(|m| m.as_str()).unwrap_or("");
            let inner_text = ALL_TAGS_RE.replace_all(inner, "");
            if CITATION_ANCHOR_RE.is_match(inner_text.trim()) {
                "".to_string()
            } else {
                caps.get(0).map(|m| m.as_str()).unwrap_or("").to_string()
            }
        });
        SUP_TAG_RE.replace_all(&without_a, |caps: &regex::Captures| {
            let inner = caps.get(1).map(|m| m.as_str()).unwrap_or("");
            let inner_text = ALL_TAGS_RE.replace_all(inner, "");
            if CITATION_ANCHOR_RE.is_match(inner_text.trim()) {
                "".to_string()
            } else {
                caps.get(0).map(|m| m.as_str()).unwrap_or("").to_string()
            }
        }).to_string()
    } else {
        cleaned.to_string()
    };


    // 3. Handle Ruby typography: voice kana rt over kanji base when for_speech
    let cleaned = if for_speech {
        RUBY_RE.replace_all(&cleaned, |caps: &regex::Captures| {
            if let Some(rt_match) = caps.name("rt") {
                let rt_text = rt_match.as_str().trim();
                if KANA_RE.is_match(rt_text) {
                    return format!(" {} ", rt_text);
                }
            }
            if let Some(base_match) = caps.name("base").or_else(|| caps.name("only_base")) {
                let base = ALL_TAGS_RE.replace_all(base_match.as_str(), "");
                base.to_string()
            } else {
                String::new()
            }
        }).to_string()
    } else {
        cleaned
    };

    // 4. Replace block ending tags with newlines
    let with_newlines = BLOCK_END_RE.replace_all(&cleaned, "\n");

    // 5. Strip all remaining HTML tags
    let stripped = ALL_TAGS_RE.replace_all(&with_newlines, "");

    // 6. Decode common HTML entities
    let decoded = stripped
        .replace("&nbsp;", " ")
        .replace("&amp;", "&")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&quot;", "\"")
        .replace("&#39;", "'")
        .replace("&mdash;", "—")
        .replace("&ndash;", "–");

    // 7. Clean up lines and excessive whitespace
    let mut lines = Vec::new();
    for line in decoded.lines() {
        let trimmed = WHITESPACE_RE.replace_all(line.trim(), " ").trim().to_string();
        if !trimmed.is_empty() {
            lines.push(trimmed);
        }
    }

    lines.join("\n")
}

/// Extracts all structured footnotes from HTML.
pub fn extract_footnotes(html: &str) -> Vec<RustFootnoteItem> {
    let mut results = Vec::new();

    for caps in FOOTNOTE_ASIDE_RE.captures_iter(html) {
        let id = caps.get(2).map(|m| m.as_str()).unwrap_or("").to_string();
        let inner = caps.get(3).map(|m| m.as_str().trim()).unwrap_or("").to_string();
        let attrs = caps.get(1).map(|m| m.as_str()).unwrap_or("");
        let fn_type = if attrs.contains("endnote") { "endnote" } else { "footnote" };

        results.push(RustFootnoteItem {
            id,
            content_html: inner,
            footnote_type: fn_type.to_string(),
        });
    }

    for caps in DUOKAN_FOOTNOTE_RE.captures_iter(html) {
        let id = caps.get(2).map(|m| m.as_str()).unwrap_or("").to_string();
        let inner = caps.get(3).map(|m| m.as_str().trim()).unwrap_or("").to_string();
        if !results.iter().any(|r| r.id == id) {
            results.push(RustFootnoteItem {
                id,
                content_html: inner,
                footnote_type: "footnote".to_string(),
            });
        }
    }

    results
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_extract_page_text_blocks() {
        let html = "<html><body><h1>Title</h1><p>Paragraph 1.</p><p>Paragraph 2.</p></body></html>";
        let text = extract_page_text(html, false);
        assert_eq!(text, "Title\nParagraph 1.\nParagraph 2.");
    }

    #[test]
    fn test_extract_speech_text_filters_footnotes() {
        let html = "<p>Here is text <a href='#fn1'>[1]</a>.</p><aside id='fn1' epub:type='footnote'><p>Footnote note</p></aside>";
        let text = extract_page_text(html, true);
        assert_eq!(text, "Here is text .");
        assert!(!text.contains("Footnote note"));
    }

    #[test]
    fn test_extract_footnotes() {
        let html = "<aside id='note-1' epub:type='footnote'><p>First note</p></aside>";
        let notes = extract_footnotes(html);
        assert_eq!(notes.len(), 1);
        assert_eq!(notes[0].id, "note-1");
        assert_eq!(notes[0].content_html, "<p>First note</p>");
    }

    #[test]
    fn test_ruby_speech_swap() {
        let html = "<p>Read <ruby>漢字<rt>かんじ</rt></ruby> properly.</p>";
        let speech_text = extract_page_text(html, true);
        assert!(speech_text.contains("かんじ"));
        assert!(!speech_text.contains("漢字"));
    }
}
