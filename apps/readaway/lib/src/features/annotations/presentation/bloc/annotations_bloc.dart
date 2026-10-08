import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entity/document_notes.dart';
import '../../domain/entity/reader_note.dart';
import '../../domain/entity/reader_notes_filter.dart';
import '../../domain/repositories/annotations_repository.dart';
import '../../domain/services/reader_note_operations.dart';

part 'annotations_bloc.freezed.dart';
part 'annotations_event.dart';
part 'annotations_state.dart';

/// Owns the bookmarks, highlights and notes of the document currently open in
/// the reader.
///
/// One document is open at a time, so a single app-scoped instance is enough
/// and avoids threading a per-route provider through the reader's widgets. The
/// reader page loads a document's notes when the document changes and clears
/// them when it closes.
@lazySingleton
class AnnotationsBloc extends Bloc<AnnotationsEvent, AnnotationsState> {
  final _log = AppLogger.instance.scope('AnnotationsBloc');
  final AnnotationsRepository _repository;

  /// Failures from a *mutation*, as one-shot notifications.
  ///
  /// These are kept out of the state on purpose: a failed write must not
  /// replace the list the reader is looking at. The reader shows them as a
  /// toast and keeps the notes on screen.
  final _failures = StreamController<Failure>.broadcast();

  AnnotationsBloc(this._repository) : super(const AnnotationsState()) {
    on<_LoadForDocument>(_onLoadForDocument, transformer: restartable());
    on<_Clear>(_onClear);

    // Sequential rather than droppable: each of these is a deliberate user
    // action against the same list, and dropping one because another was in
    // flight would silently discard a delete or a restyle.
    on<_AddHighlight>(_onAddHighlight, transformer: sequential());
    on<_AddNote>(_onAddNote, transformer: sequential());
    on<_ToggleBookmark>(_onToggleBookmark, transformer: sequential());
    on<_UpdateNoteBody>(_onUpdateNoteBody, transformer: sequential());
    on<_RestyleNote>(_onRestyleNote, transformer: sequential());
    on<_DeleteNote>(_onDeleteNote, transformer: sequential());
    on<_RestoreNote>(_onRestoreNote, transformer: sequential());
    on<_DeleteAll>(_onDeleteAll, transformer: sequential());

    on<_FilterChanged>(_onFilterChanged);
  }

  /// Mutation failures, for the reader to surface as a toast.
  Stream<Failure> get failures => _failures.stream;

  @override
  Future<void> close() async {
    await _failures.close();
    return super.close();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> _onLoadForDocument(
    _LoadForDocument event,
    Emitter<AnnotationsState> emit,
  ) async {
    final path = event.documentPath;

    // Re-loading the same document — a rebuild, or the reader re-opening it —
    // must not throw away unsaved in-memory state.
    if (state.documentPath == path && state.status == AnnotationsStatus.ready) {
      return;
    }

    emit(
      AnnotationsState(
        status: AnnotationsStatus.loading,
        documentPath: path,
      ),
    );

    final result = await _repository.getForDocument(path);

    result.fold(
      (failure) {
        _log.e('Failed to load annotations for $path: $failure');
        emit(
          AnnotationsState(
            status: AnnotationsStatus.failure,
            documentPath: path,
            failure: failure,
          ),
        );
      },
      (record) => emit(
        _stateFor(record, const ReaderNotesFilter()),
      ),
    );
  }

  void _onClear(_Clear event, Emitter<AnnotationsState> emit) {
    emit(const AnnotationsState());
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  Future<void> _onAddHighlight(
    _AddHighlight event,
    Emitter<AnnotationsState> emit,
  ) => _mutate(emit, (notes) {
    final existing = ReaderNoteOperations.identicalHighlight(
      notes,
      event.anchor,
    );
    // Re-highlighting exactly the same words takes the highlight away.
    if (existing != null) {
      return ReaderNoteOperations.tombstone(
        notes,
        existing.id,
        DateTime.now(),
      );
    }

    final now = DateTime.now();
    return ReaderNoteOperations.upsert(
      notes,
      ReaderNote(
        id: newReaderNoteId(),
        type: ReaderNoteType.highlight,
        anchor: event.anchor,
        style: event.style,
        colorValue: event.colorValue,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  Future<void> _onAddNote(
    _AddNote event,
    Emitter<AnnotationsState> emit,
  ) => _mutate(emit, (notes) {
    final now = DateTime.now();
    final isPainted = event.style != null || event.colorValue != null;

    final existingIndex = notes.indexWhere(
      (n) =>
          !n.isDeleted &&
          n.type != ReaderNoteType.bookmark &&
          n.anchor.chapterIndex == event.anchor.chapterIndex &&
          n.anchor.startChar == event.anchor.startChar &&
          n.anchor.endChar == event.anchor.endChar,
    );

    if (existingIndex >= 0) {
      final existing = notes[existingIndex];
      final next = [...notes];
      next[existingIndex] = existing.copyWith(
        note: event.note,
        type: isPainted ? ReaderNoteType.highlight : existing.type,
        style: event.style ?? existing.style,
        colorValue: event.colorValue ?? existing.colorValue,
        updatedAt: now,
      );
      return next;
    }

    return ReaderNoteOperations.upsert(
      notes,
      ReaderNote(
        id: newReaderNoteId(),
        type: isPainted ? ReaderNoteType.highlight : ReaderNoteType.note,
        anchor: event.anchor,
        note: event.note,
        style: event.style ?? HighlightStyle.highlight,
        colorValue: event.colorValue ?? 'amber',
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  Future<void> _onToggleBookmark(
    _ToggleBookmark event,
    Emitter<AnnotationsState> emit,
  ) => _mutate(emit, (notes) {
    final existing = ReaderNoteOperations.identicalBookmark(
      notes,
      event.anchor,
    );
    if (existing != null) {
      return ReaderNoteOperations.tombstone(
        notes,
        existing.id,
        DateTime.now(),
      );
    }

    final now = DateTime.now();
    return ReaderNoteOperations.upsert(
      notes,
      ReaderNote(
        id: newReaderNoteId(),
        type: ReaderNoteType.bookmark,
        anchor: event.anchor,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  Future<void> _onUpdateNoteBody(
    _UpdateNoteBody event,
    Emitter<AnnotationsState> emit,
  ) => _mutateNote(emit, event.id, (note, now) {
    return note.copyWith(note: event.note, updatedAt: now);
  });

  Future<void> _onRestyleNote(
    _RestyleNote event,
    Emitter<AnnotationsState> emit,
  ) => _mutateNote(emit, event.id, (note, now) {
    // A record restyled from a note into a highlight becomes painted, which is
    // what the reader expects after choosing a colour for it.
    return note.copyWith(
      type: ReaderNoteType.highlight,
      style: event.style,
      colorValue: event.colorValue,
      updatedAt: now,
    );
  });

  Future<void> _onDeleteNote(
    _DeleteNote event,
    Emitter<AnnotationsState> emit,
  ) => _mutate(
    emit,
    (notes) => ReaderNoteOperations.tombstone(notes, event.id, DateTime.now()),
  );

  Future<void> _onRestoreNote(
    _RestoreNote event,
    Emitter<AnnotationsState> emit,
  ) => _mutate(
    emit,
    (notes) => ReaderNoteOperations.restore(notes, event.id, DateTime.now()),
  );

  Future<void> _onDeleteAll(
    _DeleteAll event,
    Emitter<AnnotationsState> emit,
  ) => _mutate(emit, (notes) {
    // Tombstoning is idempotent, so notes that are already deleted are left
    // exactly as they were rather than re-stamped.
    final now = DateTime.now();
    var next = notes;
    for (final note in notes) {
      next = ReaderNoteOperations.tombstone(next, note.id, now);
    }
    return next;
  });

  // ---------------------------------------------------------------------------
  // Filter
  // ---------------------------------------------------------------------------

  void _onFilterChanged(_FilterChanged event, Emitter<AnnotationsState> emit) {
    emit(state.copyWith(filter: event.filter));
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Applies [mutate] to the open document's notes and persists the result.
  Future<void> _mutate(
    Emitter<AnnotationsState> emit,
    List<ReaderNote> Function(List<ReaderNote> notes) mutate,
  ) async {
    final path = state.documentPath;
    if (path == null) return;

    final result = await _repository.save(mutate(state.notes).asDocument(path));

    result.fold(
      (failure) {
        _log.e('Failed to save annotations for $path: $failure');
        _failures.add(failure);
      },
      // Re-derive the whole state from what was actually written, so the list
      // always reflects storage rather than an optimistic guess.
      (saved) => emit(_stateFor(saved, state.filter)),
    );
  }

  /// Applies [mutate] to the single note with [id], leaving the rest alone.
  Future<void> _mutateNote(
    Emitter<AnnotationsState> emit,
    String id,
    ReaderNote Function(ReaderNote note, DateTime now) mutate,
  ) => _mutate(emit, (notes) {
    final index = notes.indexWhere((note) => note.id == id);
    if (index < 0) return notes;
    final next = [...notes];
    next[index] = mutate(next[index], DateTime.now());
    return next;
  });

  AnnotationsState _stateFor(
    DocumentNotes record,
    ReaderNotesFilter filter,
  ) => AnnotationsState(
    status: AnnotationsStatus.ready,
    documentPath: record.documentPath,
    notes: record.notes,
    byChapter: ReaderNoteOperations.indexByChapter(record.notes),
    filter: filter,
  );
}
