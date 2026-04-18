import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/features/quiz/quiz_repository.dart';

sealed class UnlockedLevelState {
  const UnlockedLevelState();
}

final class UnlockedLevelInitial extends UnlockedLevelState {
  const UnlockedLevelInitial();
}

final class UnlockedLevelFetchInProgress extends UnlockedLevelState {
  const UnlockedLevelFetchInProgress();
}

final class UnlockedLevelFetchSuccess extends UnlockedLevelState {
  const UnlockedLevelFetchSuccess(
    this.categoryId,
    this.subcategoryId,
    this.unlockedLevel,
  );

  final int unlockedLevel;
  final String? categoryId;
  final String? subcategoryId;
}

final class UnlockedLevelFetchFailure extends UnlockedLevelState {
  const UnlockedLevelFetchFailure(this.errorMessage);

  final String errorMessage;
}

final class UnlockedLevelCubit extends Cubit<UnlockedLevelState> {
  UnlockedLevelCubit(this._quizRepository)
    : super(const UnlockedLevelInitial());

  final QuizRepository _quizRepository;

  // TODO(J): make subcategoryId optional
  Future<void> fetchUnlockLevel(
    String category,
    String subCategory, {
    required QuizTypes quizType,
  }) async {
    emit(const UnlockedLevelFetchInProgress());
    await _quizRepository
        .getUnlockedLevel(category, subCategory, quizType: quizType)
        .then(
          (val) => emit(UnlockedLevelFetchSuccess(category, subCategory, val)),
        )
        .catchError((Object e) {
          emit(UnlockedLevelFetchFailure(e.toString()));
        });
  }
}
