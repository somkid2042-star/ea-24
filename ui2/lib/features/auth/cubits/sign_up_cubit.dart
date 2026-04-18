import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/auth/auth_repository.dart';
import 'package:flutterquiz/features/auth/models/auth_providers_enum.dart';

sealed class SignUpState {
  const SignUpState();
}

final class SignUpInitial extends SignUpState {
  const SignUpInitial();
}

final class SignUpProgress extends SignUpState {
  const SignUpProgress(this.authProvider);

  final AuthProviders authProvider;
}

final class SignUpSuccess extends SignUpState {
  const SignUpSuccess();
}

final class SignUpFailure extends SignUpState {
  const SignUpFailure(this.errorMessage, this.authProvider);

  final String errorMessage;
  final AuthProviders authProvider;
}

final class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit(this._authRepository) : super(const SignUpInitial());

  final AuthRepository _authRepository;

  void signUpUser(AuthProviders authProvider, String email, String password) {
    emit(SignUpProgress(authProvider));
    _authRepository
        .signUpUser(email, password)
        .then((_) => emit(const SignUpSuccess()))
        .catchError(
          (Object? e) => emit(SignUpFailure(e.toString(), authProvider)),
        );
  }
}
