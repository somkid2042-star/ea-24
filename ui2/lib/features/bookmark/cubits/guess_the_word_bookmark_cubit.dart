import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/bookmark/bookmark_repository.dart';
import 'package:flutterquiz/features/quiz/models/guess_the_word_question.dart';

sealed class GuessTheWordBookmarkState {
  const GuessTheWordBookmarkState();
}

final class GuessTheWordBookmarkInitial extends GuessTheWordBookmarkState {
  const GuessTheWordBookmarkInitial();
}

final class GuessTheWordBookmarkFetchInProgress
    extends GuessTheWordBookmarkState {
  const GuessTheWordBookmarkFetchInProgress();
}

final class GuessTheWordBookmarkFetchSuccess extends GuessTheWordBookmarkState {
  const GuessTheWordBookmarkFetchSuccess(this.questions);

  //bookmarked questions
  final List<GuessTheWordQuestion> questions;
}

final class GuessTheWordBookmarkFetchFailure extends GuessTheWordBookmarkState {
  const GuessTheWordBookmarkFetchFailure(this.errorMessageCode);

  final String errorMessageCode;
}

final class GuessTheWordBookmarkCubit extends Cubit<GuessTheWordBookmarkState> {
  GuessTheWordBookmarkCubit(this._bookmarkRepository)
    : super(const GuessTheWordBookmarkInitial());

  final BookmarkRepository _bookmarkRepository;

  Future<void> getBookmark() async {
    emit(const GuessTheWordBookmarkFetchInProgress());

    try {
      final questions =
          await _bookmarkRepository.getBookmark('3')
              as List<GuessTheWordQuestion>;

      emit(GuessTheWordBookmarkFetchSuccess(questions));
    } on Exception catch (e) {
      emit(GuessTheWordBookmarkFetchFailure(e.toString()));
    }
  }

  bool hasQuestionBookmarked(String questionId) {
    return questions().indexWhere((e) => e.id == questionId) != -1;
  }

  void addBookmarkQuestion(GuessTheWordQuestion question) {
    if (state is GuessTheWordBookmarkFetchSuccess) {
      emit(GuessTheWordBookmarkFetchSuccess(questions()..insert(0, question)));
    }
  }

  void removeBookmarkQuestion(String questionId) {
    if (state is GuessTheWordBookmarkFetchSuccess) {
      emit(
        GuessTheWordBookmarkFetchSuccess(
          questions()..removeWhere((e) => e.id == questionId),
        ),
      );
    }
  }

  List<GuessTheWordQuestion> questions() {
    if (state is GuessTheWordBookmarkFetchSuccess) {
      return (state as GuessTheWordBookmarkFetchSuccess).questions;
    }
    return [];
  }

  void reset() => emit(const GuessTheWordBookmarkInitial());
}
