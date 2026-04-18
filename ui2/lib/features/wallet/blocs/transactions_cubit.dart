import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/wallet/models/payment_request.dart';
import 'package:flutterquiz/features/wallet/repos/wallet_repository.dart';

sealed class TransactionsState {
  const TransactionsState();
}

final class TransactionsFetchInitial extends TransactionsState {
  const TransactionsFetchInitial();
}

final class TransactionsFetchInProgress extends TransactionsState {
  const TransactionsFetchInProgress();
}

final class TransactionsFetchSuccess extends TransactionsState {
  const TransactionsFetchSuccess({
    required this.paymentRequests,
    required this.totalTransactionsCount,
    required this.hasMoreFetchError,
    required this.hasMore,
  });

  final List<PaymentRequest> paymentRequests;
  final int totalTransactionsCount;
  final bool hasMoreFetchError;
  final bool hasMore;
}

final class TransactionsFetchFailure extends TransactionsState {
  const TransactionsFetchFailure(this.errorMessage);

  final String errorMessage;
}

class TransactionsCubit extends Cubit<TransactionsState> {
  TransactionsCubit(this._walletRepository)
    : super(const TransactionsFetchInitial());

  final WalletRepository _walletRepository;

  final int limit = 15;

  Future<void> getTransactions() async {
    try {
      final (:total, :data) = await _walletRepository.getTransactions(
        limit: limit.toString(),
        offset: '0',
      );

      if (isClosed) return;

      emit(
        TransactionsFetchSuccess(
          paymentRequests: data,
          totalTransactionsCount: total,
          hasMoreFetchError: false,
          hasMore: data.length < total,
        ),
      );
    } on Exception catch (e) {
      if (isClosed) return;

      emit(TransactionsFetchFailure(e.toString()));
    }
  }

  bool hasMoreTransactions() =>
      (state is TransactionsFetchSuccess) &&
      (state as TransactionsFetchSuccess).hasMore;

  Future<void> getMoreTransactions() async {
    if (state is TransactionsFetchSuccess) {
      final successState = state as TransactionsFetchSuccess;

      try {
        //
        final (:total, :data) = await _walletRepository.getTransactions(
          limit: limit.toString(),
          offset: successState.paymentRequests.length.toString(),
        );

        final updatedResults = successState.paymentRequests..addAll(data);

        emit(
          TransactionsFetchSuccess(
            paymentRequests: updatedResults,
            totalTransactionsCount: total,
            hasMoreFetchError: false,
            hasMore: updatedResults.length < total,
          ),
        );
        //
      } on Exception catch (_) {
        //in case of any error
        emit(
          TransactionsFetchSuccess(
            paymentRequests: successState.paymentRequests,
            hasMoreFetchError: true,
            totalTransactionsCount: successState.totalTransactionsCount,
            hasMore: successState.hasMore,
          ),
        );
      }
    }
  }

  double calculateTotalEarnings() {
    if (state is TransactionsFetchSuccess) {
      final successfulRequests = (state as TransactionsFetchSuccess)
          .paymentRequests
          .where((element) => element.status == '1');
      var totalEarnings = 0.0;

      for (final element in successfulRequests) {
        totalEarnings = totalEarnings + double.parse(element.paymentAmount);
      }
      return totalEarnings;
    }
    return 0;
  }
}
