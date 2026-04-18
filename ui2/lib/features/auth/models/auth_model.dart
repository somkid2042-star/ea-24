import 'package:flutterquiz/features/auth/models/auth_providers_enum.dart';

final class AuthModel {
  const AuthModel({
    required this.jwtToken,
    required this.firebaseId,
    required this.authProvider,
    required this.isNewUser,
  });

  AuthModel.fromJson(Map<String, dynamic> json)
    : jwtToken = json['jwtToken'] as String,
      firebaseId = json['firebaseId'] as String,
      authProvider = AuthProviders.fromString(json['authProvider'].toString()),
      isNewUser = false;

  final AuthProviders authProvider;
  final String firebaseId;
  final String jwtToken;
  final bool isNewUser;
}
