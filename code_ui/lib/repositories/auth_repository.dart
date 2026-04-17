import 'dart:convert';

import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/common_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/confirm_code_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/login_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/logout_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/password_confirm_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/password_forget_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/resend_code_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/api-request.dart';

class AuthRepository {
  Future<LoginResponse> getLoginResponse(
    String? email,
    String password,
    String loginBy,
    String capchaKey,
  ) async {
    var postBody = jsonEncode({
      "email": "$email",
      "password": password,
      "identity_matrix": AppConfig.purchase_code,
      "login_by": loginBy,
      "temp_user_id": temp_user_id.$,
      "g-recaptcha-response": capchaKey,
      "recaptcha_action": "recaptcha_customer_login",
    });

    String url = ("${AppConfig.BASE_URL}/auth/login");
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Accept": "*/*",
        "Content-Type": "application/json",
        "App-Language": app_language.$!,
      },
      body: postBody,
    );
    return loginResponseFromJson(response.body);
  }

  Future<LoginResponse> getSocialLoginResponse(
    String socialProvider,
    String? name,
    String? email,
    String? provider, {
    accessToken = "",
    secretToken = "",
  }) async {
    email = email == ("null") ? "" : email;

    var postBody = jsonEncode({
      "name": name,
      "email": email,
      "provider": "$provider",
      "social_provider": socialProvider,
      "access_token": "$accessToken",
      "secret_token": "$secretToken",
    });

    String url = ("${AppConfig.BASE_URL}/auth/social-login");
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "App-Language": app_language.$!,
      },
      body: postBody,
    );
    return loginResponseFromJson(response.body);
  }

  Future<LogoutResponse> getLogoutResponse() async {
    String url = ("${AppConfig.BASE_URL}/auth/logout");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
    );

    return logoutResponseFromJson(response.body);
  }

  Future<CommonResponse> getAccountDeleteResponse() async {
    String url = ("${AppConfig.BASE_URL}/auth/account-deletion");

    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$!,
      },
    );
    return commonResponseFromJson(response.body);
  }

  Future<LoginResponse> getSignupResponse(
    String name,
    String? emailOrPhone,
    String password,
    String passowrdConfirmation,
    String registerBy,
    String capchaKey,
  ) async {
    var postBody = jsonEncode({
      "name": name,
      "email_or_phone": "$emailOrPhone",
      "password": password,
      "password_confirmation": passowrdConfirmation,
      "register_by": registerBy,
      "g-recaptcha-response": capchaKey,
      "recaptcha_action": "recaptcha_customer_register",
    });

    String url = ("${AppConfig.BASE_URL}/auth/signup");
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "App-Language": app_language.$!,
      },
      body: postBody,
    );

    return loginResponseFromJson(response.body);
  }

  Future<ResendCodeResponse> getResendCodeResponse() async {
    String url = ("${AppConfig.BASE_URL}/auth/resend_code");
    final response = await ApiRequest.get(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "App-Language": app_language.$!,
        "Authorization": "Bearer ${access_token.$}",
      },
    );
    return resendCodeResponseFromJson(response.body);
  }

  Future<ConfirmCodeResponse> getConfirmCodeResponse(
    String verificationCode,
  ) async {
    var postBody = jsonEncode({"verification_code": verificationCode});

    String url = ("${AppConfig.BASE_URL}/auth/confirm_code");
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "App-Language": app_language.$!,
        "Authorization": "Bearer ${access_token.$}",
      },
      body: postBody,
    );

    return confirmCodeResponseFromJson(response.body);
  }

  Future<PasswordForgetResponse> getPasswordForgetResponse(
    String? emailOrPhone,
    String sendCodeBy,
    String capchaKey,
  ) async {
    var postBody = jsonEncode({
      "email_or_phone": "$emailOrPhone",
      "send_code_by": sendCodeBy,
      "g-recaptcha-response": capchaKey,
      "recaptcha_action": "recaptcha_forgot_password",
    });

    String url = ("${AppConfig.BASE_URL}/auth/password/forget_request");

    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "App-Language": app_language.$!,
      },
      body: postBody,
    );

    return passwordForgetResponseFromJson(response.body);
  }

  Future<PasswordConfirmResponse> getPasswordConfirmResponse(
    String verificationCode,
    String password,
  ) async {
    var postBody = jsonEncode({
      "verification_code": verificationCode,
      "password": password,
    });

    String url = ("${AppConfig.BASE_URL}/auth/password/confirm_reset");
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "App-Language": app_language.$!,
      },
      body: postBody,
    );

    return passwordConfirmResponseFromJson(response.body);
  }

  Future<ResendCodeResponse> getPasswordResendCodeResponse(
    String? emailOrCode,
    String verifyBy,
  ) async {
    var postBody = jsonEncode({
      "email_or_code": "$emailOrCode",
      "verify_by": verifyBy,
    });

    String url = ("${AppConfig.BASE_URL}/auth/password/resend_code");
    final response = await ApiRequest.post(
      url: url,
      headers: {
        "Content-Type": "application/json",
        "App-Language": app_language.$!,
      },
      body: postBody,
    );

    return resendCodeResponseFromJson(response.body);
  }

  Future<LoginResponse> getUserByTokenResponse() async {
    var postBody = jsonEncode({"access_token": "${access_token.$}"});

    String url = ("${AppConfig.BASE_URL}/auth/info");
    if (access_token.$!.isNotEmpty) {
      final response = await ApiRequest.post(
        url: url,
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
        },
        body: postBody,
      );

      return loginResponseFromJson(response.body);
    }
    return LoginResponse();
  }
}
