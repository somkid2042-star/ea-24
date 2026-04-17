import 'package:ea24_mobile/helpers/main_helpers.dart';
import 'package:ea24_mobile/middlewares/route_middleware.dart';
import 'package:ea24_mobile/screens/auth/login.dart';
import 'package:flutter/cupertino.dart';

class AuthMiddleware extends RouteMiddleware {
  final Widget _goto;

  AuthMiddleware(this._goto);

  @override
  Widget next() {
    if (!userIsLogedIn) {
      return Login();
    }
    return _goto;
  }
}
