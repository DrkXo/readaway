use crate::api::models::{RustExtractedContent, RustFootnote, RustTtsChunk};
use crate::document::html;
use crate::tts::{normalizer, segmenter};

/// Preprocesses raw HTML or plain text into normalized TTS chunks for speech synthesis.
/// Performs:
/// 1. HTML tag removal and footnote isolation (if HTML).
/// 2. Unicode NFKC normalization and zero-width character stripping.
/// 3. Sentence boundary segmentation with abbreviation disambiguation (`sentencex`).
/// 4. Spoken text expansion ($42.50 -> forty-two dollars and fifty cents, Dr. -> Doctor).
/// 5. Phonetic transliteration with `deunicode`.
/// 6. Duration estimation and character offset tracking.
const MAX_PARAGRAPH_CHUNK_CHARS: usize = 450;

#[flutter_rust_bridge::frb(sync)]
pub fn preprocess_text_for_tts(
    text: String,
    section_index: i32,
    language: Option<String>,
    is_html: bool,
) -> Vec<RustTtsChunk> {
    let clean_text = if is_html {
        html::extract_page_text(&text, true)
    } else {
        text
    };

    let lang = language.unwrap_or_else(|| "en".to_string());
    
    // Split into paragraph blocks by newlines
    let paragraphs: Vec<&str> = clean_text
        .split('\n')
        .map(|p| p.trim())
        .filter(|p| !p.is_empty())
        .collect();

    if paragraphs.is_empty() {
        return Vec::new();
    }

    let mut chunks = Vec::new();
    let mut global_chunk_idx = 0;
    let mut current_char_offset = 0;

    for (para_idx, para) in paragraphs.iter().enumerate() {
        let para_len = para.chars().count();
        if para_len <= MAX_PARAGRAPH_CHUNK_CHARS {
            // Whole paragraph fits in a single cohesive natural chunk
            let spoken = normalizer::normalize_for_speech(para);
            let duration = normalizer::estimate_duration_ms(&spoken, None);
            let start = current_char_offset;
            let end = current_char_offset + para_len;
            let id = format!("{}:{}:{}", section_index, global_chunk_idx, start);

            chunks.push(RustTtsChunk {
                id,
                section_index,
                sentence_index: global_chunk_idx as i32,
                display_text: para.to_string(),
                spoken_text: spoken,
                start_offset: start,
                end_offset: end,
                estimated_duration_ms: duration,
                is_paragraph_end: true,
                paragraph_index: para_idx as i32,
            });
            global_chunk_idx += 1;
        } else {
            // Paragraph is oversized: split into sentences and group up to MAX_PARAGRAPH_CHUNK_CHARS
            let spans = segmenter::segment_sentences(para, &lang);
            if spans.is_empty() {
                let spoken = normalizer::normalize_for_speech(para);
                let duration = normalizer::estimate_duration_ms(&spoken, None);
                let start = current_char_offset;
                let end = current_char_offset + para_len;
                let id = format!("{}:{}:{}", section_index, global_chunk_idx, start);

                chunks.push(RustTtsChunk {
                    id,
                    section_index,
                    sentence_index: global_chunk_idx as i32,
                    display_text: para.to_string(),
                    spoken_text: spoken,
                    start_offset: start,
                    end_offset: end,
                    estimated_duration_ms: duration,
                    is_paragraph_end: true,
                    paragraph_index: para_idx as i32,
                });
                global_chunk_idx += 1;
            } else {
                let mut sub_spans: Vec<&segmenter::SentenceSpan> = Vec::new();
                let mut current_len = 0;

                for (s_idx, span) in spans.iter().enumerate() {
                    let span_len = span.text.chars().count();
                    if current_len + span_len > MAX_PARAGRAPH_CHUNK_CHARS && !sub_spans.is_empty() {
                        let combined_text = sub_spans
                            .iter()
                            .map(|s| s.text.as_str())
                            .collect::<Vec<_>>()
                            .join(" ");
                        let spoken = normalizer::normalize_for_speech(&combined_text);
                        let duration = normalizer::estimate_duration_ms(&spoken, None);
                        let start = current_char_offset + sub_spans[0].char_start;
                        let end = current_char_offset + sub_spans.last().unwrap().char_end;
                        let id = format!("{}:{}:{}", section_index, global_chunk_idx, start);

                        chunks.push(RustTtsChunk {
                            id,
                            section_index,
                            sentence_index: global_chunk_idx as i32,
                            display_text: combined_text,
                            spoken_text: spoken,
                            start_offset: start,
                            end_offset: end,
                            estimated_duration_ms: duration,
                            is_paragraph_end: false,
                            paragraph_index: para_idx as i32,
                        });
                        global_chunk_idx += 1;
                        sub_spans.clear();
                        current_len = 0;
                    }

                    sub_spans.push(span);
                    current_len += span_len + 1;

                    if s_idx == spans.len() - 1 && !sub_spans.is_empty() {
                        let combined_text = sub_spans
                            .iter()
                            .map(|s| s.text.as_str())
                            .collect::<Vec<_>>()
                            .join(" ");
                        let spoken = normalizer::normalize_for_speech(&combined_text);
                        let duration = normalizer::estimate_duration_ms(&spoken, None);
                        let start = current_char_offset + sub_spans[0].char_start;
                        let end = current_char_offset + sub_spans.last().unwrap().char_end;
                        let id = format!("{}:{}:{}", section_index, global_chunk_idx, start);

                        chunks.push(RustTtsChunk {
                            id,
                            section_index,
                            sentence_index: global_chunk_idx as i32,
                            display_text: combined_text,
                            spoken_text: spoken,
                            start_offset: start,
                            end_offset: end,
                            estimated_duration_ms: duration,
                            is_paragraph_end: true,
                            paragraph_index: para_idx as i32,
                        });
                        global_chunk_idx += 1;
                    }
                }
            }
        }

        current_char_offset += para_len + 1;
    }

    chunks
}

/// Normalizes a single string for speech synthesis (number expansion, abbreviations, ASCII transliteration).
#[flutter_rust_bridge::frb(sync)]
pub fn normalize_single_text_for_speech(text: String) -> String {
    normalizer::normalize_for_speech(&text)
}

/// Extracts clean display text, speech text, and footnotes from HTML.
#[flutter_rust_bridge::frb(sync)]
pub fn extract_html_content(html: String) -> RustExtractedContent {
    let display = html::extract_page_text(&html, false);
    let speech = html::extract_page_text(&html, true);
    let raw_fn = html::extract_footnotes(&html);

    let footnotes = raw_fn
        .into_iter()
        .map(|f| RustFootnote {
            id: f.id,
            content_html: f.content_html,
            footnote_type: f.footnote_type,
        })
        .collect();

    RustExtractedContent {
        display_text: display,
        speech_text: speech,
        footnotes,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_preprocess_text_paragraph_extraction() {
        let text = "Fresh blood flowed from the numerous wounds on the body. Just by standing there for a short while, Fang Yuan had already accumulated a large pool of blood beneath his feet.\n\nEnemies surrounded him all around; there was already no way out.";
        let chunks = preprocess_text_for_tts(text.to_string(), 0, Some("en".to_string()), false);

        assert_eq!(chunks.len(), 2);
        
        // Chunk 0: Para 0 (both sentences preserved as 1 cohesive paragraph chunk)
        assert_eq!(chunks[0].paragraph_index, 0);
        assert_eq!(chunks[0].sentence_index, 0);
        assert!(chunks[0].display_text.contains("Fresh blood flowed"));
        assert!(chunks[0].display_text.contains("Fang Yuan had already accumulated"));
        assert!(chunks[0].is_paragraph_end);

        // Chunk 1: Para 1
        assert_eq!(chunks[1].paragraph_index, 1);
        assert_eq!(chunks[1].sentence_index, 1);
        assert!(chunks[1].display_text.contains("Enemies surrounded him"));
        assert!(chunks[1].is_paragraph_end);
    }
}
