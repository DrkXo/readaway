import 'package:mupdf/mupdf.dart';

import '../../../../core/models/reader/reader_document.dart';

/// Abstract contract for parsing document source into a pure [ReaderDocument] AST.
abstract interface class DocumentParser<TInput> {
  ReaderDocument parse(TInput input, {List<PageLink>? links});
}
