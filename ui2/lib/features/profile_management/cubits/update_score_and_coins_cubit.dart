import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/profile_management/profile_management_repository.dart';

sealed class UpdateCoinsState {
  const UpdateCoinsState();
}

final class UpdateCoinsInitial extends UpdateCoinsState {
  const UpdateCoinsInitial();
}

final class UpdateCoinsInProgress extends UpdateCoinsState {
  const UpdateCoinsInProgress();
}

final class UpdateCoinsSuccess extends UpdateCoinsState {
  const UpdateCoinsSuccess({this.coins, this.score});

  final String? score;
  final String? coins;
}

final class UpdateCoinsFailure extends UpdateCoinsState {
  const UpdateCoinsFailure(this.errorMessage);

  final String errorMessage;
}

final class UpdateCoinsCubit extends Cubit<UpdateCoinsState> {
  UpdateCoinsCubit(this._profileManagementRepository)
    : super(const UpdateCoinsInitial());

  final ProfileManagementRepository _profileManagementRepository;

  Future<void> updateCoins({
    required String title,
    required bool addCoin,
    int? coins,
    String? type,
  }) async {
    emit(const UpdateCoinsInProgress());

    await _profileManagementRepository
        .updateCoins(coins: coins, addCoin: addCoin, type: type, title: title)
        .then((result) {
          if (!isClosed) {
            emit(
              UpdateCoinsSuccess(
                coins: result.coins,
                score: result.score,
              ),
            );
          }
        })
        .catchError((Object e) {
          if (!isClosed) {
            emit(UpdateCoinsFailure(e.toString()));
          }
        });
  }
}
