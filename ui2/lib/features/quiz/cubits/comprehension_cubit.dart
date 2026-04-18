import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/quiz/models/comprehension.dart';
import 'package:flutterquiz/features/quiz/quiz_repository.dart';

sealed class ComprehensionState {
  const ComprehensionState();
}

final class ComprehensionInitial extends ComprehensionState {
  const ComprehensionInitial();
}

final class ComprehensionProgress extends ComprehensionState {
  const ComprehensionProgress();
}

final class ComprehensionSuccess extends ComprehensionState {
  const ComprehensionSuccess(this.getComprehension);

  final List<Comprehension> getComprehension;
}

final class ComprehensionFailure extends ComprehensionState {
  const ComprehensionFailure(this.errorMessage);

  final String errorMessage;
}

final class ComprehensionCubit extends Cubit<ComprehensionState> {
  ComprehensionCubit(this._quizRepository)
    : super(const ComprehensionInitial());

  final QuizRepository _quizRepository;

  Future<void> getComprehension({
    required String languageId,
    required String type,
    required String typeId,
  }) async {
    emit(const ComprehensionProgress());
    await _quizRepository
        .getComprehension(languageId: languageId, type: type, typeId: typeId)
        .then((val) => emit(ComprehensionSuccess(val)))
        .catchError((Object e) {
          emit(ComprehensionFailure(e.toString()));
        });
  }
}
