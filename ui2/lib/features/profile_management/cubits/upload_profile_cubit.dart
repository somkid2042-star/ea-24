import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/profile_management/profile_management_repository.dart';

sealed class UploadProfileState {
  const UploadProfileState();
}

final class UploadProfileInitial extends UploadProfileState {
  const UploadProfileInitial();
}

final class UploadProfileInProgress extends UploadProfileState {
  const UploadProfileInProgress();
}

final class UploadProfileSuccess extends UploadProfileState {
  const UploadProfileSuccess(this.imageUrl);

  final String imageUrl;
}

final class UploadProfileFailure extends UploadProfileState {
  const UploadProfileFailure(this.errorMessage);

  final String errorMessage;
}

final class UploadProfileCubit extends Cubit<UploadProfileState> {
  UploadProfileCubit(this._profileManagementRepository)
    : super(const UploadProfileInitial());

  final ProfileManagementRepository _profileManagementRepository;

  Future<void> uploadProfilePicture(File? file) async {
    emit(const UploadProfileInProgress());

    await _profileManagementRepository
        .uploadProfilePicture(file)
        .then((imageUrl) => emit(UploadProfileSuccess(imageUrl)))
        .catchError((Object? e) => emit(UploadProfileFailure(e.toString())));
  }
}
