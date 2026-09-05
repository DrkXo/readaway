import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entity/recent_document.dart';

class LibraryState extends Equatable {
  final bool isLoading;
  final List<RecentDocument> recentDocuments;
  final Failure? failure;
  final RecentDocument? openedDocument;

  const LibraryState({
    this.isLoading = false,
    this.recentDocuments = const [],
    this.failure,
    this.openedDocument,
  });

  LibraryState copyWith({
    bool? isLoading,
    List<RecentDocument>? recentDocuments,
    Failure? failure,
    RecentDocument? openedDocument,
    bool clearOpened = false,
    bool clearFailure = false,
  }) {
    return LibraryState(
      isLoading: isLoading ?? this.isLoading,
      recentDocuments: recentDocuments ?? this.recentDocuments,
      failure: clearFailure ? null : (failure ?? this.failure),
      openedDocument: clearOpened ? null : (openedDocument ?? this.openedDocument),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    recentDocuments,
    failure,
    openedDocument,
  ];
}
