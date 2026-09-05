import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/recent_document.dart';
import '../../domain/repositories/library_repository.dart';
import 'library_state.dart';

@injectable
class LibraryCubit extends Cubit<LibraryState> {
  final LibraryRepository _repository;

  LibraryCubit(this._repository) : super(const LibraryState());

  Future<void> loadRecentDocuments() async {
    emit(state.copyWith(isLoading: true, clearFailure: true));

    final result = await _repository.getRecentDocuments().run();

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (documents) {
        emit(state.copyWith(
          isLoading: false,
          recentDocuments: documents,
          clearFailure: true,
        ));
        _populateMissingCovers(documents);
      },
    );
  }

  Future<void> _populateMissingCovers(List<RecentDocument> documents) async {
    for (final doc in documents) {
      if (doc.coverPath == null || doc.coverPath!.isEmpty) {
        final coverResult = await _repository.getCoverArtPath(doc).run();
        coverResult.fold(
          (_) {},
          (optionPath) {
            optionPath.fold(
              () {},
              (path) {
                final currentList = state.recentDocuments;
                final index = currentList.indexWhere((d) => d.path == doc.path);
                if (index != -1) {
                  final updatedList = List<RecentDocument>.from(currentList);
                  updatedList[index] =
                      updatedList[index].copyWith(coverPath: path);
                  emit(state.copyWith(recentDocuments: updatedList));
                }
              },
            );
          },
        );
      }
    }
  }

  Future<void> pickAndOpenDocument() async {
    emit(state.copyWith(isLoading: true, clearFailure: true, clearOpened: true));

    final result = await _repository.pickDocument().run();

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (optionDoc) {
        optionDoc.fold(
          () => emit(state.copyWith(isLoading: false)), // User cancelled
          (doc) {
            final updated = [doc, ...state.recentDocuments.where((d) => d.path != doc.path)];
            emit(state.copyWith(
              isLoading: false,
              recentDocuments: updated,
              openedDocument: doc,
              clearFailure: true,
            ));
          },
        );
      },
    );
  }

  Future<void> removeRecent(String path) async {
    final result = await _repository.removeRecentDocument(path).run();

    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (_) {
        final updated = state.recentDocuments.where((d) => d.path != path).toList();
        emit(state.copyWith(recentDocuments: updated));
      },
    );
  }

  void clearOpened() {
    emit(state.copyWith(clearOpened: true));
  }
}
