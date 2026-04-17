import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;
import 'dart:math' hide log;
import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/input_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/custom/intl_phone_input.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/auth_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/other_config.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/auth_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/profile_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/auth/password_forget.dart';
import 'package:active_ecommerce_cms_demo_app/screens/auth/registration.dart';
import 'package:active_ecommerce_cms_demo_app/screens/main.dart';
import 'package:active_ecommerce_cms_demo_app/ui_elements/auth_ui.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../custom/loading.dart';
import '../../repositories/address_repository.dart';
import 'otp.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String _loginBy = "email"; //phone or email
  String initialCountry = 'US';
  var countriesCode = <String?>[];
  String? _phone = "";

  // reCAPTCHA v3 setup
  late final WebViewController _controller;
  final String _recaptchaUrl = "${AppConfig.BASE_URL}/google-recaptcha";
  String googleRecaptchaKey = "";

  //controllers
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    fetchCountry();
    if (recaptcha_customer_login.$) {
      _setupWebViewController();
    }
  }

  void _setupWebViewController() {
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
    WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'Captcha',
        onMessageReceived: (JavaScriptMessage message) {
          if (!mounted) return;

          if (message.message.isNotEmpty && message.message != "error") {
            log("reCAPTCHA token received");
            setState(() {
              googleRecaptchaKey = message.message;
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            log('WebView loaded: $url');
          },
          onWebResourceError: (error) {
            ToastComponent.showDialog(
              "Verification failed,please try again",
            );
          },
          onNavigationRequest: (request) {
            if (request.url == _recaptchaUrl) {
              return NavigationDecision.navigate;
            } else {
              _launchUrl(request.url);
              return NavigationDecision.prevent;
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_recaptchaUrl));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
  }


  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      log('Could not launch $url');
    }
  }

  fetchCountry() async {
    var data = await AddressRepository().getCountryList();
    data.countries.forEach((c) => countriesCode.add(c.code));
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    super.dispose();
  }

  onPressedLogin(ctx) async {
    FocusScope.of(context).unfocus();
    Loading.show(context);
    var email = _emailController.text.toString();
    var password = _passwordController.text.toString();

    if (_loginBy == 'email' && email.isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_email);
      Loading.close();
      return;
    } else if (_loginBy == 'phone' && _phone!.isEmpty) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_phone_number,
      );
      Loading.close();
      return;
    } else if (password.isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_password);
      Loading.close();
      return;
    }

    var loginResponse = await AuthRepository().getLoginResponse(
      _loginBy == 'email' ? email : _phone,
      password,
      _loginBy,
      googleRecaptchaKey,
    );
    Loading.close();

    temp_user_id.$ = "";
    temp_user_id.save();

    if (loginResponse.result == false) {
      if (loginResponse.message is List) {
        ToastComponent.showDialog(loginResponse.message!.join("\n"));
      } else {
        ToastComponent.showDialog(loginResponse.message!.toString());
      }
    } else {
      ToastComponent.showDialog(loginResponse.message!);
      AuthHelper().setUserData(loginResponse);

      if (OtherConfig.USE_PUSH_NOTIFICATION) {
        final FirebaseMessaging fcm = FirebaseMessaging.instance;
        await fcm.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        String? fcmToken = await fcm.getToken();
        if (fcmToken != null && is_logged_in.$) {
          await ProfileRepository().getDeviceTokenUpdateResponse(fcmToken);
        }
      }

      if (loginResponse.user!.emailVerified!) {
        if (!mounted) return;
        context.go("/");
      } else {
        if ((mail_verification_status.$ && _loginBy == "email") ||
            (mail_verification_status.$ && _loginBy == "phone")) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Otp()),
          );
        } else {
          if (!mounted) return;
          context.go("/");
        }
      }
    }
  }

  onPressedFacebookLogin() async {
    try {
      final facebookLogin = await FacebookAuth.instance.login(
        loginBehavior: LoginBehavior.webOnly,
      );

      if (facebookLogin.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        var loginResponse = await AuthRepository().getSocialLoginResponse(
          "facebook",
          userData['name'].toString(),
          userData['email'].toString(),
          userData['id'].toString(),
          accessToken: facebookLogin.accessToken!.tokenString,
        );
        if (!mounted) return;
        if (loginResponse.result == false) {
          ToastComponent.showDialog(loginResponse.message!);
        } else {
          ToastComponent.showDialog(loginResponse.message!);

          AuthHelper().setUserData(loginResponse);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) {
                return Main();
              },
            ),
            (route) => false,
          );
          FacebookAuth.instance.logOut();
        }
      } else {
        log("Facebook auth Failed.");
      }
    } on Exception catch (e) {
      log("Facebook login error: $e");
    }
  }

  onPressedGoogleLogin() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        log("Google sign in was cancelled.");
        return;
      }

      GoogleSignInAuthentication googleSignInAuthentication =
          await googleUser.authentication;
      String? accessToken = googleSignInAuthentication.accessToken;

      var loginResponse = await AuthRepository().getSocialLoginResponse(
        "google",
        googleUser.displayName,
        googleUser.email,
        googleUser.id,
        accessToken: accessToken,
      );
      if (!mounted) return;
      if (loginResponse.result == false) {
        ToastComponent.showDialog(loginResponse.message!);
      } else {
        ToastComponent.showDialog(loginResponse.message!);
        AuthHelper().setUserData(loginResponse);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) {
              return Main();
            },
          ),
          (route) => false,
        );
      }
    } on Exception catch (e) {
      log("Google login error: $e");
    } finally {
      if (await GoogleSignIn().isSignedIn()) {
        GoogleSignIn().disconnect();
      }
    }
  }

  String generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  signInWithApple() async {
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      var loginResponse = await AuthRepository().getSocialLoginResponse(
        "apple",
        appleCredential.givenName,
        appleCredential.email,
        appleCredential.userIdentifier,
        accessToken: appleCredential.identityToken,
      );
      if (!mounted) return;
      if (loginResponse.result == false) {
        ToastComponent.showDialog(loginResponse.message!);
      } else {
        ToastComponent.showDialog(loginResponse.message!);
        AuthHelper().setUserData(loginResponse);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) {
              return Main();
            },
          ),
          (route) => false,
        );
      }
    } on Exception catch (e) {
      log("Apple sign in error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        AuthScreen.buildScreen(
          context,
          "${AppLocalizations.of(context)!.login_to} ${AppConfig.app_name}",
          buildBody(context, screenWidth),
        ),
        if (recaptcha_customer_login.$)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: SizedBox(
              width: 250,
              height: 80,
              child: WebViewWidget(controller: _controller),
            ),
          ),
      ],
    );
  }

  Widget buildBody(BuildContext context, double screenWidth) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: min(screenWidth * 0.8, 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        _loginBy == "email"
                            ? AppLocalizations.of(context)!.email_ucf
                            : AppLocalizations.of(context)!.login_screen_phone,
                        style: TextStyle(
                          color: MyTheme.accent_color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_loginBy == "email")
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 36,
                              child: TextField(
                                controller: _emailController,
                                autofocus: false,
                                decoration:
                                    InputDecorations.buildInputDecoration_1(
                                      hintText: "johndoe@example.com",
                                    ),
                              ),
                            ),
                            if (otp_addon_installed.$)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _loginBy = "phone";
                                  });
                                },
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.or_login_with_a_phone,
                                  style: TextStyle(
                                    color: MyTheme.accent_color,
                                    fontStyle: FontStyle.italic,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 36,
                              child: CustomInternationalPhoneNumberInput(
                                countries: countriesCode,
                                onInputChanged: (PhoneNumber number) {
                                  setState(() {
                                    _phone = number.phoneNumber;
                                  });
                                },
                                onInputValidated: (bool value) {},
                                selectorConfig: SelectorConfig(
                                  selectorType: PhoneInputSelectorType.DIALOG,
                                ),
                                ignoreBlank: false,
                                autoValidateMode: AutovalidateMode.disabled,
                                selectorTextStyle: TextStyle(
                                  color: MyTheme.font_grey,
                                ),
                                textStyle: TextStyle(color: MyTheme.font_grey),
                                textFieldController: _phoneNumberController,
                                formatInput: true,
                                keyboardType: TextInputType.numberWithOptions(
                                  signed: true,
                                  decimal: true,
                                ),
                                inputDecoration:
                                    InputDecorations.buildInputDecorationPhone(
                                      hintText: "01XXX XXX XXX",
                                    ),
                                onSaved: (PhoneNumber number) {},
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _loginBy = "email";
                                });
                              },
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.or_login_with_an_email,
                                style: TextStyle(
                                  color: MyTheme.accent_color,
                                  fontStyle: FontStyle.italic,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        AppLocalizations.of(context)!.password_ucf,
                        style: TextStyle(
                          color: MyTheme.accent_color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 36,
                            child: TextField(
                              controller: _passwordController,
                              autofocus: false,
                              obscureText: true,
                              enableSuggestions: false,
                              autocorrect: false,
                              decoration:
                                  InputDecorations.buildInputDecoration_1(
                                    hintText: "• • • • • • • •",
                                  ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return PasswordForget();
                                  },
                                ),
                              );
                            },
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.login_screen_forgot_password,
                              style: TextStyle(
                                color: MyTheme.accent_color,
                                fontStyle: FontStyle.italic,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 30.0),
                      child: SizedBox(
                        height: 45,
                        child: Btn.minWidthFixHeight(
                          minWidth: double.infinity,
                          height: 50,
                          color: MyTheme.accent_color,
                          shape: RoundedRectangleBorder(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(6.0),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.login_screen_log_in,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () => onPressedLogin(context),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.login_screen_or_create_new_account,
                            style: TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 10),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return Registration();
                                  },
                                ),
                              );
                            },
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.login_screen_sign_up,
                              style: TextStyle(
                                color: MyTheme.accent_color,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (allow_google_login.$ ||
                        allow_facebook_login.$ ||
                        Platform.isIOS)
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.login_screen_login_with,
                            style: TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (allow_google_login.$)
                              InkWell(
                                onTap: () {
                                  onPressedGoogleLogin();
                                },
                                child: SizedBox(
                                  width: 28,
                                  child: Image.asset("assets/google_logo.png"),
                                ),
                              ),
                            if (allow_facebook_login.$) SizedBox(width: 15),
                            if (allow_facebook_login.$)
                              InkWell(
                                onTap: () {
                                  onPressedFacebookLogin();
                                },
                                child: SizedBox(
                                  width: 28,
                                  child: Image.asset(
                                    "assets/facebook_logo.png",
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
