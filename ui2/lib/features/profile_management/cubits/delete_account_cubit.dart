import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/profile_management/profile_management_repository.dart';

sealed class DeleteAccountState {
  const DeleteAccountState();
}

final class DeleteAccountInitial extends DeleteAccountState {
  const DeleteAccountInitial();
}

final class DeleteAccountInProgress extends DeleteAccountState {
  const DeleteAccountInProgress();
}

final class DeleteAccountSuccess extends DeleteAccountState {
  const DeleteAccountSuccess();
}

final class DeleteAccountFailure extends DeleteAccountState {
  const DeleteAccountFailure(this.errorMessage);

  final String errorMessage;
}

final class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  DeleteAccountCubit(this._profileManagementRepository)
    : super(const DeleteAccountInitial());

  final ProfileManagementRepository _profileManagementRepository;

  void deleteUserAccount() {
    emit(const DeleteAccountInProgress());
    _profileManagementRepository
        .deleteAccount()
        .then((_) => emit(const DeleteAccountSuccess()))
        .catchError((Object e) => emit(DeleteAccountFailure(e.toString())));
  }
}
