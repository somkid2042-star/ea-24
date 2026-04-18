import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/statistic/models/statistic_model.dart';
import 'package:flutterquiz/features/statistic/statistic_repository.dart';

sealed class StatisticState {
  const StatisticState();
}

final class StatisticInitial extends StatisticState {
  const StatisticInitial();
}

final class StatisticFetchInProgress extends StatisticState {
  const StatisticFetchInProgress();
}

final class StatisticFetchSuccess extends StatisticState {
  const StatisticFetchSuccess(this.statisticModel);

  final StatisticModel statisticModel;
}

final class StatisticFetchFailure extends StatisticState {
  const StatisticFetchFailure(this.errorMessageCode);

  final String errorMessageCode;
}

final class StatisticCubit extends Cubit<StatisticState> {
  StatisticCubit(this._statisticRepository) : super(const StatisticInitial());

  final StatisticRepository _statisticRepository;

  Future<void> getStatistic() async {
    emit(const StatisticFetchInProgress());
    try {
      final result = await _statisticRepository.getStatistic(
        getBattleStatistics: false,
      );

      emit(StatisticFetchSuccess(result));
    } on Exception catch (e) {
      emit(StatisticFetchFailure(e.toString()));
    }
  }

  Future<void> getStatisticWithBattle() async {
    emit(const StatisticFetchInProgress());
    try {
      final result = await _statisticRepository.getStatistic(
        getBattleStatistics: true,
      );
      emit(StatisticFetchSuccess(result));
    } on Exception catch (e) {
      emit(StatisticFetchFailure(e.toString()));
    }
  }

  StatisticModel getStatisticsDetails() {
    if (state is StatisticFetchSuccess) {
      return (state as StatisticFetchSuccess).statisticModel;
    }
    return StatisticModel.fromJson({}, {});
  }
}
