part of 'reader_bloc.dart';

@freezed
abstract class ReaderEvent with _$ReaderEvent {
  const factory ReaderEvent.started() = _Started;
}
