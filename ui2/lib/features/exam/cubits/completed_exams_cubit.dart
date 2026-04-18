import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/exam/exam_repository.dart';
import 'package:flutterquiz/features/exam/models/exam_result.dart';

sealed class CompletedExamsState {
  const CompletedExamsState();
}

final class CompletedExamsInitial extends CompletedExamsState {
  const CompletedExamsInitial();
}

final class CompletedExamsFetchInProgress extends CompletedExamsState {
  const CompletedExamsFetchInProgress();
}

final class CompletedExamsFetchSuccess extends CompletedExamsState {
  const CompletedExamsFetchSuccess({
    required this.completedExams,
    required this.totalResultCount,
    required this.hasMoreFetchError,
    required this.hasMore,
  });

  final List<ExamResult> completedExams;
  final int totalResultCount;
  final bool hasMoreFetchError;
  final bool hasMore;
}

final class CompletedExamsFetchFailure extends CompletedExamsState {
  const CompletedExamsFetchFailure(this.errorMessage);

  final String errorMessage;
}

final class CompletedExamsCubit extends Cubit<CompletedExamsState> {
  CompletedExamsCubit(this._examRepository)
    : super(const CompletedExamsInitial());

  final ExamRepository _examRepository;

  final int limit = 15;

  Future<void> getCompletedExams({required String languageId}) async {
    try {
      //
      final (:total, :data) = await _examRepository.getCompletedExams(
        languageId: languageId,
        limit: limit.toString(),
        offset: '0',
      );

      emit(
        CompletedExamsFetchSuccess(
          completedExams: data,
          totalResultCount: total,
          hasMoreFetchError: false,
          hasMore: data.length < total,
        ),
      );
    } on Exception catch (e) {
      emit(CompletedExamsFetchFailure(e.toString()));
    }
  }

  bool hasMoreResult() {
    if (state is CompletedExamsFetchSuccess) {
      return (state as CompletedExamsFetchSuccess).hasMore;
    }
    return false;
  }

  Future<void> getMoreResult({required String languageId}) async {
    if (state is CompletedExamsFetchSuccess) {
      try {
        //
        final (:total, :data) = await _examRepository.getCompletedExams(
          languageId: languageId,
          limit: limit.toString(),
          offset: (state as CompletedExamsFetchSuccess).completedExams.length
              .toString(),
        );
        final updatedResults =
            (state as CompletedExamsFetchSuccess).completedExams..addAll(data);

        emit(
          CompletedExamsFetchSuccess(
            completedExams: updatedResults,
            totalResultCount: total,
            hasMoreFetchError: false,
            hasMore: updatedResults.length < total,
          ),
        );
        //
      } on Exception catch (_) {
        //in case of any error
        emit(
          CompletedExamsFetchSuccess(
            completedExams:
                (state as CompletedExamsFetchSuccess).completedExams,
            hasMoreFetchError: true,
            totalResultCount:
                (state as CompletedExamsFetchSuccess).totalResultCount,
            hasMore: (state as CompletedExamsFetchSuccess).hasMore,
          ),
        );
      }
    }
  }
}
