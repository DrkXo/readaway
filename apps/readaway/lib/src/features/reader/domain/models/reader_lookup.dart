import 'package:equatable/equatable.dart';

enum ReaderLookupKind { dictionary, translate }

class ReaderLookupRequest extends Equatable {
  const ReaderLookupRequest({required this.kind, required this.text});

  final ReaderLookupKind kind;
  final String text;

  @override
  List<Object?> get props => [kind, text];
}
