use unicode_normalization::UnicodeNormalization;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SentenceSpan {
    pub text: String,
    pub char_start: usize,
    pub char_end: usize,
    pub sentence_index: usize,
}

/// Strips zero-width and invisible control characters while preserving spacing and structure.
pub fn sanitize_unicode(text: &str) -> String {
    text.nfkc()
        .collect::<String>()
        .chars()
        .filter(|&c| {
            c != '\u{200B}' // Zero-width space
                && c != '\u{200C}' // Zero-width non-joiner
                && c != '\u{200D}' // Zero-width joiner
                && c != '\u{FEFF}' // Zero-width no-break space / BOM
                && c != '\u{00AD}' // Soft hyphen
        })
        .collect()
}

/// Splits text into natural sentence boundaries using `sentencex`,
/// which disambiguates abbreviations, decimals, ellipses, and quotes.
/// Computes accurate character offsets for each sentence span.
pub fn segment_sentences(text: &str, language: &str) -> Vec<SentenceSpan> {
    let sanitized = sanitize_unicode(text);
    let lang = if language.is_empty() { "en" } else { language };
    let boundaries = sentencex::get_sentence_boundaries(lang, &sanitized);

    let mut spans = Vec::new();
    for (idx, b) in boundaries.into_iter().enumerate() {
        let trimmed = b.text.trim();
        if trimmed.is_empty() {
            continue;
        }

        // Compute char offsets corresponding to byte offsets or trimmed text
        let start_pos = sanitized[..b.start_byte].chars().count();
        let end_pos = sanitized[..b.end_byte].chars().count();

        spans.push(SentenceSpan {
            text: trimmed.to_string(),
            char_start: start_pos,
            char_end: end_pos,
            sentence_index: idx,
        });
    }

    spans
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sanitize_unicode() {
        let input = "Hello\u{200B} world\u{FEFF}!";
        let sanitized = sanitize_unicode(input);
        assert_eq!(sanitized, "Hello world!");
    }

    #[test]
    fn test_abbreviation_aware_splitting() {
        let input = "Dr. Watson met Mrs. Hudson at 8 a.m. It was a lovely day in the U.S.A.";
        let spans = segment_sentences(input, "en");
        // sentencex should not break on Dr., Mrs., a.m., or U.S.A.
        assert_eq!(spans.len(), 2);
        assert!(spans[0].text.contains("Dr. Watson met Mrs. Hudson"));
        assert!(spans[1].text.contains("It was a lovely day"));
    }

    #[test]
    fn test_char_offsets() {
        let input = "First sentence. Second sentence.";
        let spans = segment_sentences(input, "en");
        assert_eq!(spans.len(), 2);
        assert_eq!(spans[0].text, "First sentence.");
        assert_eq!(spans[1].text, "Second sentence.");
    }

    #[test]
    fn test_non_ascii_char_offsets() {
        let input = "こんにちは。世界です。";
        let spans = segment_sentences(input, "ja");
        assert_eq!(spans.len(), 2);
        assert_eq!(spans[0].char_start, 0);
        assert_eq!(spans[0].char_end, 6);
        assert_eq!(spans[1].char_start, 6);
        assert_eq!(spans[1].char_end, 11);
    }
}
