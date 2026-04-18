import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/quiz/models/subcategory.dart';
import 'package:flutterquiz/features/quiz/quiz_repository.dart';

sealed class SubCategoryState {
  const SubCategoryState();
}

final class SubCategoryInitial extends SubCategoryState {
  const SubCategoryInitial();
}

final class SubCategoryFetchInProgress extends SubCategoryState {
  const SubCategoryFetchInProgress();
}

final class SubCategoryFetchSuccess extends SubCategoryState {
  const SubCategoryFetchSuccess(this.categoryId, this.subcategoryList);

  final List<Subcategory> subcategoryList;
  final String? categoryId;
}

final class SubCategoryFetchFailure extends SubCategoryState {
  const SubCategoryFetchFailure(this.errorMessage);

  final String errorMessage;
}

final class SubCategoryCubit extends Cubit<SubCategoryState> {
  SubCategoryCubit(this._quizRepository) : super(const SubCategoryInitial());

  final QuizRepository _quizRepository;

  Future<void> fetchSubCategory(String category) async {
    emit(const SubCategoryFetchInProgress());
    await _quizRepository
        .getSubCategory(category)
        .then((val) => emit(SubCategoryFetchSuccess(category, val)))
        .catchError((Object e) {
          emit(SubCategoryFetchFailure(e.toString()));
        });
  }

  void reset() => emit(const SubCategoryInitial());

  void unlockPremiumSubCategory({
    required String categoryId,
    required String id,
  }) {
    if (state is SubCategoryFetchSuccess) {
      final subcategories = (state as SubCategoryFetchSuccess).subcategoryList;

      final idx = subcategories.indexWhere((s) => s.id == id);

      if (idx != -1) {
        emit(const SubCategoryFetchInProgress());
        subcategories[idx] = subcategories[idx].copyWith(hasUnlocked: true);
        emit(SubCategoryFetchSuccess(categoryId, subcategories));
      }
    }
  }
}
