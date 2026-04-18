import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/quiz/quiz_repository.dart';

part 'unlock_premium_category_state.dart';

final class UnlockPremiumCategoryCubit
    extends Cubit<UnlockPremiumCategoryState> {
  UnlockPremiumCategoryCubit(this._quizRepository)
    : super(const UnlockPremiumCategoryInitial());

  final QuizRepository _quizRepository;

  void unlockPremiumCategory({required String categoryId}) {
    emit(const UnlockPremiumCategoryInProgress());

    _quizRepository
        .unlockPremiumCategory(categoryId: categoryId)
        .then((_) => emit(const UnlockPremiumCategorySuccess()))
        .catchError(
          (Object e) => emit(UnlockPremiumCategoryFailure(e.toString())),
        );
  }

  void reset() => emit(const UnlockPremiumCategoryInitial());
}
