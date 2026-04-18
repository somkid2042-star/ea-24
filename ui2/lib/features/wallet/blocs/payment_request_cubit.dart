import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/wallet/repos/wallet_repository.dart';

sealed class PaymentRequestState {
  const PaymentRequestState();
}

final class PaymentRequestInitial extends PaymentRequestState {
  const PaymentRequestInitial();
}

final class PaymentRequestInProgress extends PaymentRequestState {
  const PaymentRequestInProgress();
}

final class PaymentRequestSuccess extends PaymentRequestState {
  const PaymentRequestSuccess();
}

final class PaymentRequestFailure extends PaymentRequestState {
  const PaymentRequestFailure(this.errorMessage);

  final String errorMessage;
}

final class PaymentRequestCubit extends Cubit<PaymentRequestState> {
  PaymentRequestCubit(this._walletRepository)
    : super(const PaymentRequestInitial());

  final WalletRepository _walletRepository;

  Future<void> makePaymentRequest({
    required String paymentType,
    required String paymentAddress,
    required String paymentAmount,
    required String coinUsed,
    required String details,
  }) async {
    try {
      emit(const PaymentRequestInProgress());
      await _walletRepository.makePaymentRequest(
        paymentType: paymentType,
        paymentAddress: paymentAddress,
        paymentAmount: paymentAmount,
        coinUsed: coinUsed,
        details: details,
      );
      emit(const PaymentRequestSuccess());
    } on Exception catch (e) {
      emit(PaymentRequestFailure(e.toString()));
    }
  }

  void reset() => emit(const PaymentRequestInitial());
}
