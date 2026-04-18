import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/bookmark/bookmark_repository.dart';
import 'package:flutterquiz/features/quiz/models/question.dart';

sealed class BookmarkState {
  const BookmarkState();
}

final class BookmarkInitial extends BookmarkState {
  const BookmarkInitial();
}

final class BookmarkFetchInProgress extends BookmarkState {
  const BookmarkFetchInProgress();
}

final class BookmarkFetchSuccess extends BookmarkState {
  const BookmarkFetchSuccess(this.questions);

  final List<Question> questions;
}

final class BookmarkFetchFailure extends BookmarkState {
  const BookmarkFetchFailure(this.errorMessageCode);

  final String errorMessageCode;
}

final class BookmarkCubit extends Cubit<BookmarkState> {
  BookmarkCubit(this._bookmarkRepository) : super(const BookmarkInitial());

  final BookmarkRepository _bookmarkRepository;

  Future<void> getBookmark() async {
    emit(const BookmarkFetchInProgress());

    try {
      final questions =
          await _bookmarkRepository.getBookmark('1') as List<Question>;

      emit(BookmarkFetchSuccess(questions));
    } on Exception catch (e) {
      emit(BookmarkFetchFailure(e.toString()));
    }
  }

  bool hasQuestionBookmarked(String questionId) {
    return questions().indexWhere((e) => e.id == questionId) != -1;
  }

  void addBookmarkQuestion(Question question) {
    if (state is BookmarkFetchSuccess) {
      emit(BookmarkFetchSuccess(questions()..insert(0, question)));
    }
  }

  void removeBookmarkQuestion(String questionId) {
    if (state is BookmarkFetchSuccess) {
      emit(
        BookmarkFetchSuccess(
          questions()..removeWhere((e) => e.id == questionId),
        ),
      );
    }
  }

  List<Question> questions() {
    if (state is BookmarkFetchSuccess) {
      return (state as BookmarkFetchSuccess).questions;
    }
    return [];
  }

  void reset() => emit(const BookmarkInitial());
}
