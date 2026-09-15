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
    let spans = segmenter::segment_sentences(&clean_text, &lang);

    let mut chunks = Vec::with_capacity(spans.len());
    for span in spans {
        let spoken = normalizer::normalize_for_speech(&span.text);
        let duration = normalizer::estimate_duration_ms(&spoken, None);
        let id = format!("{}:{}:{}", section_index, span.sentence_index, span.char_start);

        chunks.push(RustTtsChunk {
            id,
            section_index,
            sentence_index: span.sentence_index as i32,
            display_text: span.text,
            spoken_text: spoken,
            start_offset: span.char_start,
            end_offset: span.char_end,
            estimated_duration_ms: duration,
        });
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
