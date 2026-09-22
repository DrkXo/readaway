import 'package:xml/xml.dart';
import '../../models/models.dart';

/// Represents a single page annotation inside ComicInfo.xml
class ComicPageInfo {
  final int imageIndex;
  final String? type; // e.g. "Cover", "Story", "Editorial", "Advertisement"
  final bool isDoublePage;
  final String? bookmark;

  const ComicPageInfo({
    required this.imageIndex,
    this.type,
    this.isDoublePage = false,
    this.bookmark,
  });
}

/// Parsed ComicInfo.xml metadata schema.
class ComicInfo {
  final String? title;
  final String? series;
  final String? number;
  final int? volume;
  final String? summary;
  final String? writer;
  final String? penciller;
  final String? inker;
  final String? colorist;
  final String? letterer;
  final String? coverArtist;
  final String? publisher;
  final String? genre;
  final String? language;
  final int? pageCount;
  final List<ComicPageInfo> pages;

  const ComicInfo({
    this.title,
    this.series,
    this.number,
    this.volume,
    this.summary,
    this.writer,
    this.penciller,
    this.inker,
    this.colorist,
    this.letterer,
    this.coverArtist,
    this.publisher,
    this.genre,
    this.language,
    this.pageCount,
    this.pages = const [],
  });

  /// Formatted author / creator credit line.
  String? get combinedAuthor {
    final creators = <String>[];
    if (writer != null && writer!.isNotEmpty) creators.add(writer!);
    if (penciller != null && penciller!.isNotEmpty && penciller != writer) {
      creators.add('Art: $penciller');
    }
    if (creators.isEmpty && publisher != null && publisher!.isNotEmpty) {
      creators.add(publisher!);
    }
    return creators.isNotEmpty ? creators.join(', ') : null;
  }

  /// Converts parsed ComicInfo into standard ReadAway [DocumentMetadata].
  DocumentMetadata toDocumentMetadata() {
    return DocumentMetadata(
      title: title ?? (series != null ? '$series #$number' : null),
      author: combinedAuthor,
      language: language,
      description: summary,
      publisher: publisher,
    );
  }
}

/// Parser for ComicRack / standard `ComicInfo.xml` metadata files.
class ComicInfoParser {
  const ComicInfoParser._();

  static ComicInfo? parse(String xmlSource) {
    try {
      final doc = XmlDocument.parse(xmlSource);
      final root = doc.findElements('ComicInfo').firstOrNull ?? doc.rootElement;

      String? getElemText(String name) {
        final elem = root.findElements(name).firstOrNull;
        return elem?.innerText.trim().isNotEmpty == true ? elem!.innerText.trim() : null;
      }

      int? getElemInt(String name) {
        final txt = getElemText(name);
        return txt != null ? int.tryParse(txt) : null;
      }

      final pages = <ComicPageInfo>[];
      final pagesContainer = root.findElements('Pages').firstOrNull;
      if (pagesContainer != null) {
        for (final pageElem in pagesContainer.findElements('Page')) {
          final imgAttr = pageElem.getAttribute('Image');
          final imgIdx = imgAttr != null ? int.tryParse(imgAttr) : null;
          if (imgIdx != null) {
            final typeAttr = pageElem.getAttribute('Type');
            final doubleAttr = pageElem.getAttribute('DoublePage')?.toLowerCase();
            final bookmarkAttr = pageElem.getAttribute('Bookmark');
            pages.add(ComicPageInfo(
              imageIndex: imgIdx,
              type: typeAttr,
              isDoublePage: doubleAttr == 'true' || doubleAttr == '1',
              bookmark: bookmarkAttr,
            ));
          }
        }
      }

      return ComicInfo(
        title: getElemText('Title'),
        series: getElemText('Series'),
        number: getElemText('Number'),
        volume: getElemInt('Volume'),
        summary: getElemText('Summary'),
        writer: getElemText('Writer'),
        penciller: getElemText('Penciller'),
        inker: getElemText('Inker'),
        colorist: getElemText('Colorist'),
        letterer: getElemText('Letterer'),
        coverArtist: getElemText('CoverArtist'),
        publisher: getElemText('Publisher'),
        genre: getElemText('Genre'),
        language: getElemText('LanguageISO'),
        pageCount: getElemInt('PageCount'),
        pages: pages,
      );
    } catch (_) {
      return null;
    }
  }
}
