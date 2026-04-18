import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/quiz/models/category.dart';
import 'package:flutterquiz/features/quiz/quiz_repository.dart';

sealed class QuizCategoryState {
  const QuizCategoryState();
}

final class QuizCategoryInitial extends QuizCategoryState {
  const QuizCategoryInitial();
}

final class QuizCategoryProgress extends QuizCategoryState {
  const QuizCategoryProgress();
}

final class QuizCategorySuccess extends QuizCategoryState {
  const QuizCategorySuccess(this.categories);

  final List<Category> categories;
}

final class QuizCategoryFailure extends QuizCategoryState {
  const QuizCategoryFailure(this.errorMessage);

  final String errorMessage;
}

final class QuizCategoryCubit extends Cubit<QuizCategoryState> {
  QuizCategoryCubit(this._quizRepository) : super(const QuizCategoryInitial());

  final QuizRepository _quizRepository;

  Future<void> getQuizCategoryWithUserId({
    required String languageId,
    required String type,
    String? subType,
  }) async {
    emit(const QuizCategoryProgress());
    await _quizRepository
        .getCategory(languageId: languageId, type: type, subType: subType)
        .then((v) => emit(QuizCategorySuccess(v)))
        .catchError((Object e) => emit(QuizCategoryFailure(e.toString())));
  }

  Future<void> getQuizCategory({
    required String languageId,
    required String type,
  }) async {
    emit(const QuizCategoryProgress());
    await _quizRepository
        .getCategoryWithoutUser(languageId: languageId, type: type)
        .then((v) => emit(QuizCategorySuccess(v)))
        .catchError((Object e) => emit(QuizCategoryFailure(e.toString())));
  }

  void reset() => emit(const QuizCategoryInitial());

  void unlockPremiumCategory({required String id}) {
    if (state is QuizCategorySuccess) {
      final categories = (state as QuizCategorySuccess).categories;

      final idx = categories.indexWhere((c) => c.id == id);

      if (idx != -1) {
        emit(const QuizCategoryProgress());

        categories[idx] = categories[idx].copyWith(hasUnlocked: true);

        emit(QuizCategorySuccess(categories));
      }
    }
  }

  bool isPremiumCategoryUnlocked(String categoryId) {
    if (state is QuizCategorySuccess) {
      final categories = (state as QuizCategorySuccess).categories;

      final idx = categories.indexWhere((c) => c.id == categoryId);

      if (idx != -1) {
        final cate = categories[idx];
        return !cate.isPremium || (cate.isPremium && cate.hasUnlocked);
      }
    }
    return false;
  }

  Object getCat() {
    if (state is QuizCategorySuccess) {
      return (state as QuizCategorySuccess).categories;
    }
    return '';
  }
}
