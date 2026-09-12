import 'package:path/path.dart' as p;

/// Represents high-level document categories supported by the reader.
enum DocumentCategory {
  ebook,
  text,
  unknown,
}

/// Information about a supported document format.
class DocumentFormatInfo {
  final String name;
  final DocumentCategory category;
  final List<String> extensions;
  final List<String> mimeTypes;
  final bool isReflowable;

  const DocumentFormatInfo({
    required this.name,
    required this.category,
    required this.extensions,
    required this.mimeTypes,
    required this.isReflowable,
  });
}

/// Central registry of all formats supported by ReadAway.
class SupportedDocumentFormats {
  SupportedDocumentFormats._();

  static const DocumentFormatInfo epub = DocumentFormatInfo(
    name: 'EPUB E-Book',
    category: DocumentCategory.ebook,
    extensions: ['epub'],
    mimeTypes: ['application/epub+zip'],
    isReflowable: true,
  );

  static const DocumentFormatInfo plainText = DocumentFormatInfo(
    name: 'Plain Text & Logs',
    category: DocumentCategory.text,
    extensions: ['txt', 'text', 'log'],
    mimeTypes: ['text/plain'],
    isReflowable: true,
  );

  static const DocumentFormatInfo html = DocumentFormatInfo(
    name: 'HTML & Web Documents',
    category: DocumentCategory.text,
    extensions: ['html', 'htm', 'xhtml', 'xml'],
    mimeTypes: ['text/html', 'application/xhtml+xml', 'application/xml'],
    isReflowable: true,
  );

  /// All supported format specifications.
  static const List<DocumentFormatInfo> allFormats = [
    epub,
    plainText,
    html,
  ];

  /// Set of all lowercase file extensions supported by the app (without leading dots).
  static final Set<String> allExtensions = {
    for (final fmt in allFormats)
      for (final ext in fmt.extensions) ext.toLowerCase(),
  };

  /// Common extensions prioritized for user file pickers.
  static const List<String> pickerExtensions = [
    'epub',
    'txt',
    'html',
    'htm',
  ];

  /// Check whether a file at [filePath] has a supported extension.
  static bool isSupported(String filePath) {
    final ext = p.extension(filePath).replaceFirst('.', '').toLowerCase();
    return allExtensions.contains(ext);
  }

  /// Get the category of a document by its file path or extension.
  static DocumentCategory getCategory(String filePath) {
    final ext = p.extension(filePath).replaceFirst('.', '').toLowerCase();
    for (final fmt in allFormats) {
      if (fmt.extensions.contains(ext)) {
        return fmt.category;
      }
    }
    return DocumentCategory.unknown;
  }

  /// Find format info for a given file path.
  static DocumentFormatInfo? findFormat(String filePath) {
    final ext = p.extension(filePath).replaceFirst('.', '').toLowerCase();
    for (final fmt in allFormats) {
      if (fmt.extensions.contains(ext)) {
        return fmt;
      }
    }
    return null;
  }
}
