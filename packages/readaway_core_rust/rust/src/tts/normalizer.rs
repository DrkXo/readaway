use num2words::{Currency, Num2Words};
use once_cell::sync::Lazy;
use regex::{Captures, Regex};

static CURRENCY_RE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"(\$|£|€)(\d+(?:\.\d{1,2})?)").unwrap()
});

static ORDINAL_RE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"\b(\d+)(?:st|nd|rd|th)\b").unwrap()
});

static PERCENT_RE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"\b(\d+(?:\.\d+)?)\s*%").unwrap()
});

static STANDALONE_NUMBER_RE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"\b(\d{1,9})\b").unwrap()
});

static ABBREVIATIONS: &[(&str, &str)] = &[
    (r"\bDr\.(?:\s|$)", "Doctor "),
    (r"\bMr\.(?:\s|$)", "Mister "),
    (r"\bMrs\.(?:\s|$)", "Missus "),
    (r"\bMs\.(?:\s|$)", "Miz "),
    (r"\bProf\.(?:\s|$)", "Professor "),
    (r"\bSt\.(?:\s|$)", "Saint "),
    (r"\bvs\.(?:\s|$)", "versus "),
    (r"\betc\.(?:\s|$)", "et cetera "),
    (r"\be\.g\.(?:\s|$)", "for example "),
    (r"\bi\.e\.(?:\s|$)", "that is "),
    (r"\s*&\s*", " and "),
];

/// Expands numbers, currencies, ordinals, and percentages into spoken English words.
pub fn expand_numbers_and_currency(text: &str) -> String {
    // 1. Currency ($42.50 -> forty-two dollars and fifty cents)
    let text = CURRENCY_RE.replace_all(text, |caps: &Captures| {
        let sym = &caps[1];
        let num_str = &caps[2];
        if let Ok(num) = num_str.parse::<f64>() {
            let curr = match sym {
                "$" => Currency::DOLLAR,
                "£" => Currency::GBP,
                "€" => Currency::EUR,
                _ => Currency::DOLLAR,
            };
            Num2Words::new(num).currency(curr).to_words().unwrap_or_else(|_| caps[0].to_string())
        } else {
            caps[0].to_string()
        }
    });

    // 2. Percentages (50% -> fifty percent)
    let text = PERCENT_RE.replace_all(&text, |caps: &Captures| {
        let num_str = &caps[1];
        if let Ok(num) = num_str.parse::<i64>() {
            if let Ok(words) = Num2Words::new(num).to_words() {
                return format!("{} percent", words);
            }
        }
        caps[0].to_string()
    });

    // 3. Ordinals (1st -> first, 2nd -> second)
    let text = ORDINAL_RE.replace_all(&text, |caps: &Captures| {
        let num_str = &caps[1];
        if let Ok(num) = num_str.parse::<i64>() {
            Num2Words::new(num).ordinal().to_words().unwrap_or_else(|_| caps[0].to_string())
        } else {
            caps[0].to_string()
        }
    });

    // 4. Standalone integers (up to 9 digits to avoid phone numbers / ISBNs)
    let text = STANDALONE_NUMBER_RE.replace_all(&text, |caps: &Captures| {
        let num_str = &caps[1];
        if let Ok(num) = num_str.parse::<i64>() {
            Num2Words::new(num).to_words().unwrap_or_else(|_| caps[0].to_string())
        } else {
            caps[0].to_string()
        }
    });

    text.to_string()
}

/// Expands common abbreviations into full spoken forms.
pub fn expand_abbreviations(text: &str) -> String {
    let mut result = text.to_string();
    for (pattern, replacement) in ABBREVIATIONS {
        let re = Regex::new(pattern).unwrap();
        result = re.replace_all(&result, *replacement).to_string();
    }
    result
}

/// Returns true if Latin characters (ASCII or Latin Extended) make up majority of alphabetic characters.
fn is_latin_dominant(text: &str) -> bool {
    let alpha_chars: Vec<char> = text.chars().filter(|c| c.is_alphabetic()).collect();
    if alpha_chars.is_empty() {
        return true;
    }
    let latin_count = alpha_chars
        .iter()
        .filter(|&&c| c.is_ascii_alphabetic() || ('\u{00C0}'..='\u{024F}').contains(&c))
        .count();
    (latin_count as f64 / alpha_chars.len() as f64) > 0.5
}

/// Normalizes text for speech by running Unicode sanitization,
/// abbreviation expansion, and number spell-out.
pub fn normalize_for_speech(text: &str) -> String {
    let unescaped = expand_abbreviations(text);
    let expanded = expand_numbers_and_currency(&unescaped);
    // Transliterate accented or non-ASCII characters only when Latin-dominant
    let transformed = if is_latin_dominant(&expanded) {
        deunicode::deunicode(&expanded)
    } else {
        expanded
    };
    // Collapse excess whitespace
    transformed.split_whitespace().collect::<Vec<_>>().join(" ")
}

/// Estimates spoken audio duration in milliseconds based on word count.
/// Defaults to ~160 words per minute (standard English audiobook pace).
pub fn estimate_duration_ms(text: &str, words_per_minute: Option<f32>) -> u32 {
    let wpm = words_per_minute.unwrap_or(160.0);
    let word_count = text.split_whitespace().count().max(1);
    ((word_count as f32 / wpm) * 60.0 * 1000.0) as u32
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_currency_expansion() {
        let input = "I paid $42.50 for lunch.";
        let expanded = expand_numbers_and_currency(input);
        assert!(expanded.contains("forty-two dollars and fifty cents"));
    }

    #[test]
    fn test_ordinal_expansion() {
        let input = "He finished in 1st place on his 21st birthday.";
        let expanded = expand_numbers_and_currency(input);
        assert!(expanded.contains("first"));
        assert!(expanded.contains("twenty-first"));
    }

    #[test]
    fn test_abbreviation_expansion() {
        let input = "Dr. Watson met Mr. Holmes & visited St. John.";
        let expanded = expand_abbreviations(input);
        assert!(expanded.contains("Doctor Watson"));
        assert!(expanded.contains("Mister Holmes"));
        assert!(expanded.contains(" and visited"));
        assert!(expanded.contains("Saint John"));
    }

    #[test]
    fn test_normalize_for_speech() {
        let input = "Dr. Smith bought 3 apples for $5 on the 2nd day.";
        let normalized = normalize_for_speech(input);
        assert!(normalized.contains("Doctor Smith"));
        assert!(normalized.contains("three apples"));
        assert!(normalized.contains("five dollars"));
        assert!(normalized.contains("second day"));
    }

    #[test]
    fn test_normalize_non_latin_preservation() {
        let input = "こんにちは、世界！";
        let normalized = normalize_for_speech(input);
        assert_eq!(normalized, "こんにちは、世界！");
    }
}
