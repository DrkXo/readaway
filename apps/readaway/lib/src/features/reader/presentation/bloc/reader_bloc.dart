import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'reader_bloc.freezed.dart';
part 'reader_event.dart';
part 'reader_state.dart';

@injectable
class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  ReaderBloc() : super(_Initial()) {
    on<ReaderEvent>((event, emit) {});
  }
}
