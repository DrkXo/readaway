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
  final bool requiresPasswordSupport;
  final bool supportsTextExtraction;

  const DocumentFormatInfo({
    required this.name,
    required this.category,
    required this.extensions,
    required this.mimeTypes,
    required this.isReflowable,
    this.requiresPasswordSupport = false,
    this.supportsTextExtraction = true,
  });

  bool get isFixedLayout => !isReflowable;
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
    supportsTextExtraction: true,
  );

  static const DocumentFormatInfo pdf = DocumentFormatInfo(
    name: 'Portable Document Format',
    category: DocumentCategory.ebook,
    extensions: ['pdf'],
    mimeTypes: ['application/pdf'],
    isReflowable: false,
    requiresPasswordSupport: true,
    supportsTextExtraction: false,
  );

  static const DocumentFormatInfo comicBook = DocumentFormatInfo(
    name: 'Comic Book Archive',
    category: DocumentCategory.ebook,
    extensions: ['cbz', 'cbr', 'cbt', 'cb7'],
    mimeTypes: [
      'application/vnd.comicbook+zip',
      'application/x-cbz',
      'application/x-cbr',
      'application/x-cbt',
      'application/x-cb7',
    ],
    isReflowable: false,
    supportsTextExtraction: false,
  );

  static const DocumentFormatInfo plainText = DocumentFormatInfo(
    name: 'Plain Text & Logs',
    category: DocumentCategory.text,
    extensions: ['txt', 'text', 'log'],
    mimeTypes: ['text/plain'],
    isReflowable: true,
    supportsTextExtraction: true,
  );

  static const DocumentFormatInfo html = DocumentFormatInfo(
    name: 'HTML & Web Documents',
    category: DocumentCategory.text,
    extensions: ['html', 'htm', 'xhtml'],
    mimeTypes: ['text/html', 'application/xhtml+xml'],
    isReflowable: true,
    supportsTextExtraction: true,
  );

  static const DocumentFormatInfo markdown = DocumentFormatInfo(
    name: 'Markdown',
    category: DocumentCategory.text,
    extensions: ['md', 'markdown'],
    mimeTypes: ['text/markdown', 'text/x-markdown'],
    isReflowable: true,
    supportsTextExtraction: true,
  );

  /// All supported format specifications.
  static const List<DocumentFormatInfo> allFormats = [
    epub,
    pdf,
    comicBook,
    plainText,
    html,
    markdown,
  ];

  /// Set of all lowercase file extensions supported by the app (without leading dots).
  static final Set<String> allExtensions = {
    for (final fmt in allFormats)
      for (final ext in fmt.extensions) ext.toLowerCase(),
  };

  /// Common extensions prioritized for user file pickers.
  static const List<String> pickerExtensions = [
    'epub',
    'pdf',
    'cbz',
    'cbr',
    'cbt',
    'cb7',
    'txt',
    'md',
    'html',
    'htm',
  ];

  /// Check whether a file at [filePath] has a supported extension.
  static bool isSupported(String filePath) {
    final ext = p.extension(filePath).replaceFirst('.', '').toLowerCase();
    return allExtensions.contains(ext);
  }

  /// Whether a document at [filePath] is reflowable text.
  static bool isReflowable(String filePath) {
    return findFormat(filePath)?.isReflowable ?? false;
  }

  /// Whether a document at [filePath] is a comic archive.
  static bool isComic(String filePath) {
    final ext = p.extension(filePath).replaceFirst('.', '').toLowerCase();
    return comicBook.extensions.contains(ext);
  }

  /// Whether a document at [filePath] is a PDF.
  static bool isPdf(String filePath) {
    final ext = p.extension(filePath).replaceFirst('.', '').toLowerCase();
    return pdf.extensions.contains(ext);
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
