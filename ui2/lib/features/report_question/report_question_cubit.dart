import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/features/report_question/report_question_repository.dart';

sealed class ReportQuestionState {
  const ReportQuestionState();
}

final class ReportQuestionInitial extends ReportQuestionState {
  const ReportQuestionInitial();
}

final class ReportQuestionInProgress extends ReportQuestionState {
  const ReportQuestionInProgress();
}

final class ReportQuestionSuccess extends ReportQuestionState {
  const ReportQuestionSuccess();
}

final class ReportQuestionFailure extends ReportQuestionState {
  const ReportQuestionFailure(this.errorMessageCode);

  final String errorMessageCode;
}

final class ReportQuestionCubit extends Cubit<ReportQuestionState> {
  ReportQuestionCubit(this.reportQuestionRepository)
    : super(const ReportQuestionInitial());

  ReportQuestionRepository reportQuestionRepository;

  void reportQuestion({
    required QuizTypes quizType,
    required String questionId,
    required String message,
  }) {
    emit(const ReportQuestionInProgress());
    reportQuestionRepository
        .reportQuestion(
          quizType: quizType,
          message: message,
          questionId: questionId,
        )
        .then((value) {
          emit(const ReportQuestionSuccess());
        })
        .catchError((Object e) {
          emit(ReportQuestionFailure(e.toString()));
        });
  }
}
