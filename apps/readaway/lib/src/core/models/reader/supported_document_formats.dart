import 'package:path/path.dart' as p;

/// Represents high-level document categories supported by the reader.
enum DocumentCategory {
  pdf,
  xps,
  ebook,
  comic,
  text,
  office,
  image,
  compressed,
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

/// Central registry of all formats supported natively by MuPDF and ReadAway.
class SupportedDocumentFormats {
  SupportedDocumentFormats._();

  static const DocumentFormatInfo pdf = DocumentFormatInfo(
    name: 'Portable Document Format',
    category: DocumentCategory.pdf,
    extensions: ['pdf', 'ai', 'pclm', 'fdf'],
    mimeTypes: ['application/pdf', 'application/PCLm'],
    isReflowable: false,
  );

  static const DocumentFormatInfo xps = DocumentFormatInfo(
    name: 'XML Paper Specification',
    category: DocumentCategory.xps,
    extensions: ['xps', 'oxps'],
    mimeTypes: [
      'application/oxps',
      'application/xps',
      'application/vnd.ms-xpsdocument',
    ],
    isReflowable: false,
  );

  static const DocumentFormatInfo epub = DocumentFormatInfo(
    name: 'EPUB E-Book',
    category: DocumentCategory.ebook,
    extensions: ['epub'],
    mimeTypes: ['application/epub+zip'],
    isReflowable: true,
  );

  static const DocumentFormatInfo mobi = DocumentFormatInfo(
    name: 'Mobipocket / Kindle',
    category: DocumentCategory.ebook,
    extensions: ['mobi', 'prc', 'pdb'],
    mimeTypes: ['application/x-mobipocket-ebook'],
    isReflowable: true,
  );

  static const DocumentFormatInfo fb2 = DocumentFormatInfo(
    name: 'FictionBook 2',
    category: DocumentCategory.ebook,
    extensions: ['fb2'],
    mimeTypes: ['application/x-fictionbook'],
    isReflowable: true,
  );

  static const DocumentFormatInfo cbz = DocumentFormatInfo(
    name: 'Comic Book Archive',
    category: DocumentCategory.comic,
    extensions: ['cbz', 'cbr', 'cbt', 'tar', 'zip'],
    mimeTypes: [
      'application/vnd.comicbook+zip',
      'application/vnd.comicbook-rar',
      'application/x-cbz',
      'application/x-cbr',
      'application/x-cbt',
      'application/x-tar',
      'application/zip',
    ],
    isReflowable: false,
  );

  static const DocumentFormatInfo plainText = DocumentFormatInfo(
    name: 'Plain Text & Logs',
    category: DocumentCategory.text,
    extensions: ['txt', 'text', 'log'],
    mimeTypes: ['text/plain'],
    isReflowable: true,
  );

  static const DocumentFormatInfo markdown = DocumentFormatInfo(
    name: 'Markdown',
    category: DocumentCategory.text,
    extensions: ['md'],
    mimeTypes: ['text/markdown'],
    isReflowable: true,
  );

  static const DocumentFormatInfo html = DocumentFormatInfo(
    name: 'HTML & Web Documents',
    category: DocumentCategory.text,
    extensions: ['html', 'htm', 'xhtml', 'xml'],
    mimeTypes: ['text/html', 'application/xhtml+xml', 'application/xml'],
    isReflowable: true,
  );

  static const DocumentFormatInfo office = DocumentFormatInfo(
    name: 'Office Document',
    category: DocumentCategory.office,
    extensions: ['docx', 'xlsx', 'pptx', 'hwpx'],
    mimeTypes: [
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/haansofthwpx',
      'application/vnd.hancom.hwpx',
    ],
    isReflowable: true,
  );

  static const DocumentFormatInfo svg = DocumentFormatInfo(
    name: 'Scalable Vector Graphics',
    category: DocumentCategory.image,
    extensions: ['svg'],
    mimeTypes: ['image/svg+xml'],
    isReflowable: false,
  );

  static const DocumentFormatInfo images = DocumentFormatInfo(
    name: 'Image Document',
    category: DocumentCategory.image,
    extensions: [
      'png',
      'jpg',
      'jpeg',
      'jpe',
      'jfif',
      'jfif-tbnl',
      'bmp',
      'gif',
      'webp',
      'tif',
      'tiff',
      'jp2',
      'j2k',
      'jpx',
      'jxr',
      'hdp',
      'wdp',
      'psd',
      'pnm',
      'pbm',
      'pgm',
      'ppm',
      'pam',
      'pfm',
      'pkm',
    ],
    mimeTypes: [
      'image/png',
      'image/jpeg',
      'image/pjpeg',
      'image/webp',
      'image/bmp',
      'image/gif',
      'image/tiff',
      'image/x-tiff',
      'image/jp2',
      'image/jpx',
      'image/jxr',
      'image/vnd.adobe.photoshop',
      'image/x-portable-pixmap',
    ],
    isReflowable: false,
  );

  static const DocumentFormatInfo gzip = DocumentFormatInfo(
    name: 'Gzip Compressed Document',
    category: DocumentCategory.compressed,
    extensions: ['gz'],
    mimeTypes: ['application/x-gzip-compressed'],
    isReflowable: false,
  );

  /// All supported format specifications.
  static const List<DocumentFormatInfo> allFormats = [
    pdf,
    xps,
    epub,
    mobi,
    fb2,
    cbz,
    plainText,
    markdown,
    html,
    office,
    svg,
    images,
    gzip,
  ];

  /// Set of all lowercase file extensions supported by the app (without leading dots).
  static final Set<String> allExtensions = {
    for (final fmt in allFormats)
      for (final ext in fmt.extensions) ext.toLowerCase(),
  };

  /// Common extensions prioritized for user file pickers.
  static const List<String> pickerExtensions = [
    'pdf',
    'epub',
    'mobi',
    'fb2',
    'xps',
    'oxps',
    'cbz',
    'cbr',
    'txt',
    'md',
    'html',
    'htm',
    'docx',
    'pptx',
    'xlsx',
    'svg',
    'png',
    'jpg',
    'jpeg',
    'webp',
  ];

  /// Check whether a file at [filePath] has an extension supported by MuPDF.
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
