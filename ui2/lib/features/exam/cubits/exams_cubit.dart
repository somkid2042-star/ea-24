import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/exam/exam_repository.dart';
import 'package:flutterquiz/features/exam/models/exam.dart';

sealed class ExamsState {
  const ExamsState();
}

final class ExamsInitial extends ExamsState {
  const ExamsInitial();
}

final class ExamsFetchInProgress extends ExamsState {
  const ExamsFetchInProgress();
}

final class ExamsFetchSuccess extends ExamsState {
  const ExamsFetchSuccess(this.exams);

  final List<Exam> exams;
}

final class ExamsFetchFailure extends ExamsState {
  const ExamsFetchFailure(this.errorMessage);

  final String errorMessage;
}

final class ExamsCubit extends Cubit<ExamsState> {
  ExamsCubit(this._examRepository) : super(const ExamsInitial());

  final ExamRepository _examRepository;

  Future<void> getExams({required String languageId}) async {
    emit(const ExamsFetchInProgress());
    try {
      //today's all exam but unattempted
      //(status: 1-Not in Exam, 2-In exam, 3-Completed)
      final exams = (await _examRepository.getExams(
        languageId: languageId,
      )).where((e) => e.examStatus == '1').toList();

      emit(ExamsFetchSuccess(exams));
    } on Exception catch (e) {
      emit(ExamsFetchFailure(e.toString()));
    }
  }
}
