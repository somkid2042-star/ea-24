import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/bookmark/bookmark_repository.dart';

sealed class UpdateBookmarkState {
  const UpdateBookmarkState();
}

final class UpdateBookmarkInitial extends UpdateBookmarkState {
  const UpdateBookmarkInitial();
}

final class UpdateBookmarkInProgress extends UpdateBookmarkState {
  const UpdateBookmarkInProgress();
}

final class UpdateBookmarkSuccess extends UpdateBookmarkState {
  const UpdateBookmarkSuccess();
}

final class UpdateBookmarkFailure extends UpdateBookmarkState {
  const UpdateBookmarkFailure(this.errorMessageCode, this.failedStatus);

  final String errorMessageCode;
  final String failedStatus;
}

class UpdateBookmarkCubit extends Cubit<UpdateBookmarkState> {
  UpdateBookmarkCubit(this._bookmarkRepository)
    : super(const UpdateBookmarkInitial());

  final BookmarkRepository _bookmarkRepository;

  Future<void> updateBookmark(
    String questionId,
    String status,
    String type,
  ) async {
    emit(const UpdateBookmarkInProgress());
    try {
      await _bookmarkRepository.updateBookmark(questionId, status, type);
      emit(const UpdateBookmarkSuccess());
    } on Exception catch (e) {
      emit(UpdateBookmarkFailure(e.toString(), status));
    }
  }
}
