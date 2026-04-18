import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/quiz/models/contest.dart';
import 'package:flutterquiz/features/quiz/quiz_repository.dart';
import 'package:flutterquiz/utils/datetime_utils.dart';

sealed class ContestState {
  const ContestState();
}

final class ContestInitial extends ContestState {
  const ContestInitial();
}

final class ContestProgress extends ContestState {
  const ContestProgress();
}

final class ContestSuccess extends ContestState {
  const ContestSuccess(this.contestList);

  final Contests contestList;
}

final class ContestFailure extends ContestState {
  const ContestFailure(this.errorMessage);

  final String errorMessage;
}

final class ContestCubit extends Cubit<ContestState> {
  ContestCubit(this._quizRepository) : super(const ContestInitial());

  final QuizRepository _quizRepository;

  Future<void> getContest({required String languageId}) async {
    emit(const ContestProgress());
    final (:gmt, :localTimezone) = await DateTimeUtils.getTimeZone();

    await _quizRepository
        .getContest(languageId: languageId, timezone: localTimezone, gmt: gmt)
        .then((val) {
          emit(ContestSuccess(val));
        })
        .catchError((Object e) {
          emit(ContestFailure(e.toString()));
        });
  }
}
