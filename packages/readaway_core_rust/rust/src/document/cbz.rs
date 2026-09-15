use std::fs::File;
use std::io::Read;
use std::path::Path;
use zip::ZipArchive;

pub struct CbzReader {
    image_entries: Vec<String>,
    file_path: String,
}

impl CbzReader {
    pub fn open<P: AsRef<Path>>(path: P) -> Result<Self, String> {
        let path_str = path.as_ref().to_string_lossy().to_string();
        let file = File::open(&path).map_err(|e| format!("Failed to open CBZ file: {}", e))?;
        let mut archive = ZipArchive::new(file).map_err(|e| format!("Failed to read ZIP archive: {}", e))?;

        let mut entries = Vec::new();
        for i in 0..archive.len() {
            if let Ok(file) = archive.by_index(i) {
                let name = file.name().to_string();
                if is_image_file(&name) {
                    entries.push(name);
                }
            }
        }

        // Natural sort image entries (1.jpg, 2.jpg, 10.jpg)
        entries.sort_by(|a, b| alphanumeric_sort::compare_str(a, b));

        Ok(Self {
            image_entries: entries,
            file_path: path_str,
        })
    }

    pub fn page_count(&self) -> usize {
        self.image_entries.len()
    }

    pub fn page_paths(&self) -> &[String] {
        &self.image_entries
    }

    pub fn read_page_image(&self, index: usize) -> Result<Vec<u8>, String> {
        if index >= self.image_entries.len() {
            return Err(format!("Page index {} out of range (total {})", index, self.image_entries.len()));
        }

        let entry_name = &self.image_entries[index];
        self.read_asset(entry_name)
    }

    pub fn read_asset(&self, entry_name: &str) -> Result<Vec<u8>, String> {
        let file = File::open(&self.file_path).map_err(|e| e.to_string())?;
        let mut archive = ZipArchive::new(file).map_err(|e| e.to_string())?;
        let mut entry = archive.by_name(entry_name).map_err(|e| e.to_string())?;

        let mut buffer = Vec::with_capacity(entry.size() as usize);
        entry.read_to_end(&mut buffer).map_err(|e| e.to_string())?;

        Ok(buffer)
    }
}

fn is_image_file(name: &str) -> bool {
    let lower = name.to_lowercase();
    (lower.ends_with(".jpg")
        || lower.ends_with(".jpeg")
        || lower.ends_with(".png")
        || lower.ends_with(".webp")
        || lower.ends_with(".gif"))
        && !lower.contains("__macosx")
        && !lower.starts_with('.')
}

mod alphanumeric_sort {
    use std::cmp::Ordering;

    pub fn compare_str(a: &str, b: &str) -> Ordering {
        let mut a_chars = a.chars().peekable();
        let mut b_chars = b.chars().peekable();

        loop {
            match (a_chars.peek(), b_chars.peek()) {
                (None, None) => return Ordering::Equal,
                (None, Some(_)) => return Ordering::Less,
                (Some(_), None) => return Ordering::Greater,
                (Some(&ca), Some(&cb)) => {
                    if ca.is_ascii_digit() && cb.is_ascii_digit() {
                        let a_num = take_number(&mut a_chars);
                        let b_num = take_number(&mut b_chars);
                        match a_num.cmp(&b_num) {
                            Ordering::Equal => continue,
                            other => return other,
                        }
                    } else {
                        a_chars.next();
                        b_chars.next();
                        match ca.to_lowercase().cmp(cb.to_lowercase()) {
                            Ordering::Equal => continue,
                            other => return other,
                        }
                    }
                }
            }
        }
    }

    fn take_number<I: Iterator<Item = char>>(iter: &mut std::iter::Peekable<I>) -> u64 {
        let mut num = 0u64;
        while let Some(&c) = iter.peek() {
            if let Some(digit) = c.to_digit(10) {
                num = num.saturating_mul(10).saturating_add(digit as u64);
                iter.next();
            } else {
                break;
            }
        }
        num
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_natural_sort() {
        let mut files = vec!["page_10.jpg", "page_1.jpg", "page_2.jpg", "page_20.jpg"];
        files.sort_by(|a, b| alphanumeric_sort::compare_str(a, b));
        assert_eq!(files, vec!["page_1.jpg", "page_2.jpg", "page_10.jpg", "page_20.jpg"]);
    }
}
