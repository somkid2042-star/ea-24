import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/profile_management/profile_management_repository.dart';

sealed class UpdateUserDetailState {
  const UpdateUserDetailState();
}

final class UpdateUserDetailInitial extends UpdateUserDetailState {
  const UpdateUserDetailInitial();
}

final class UpdateUserDetailInProgress extends UpdateUserDetailState {
  const UpdateUserDetailInProgress();
}

final class UpdateUserDetailSuccess extends UpdateUserDetailState {
  const UpdateUserDetailSuccess();
}

final class UpdateUserDetailFailure extends UpdateUserDetailState {
  const UpdateUserDetailFailure(this.errorMessage);

  final String errorMessage;
}

final class UpdateUserDetailCubit extends Cubit<UpdateUserDetailState> {
  UpdateUserDetailCubit(this._profileManagementRepository)
    : super(const UpdateUserDetailInitial());

  final ProfileManagementRepository _profileManagementRepository;

  Future<void> updateProfile({
    required String email,
    required String name,
    required String mobile,
  }) async {
    emit(const UpdateUserDetailInProgress());

    await _profileManagementRepository
        .updateProfile(email: email, mobile: mobile, name: name)
        .then((_) => emit(const UpdateUserDetailSuccess()))
        .catchError((Object e) => emit(UpdateUserDetailFailure(e.toString())));
  }
}
