part of 'reader_bloc.dart';

@freezed
abstract class ReaderEvent with _$ReaderEvent {
  const factory ReaderEvent.openDocument({
    required String path,
    required String fileName,
  }) = _OpenDocument;
  const factory ReaderEvent.pageChanged({required int index}) = _PageChanged;
  const factory ReaderEvent.loadPage({required int index}) = _LoadPage;
  const factory ReaderEvent.closeDocument() = _CloseDocument;
}
