import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/auth/auth_repository.dart';
import 'package:flutterquiz/features/auth/models/auth_providers_enum.dart';
import 'package:flutterquiz/features/profile_management/models/user_profile.dart';

sealed class ReferAndEarnState {
  const ReferAndEarnState();
}

final class ReferAndEarnInitial extends ReferAndEarnState {
  const ReferAndEarnInitial();
}

final class ReferAndEarnProgress extends ReferAndEarnState {
  const ReferAndEarnProgress();
}

final class ReferAndEarnSuccess extends ReferAndEarnState {
  const ReferAndEarnSuccess({required this.userProfile});

  final UserProfile userProfile;
}

final class ReferAndEarnFailure extends ReferAndEarnState {
  const ReferAndEarnFailure(this.errorMessage);

  final String errorMessage;
}

class ReferAndEarnCubit extends Cubit<ReferAndEarnState> {
  ReferAndEarnCubit(this._authRepository) : super(const ReferAndEarnInitial());
  final AuthRepository _authRepository;

  void getReward({
    required UserProfile userProfile,
    required String name,
    required String friendReferralCode,
    required AuthProviders authType,
    String? appLanguage,
  }) {
    //emitting signInProgress state
    emit(const ReferAndEarnProgress());

    //signIn user with given provider and also add user details in api
    _authRepository
        .addUserData(
          email: userProfile.email,
          firebaseId: userProfile.firebaseId!,
          friendCode: friendReferralCode,
          mobile: userProfile.mobileNumber,
          name: name,
          type: authType.name,
          profile: userProfile.profileUrl,
          appLanguage: appLanguage,
        )
        .then((result) {
          emit(ReferAndEarnSuccess(userProfile: UserProfile.fromJson(result)));
        })
        .catchError((dynamic e) {
          /// FIXME: closed before emit issue in some case.
          emit(ReferAndEarnFailure(e.toString()));
        });
  }
}
