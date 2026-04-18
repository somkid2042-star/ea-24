import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/bookmark/bookmark_repository.dart';
import 'package:flutterquiz/features/quiz/models/question.dart';

sealed class AudioQuestionBookMarkState {
  const AudioQuestionBookMarkState();
}

final class AudioQuestionBookmarkInitial extends AudioQuestionBookMarkState {
  const AudioQuestionBookmarkInitial();
}

final class AudioQuestionBookmarkFetchInProgress
    extends AudioQuestionBookMarkState {
  const AudioQuestionBookmarkFetchInProgress();
}

final class AudioQuestionBookmarkFetchSuccess
    extends AudioQuestionBookMarkState {
  const AudioQuestionBookmarkFetchSuccess(this.questions);

  final List<Question> questions;
}

final class AudioQuestionBookmarkFetchFailure
    extends AudioQuestionBookMarkState {
  const AudioQuestionBookmarkFetchFailure(this.errorMessageCode);

  final String errorMessageCode;
}

final class AudioQuestionBookmarkCubit
    extends Cubit<AudioQuestionBookMarkState> {
  AudioQuestionBookmarkCubit(this._bookmarkRepository)
    : super(const AudioQuestionBookmarkInitial());

  final BookmarkRepository _bookmarkRepository;

  Future<void> getBookmark() async {
    emit(const AudioQuestionBookmarkFetchInProgress());

    try {
      final questions =
          await _bookmarkRepository.getBookmark('4') as List<Question>;

      emit(AudioQuestionBookmarkFetchSuccess(questions));
    } on Exception catch (e) {
      emit(AudioQuestionBookmarkFetchFailure(e.toString()));
    }
  }

  bool hasQuestionBookmarked(String questionId) {
    return questions().indexWhere((e) => e.id == questionId) != -1;
  }

  void addBookmarkQuestion(Question question) {
    if (state is AudioQuestionBookmarkFetchSuccess) {
      emit(AudioQuestionBookmarkFetchSuccess(questions()..insert(0, question)));
    }
  }

  void removeBookmarkQuestion(String questionId) {
    if (state is AudioQuestionBookmarkFetchSuccess) {
      emit(
        AudioQuestionBookmarkFetchSuccess(
          questions()..removeWhere((e) => e.id == questionId),
        ),
      );
    }
  }

  List<Question> questions() {
    if (state is AudioQuestionBookmarkFetchSuccess) {
      return (state as AudioQuestionBookmarkFetchSuccess).questions;
    }
    return [];
  }

  void reset() => emit(const AudioQuestionBookmarkInitial());
}
