import 'dart:developer';
import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/input_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/custom/intl_phone_input.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/other_config.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/auth_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/profile_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/common_webview_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/home.dart';
import 'package:active_ecommerce_cms_demo_app/ui_elements/auth_ui.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:validators/validators.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../custom/loading.dart';
import '../../helpers/auth_helper.dart';
import '../../repositories/address_repository.dart';
import 'otp.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  String _registerBy = "email";
  String initialCountry = 'US';
  var countriesCode = <String?>[];

  // reCAPTCHA v3 setup
  late WebViewController _controller;
  bool _isWebViewReady = false;
  final String _recaptchaUrl = "${AppConfig.BASE_URL}/google-recaptcha";
  String googleRecaptchaKey = "";

  String? _phone = "";
  bool? _isAgree = false;

  //controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    super.initState();
    fetchCountry();
    if (recaptcha_customer_register.$) {
      _setupWebViewController();
    }
  }

  void _setupWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            log('WebView loading: $progress%');
          },
          onPageStarted: (String url) {
            log('WebView page started: $url');
            if (mounted) {
              setState(() {
                _isWebViewReady = false;
              });
            }
          },
          onPageFinished: (String url) async {
            log('WebView page finished loading: $url');

            // Inject JavaScript to handle reCAPTCHA
            await _controller.runJavaScript('''
              // Listen for reCAPTCHA token
              function onRecaptchaSuccess(token) {
                Captcha.postMessage(token);
              }
              
              // Check if reCAPTCHA is loaded and trigger if needed
              if (typeof grecaptcha !== 'undefined') {
                console.log('reCAPTCHA is available');
              } else {
                console.log('reCAPTCHA not available');
              }
              
              // Listen for messages from the app
              window.addEventListener('message', function(event) {
                if (event.data.type === 'GET_RECAPTCHA_TOKEN') {
                  if (typeof grecaptcha !== 'undefined' && typeof grecaptcha.execute !== 'undefined') {
                    grecaptcha.execute();
                  }
                }
              });
            ''');

            if (mounted) {
              setState(() {
                _isWebViewReady = true;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            log('''
WebView Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
''');
            if (mounted) {
              setState(() {
                _isWebViewReady = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url == _recaptchaUrl ||
                request.url.contains('google.com/recaptcha')) {
              return NavigationDecision.navigate;
            } else if (request.url.startsWith('http')) {
              _launchUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Captcha',
        onMessageReceived: (JavaScriptMessage message) {
          log("reCAPTCHA v3 Token Received: '${message.message}'");

          if (mounted &&
              message.message.isNotEmpty &&
              message.message != "error") {
            setState(() {
              googleRecaptchaKey = message.message;
              log(
                "reCAPTCHA key has been SET successfully: ${googleRecaptchaKey.substring(0, 20)}...",
              );
            });
          } else {
            log("reCAPTCHA key was EMPTY or an ERROR.");
            // Retry getting reCAPTCHA token
            _getRecaptchaToken();
          }
        },
      );

    _loadWebView();
  }

  void _loadWebView() async {
    try {
      setState(() {});
      await _controller.loadRequest(Uri.parse(_recaptchaUrl));
    } catch (e) {
      log('Error loading WebView: $e');
      if (mounted) {
        setState(() {
          _isWebViewReady = false;
        });
      }
    }
  }

  void _getRecaptchaToken() async {
    if (!_isWebViewReady) {
      log('WebView not ready yet');
      return;
    }

    try {
      await _controller.runJavaScript('''
        if (typeof grecaptcha !== 'undefined' && typeof grecaptcha.execute !== 'undefined') {
          grecaptcha.execute();
        } else {
          Captcha.postMessage('error');
        }
      ''');
    } catch (e) {
      log('Error executing reCAPTCHA: $e');
    }
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

  onPressSignUp() async {
    if (recaptcha_customer_register.$ &&
        (!_isWebViewReady || googleRecaptchaKey.isEmpty)) {
      ToastComponent.showDialog("Please wait for reCAPTCHA to load");
      _getRecaptchaToken();
      return;
    }

    Loading.show(context);

    var name = _nameController.text.toString();
    var email = _emailController.text.toString();
    var password = _passwordController.text.toString();
    var passwordConfirm = _passwordConfirmController.text.toString();

    if (name == "") {
      Loading.close();
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_your_name);
      return;
    } else if (_registerBy == 'email' && (email == "" || !isEmail(email))) {
      Loading.close();
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_email);
      return;
    } else if (_registerBy == 'phone' && _phone == "") {
      Loading.close();
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_phone_number,
      );
      return;
    } else if (password == "") {
      Loading.close();
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_password);
      return;
    } else if (passwordConfirm == "") {
      Loading.close();
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.confirm_your_password,
      );
      return;
    } else if (password.length < 6) {
      Loading.close();
      ToastComponent.showDialog(
        AppLocalizations.of(
          context,
        )!.password_must_contain_at_least_6_characters,
      );
      return;
    } else if (password != passwordConfirm) {
      Loading.close();
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.passwords_do_not_match,
      );
      return;
    }

    var signupResponse = await AuthRepository().getSignupResponse(
      name,
      _registerBy == 'email' ? email : _phone,
      password,
      passwordConfirm,
      _registerBy,
      googleRecaptchaKey,
    );
    Loading.close();

    if (signupResponse.result == false) {
      var message = "";
      signupResponse.message.forEach((value) {
        message += value + "\n";
      });

      ToastComponent.showDialog(message);

      // Reset reCAPTCHA token for retry
      if (recaptcha_customer_register.$) {
        setState(() {
          googleRecaptchaKey = "";
        });
        _getRecaptchaToken();
      }
    } else {
      ToastComponent.showDialog(signupResponse.message);
      AuthHelper().setUserData(signupResponse);

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

        if (is_logged_in.$ == true) {
          await ProfileRepository().getDeviceTokenUpdateResponse(fcmToken!);
        }
      }
      if (!mounted) return;
      if ((mail_verification_status.$ && _registerBy == "email") ||
          _registerBy == "phone") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return Otp();
            },
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return Home();
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AuthScreen.buildScreen(
          context,
          "${AppLocalizations.of(context)!.join_ucf} ${AppConfig.app_name}",
          buildBody(context),
        ),
        if (recaptcha_customer_register.$)
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

  Widget buildBody(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    AppLocalizations.of(context)!.name_ucf,
                    style: TextStyle(
                      color: MyTheme.accent_color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _nameController,
                      autofocus: false,
                      decoration: InputDecorations.buildInputDecoration_1(
                        hintText: "John Doe",
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    _registerBy == "email"
                        ? AppLocalizations.of(context)!.email_ucf
                        : AppLocalizations.of(context)!.phone_ucf,
                    style: TextStyle(
                      color: MyTheme.accent_color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_registerBy == "email")
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
                            decoration: InputDecorations.buildInputDecoration_1(
                              hintText: "johndoe@example.com",
                            ),
                          ),
                        ),
                        if (otp_addon_installed.$)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _registerBy = "phone";
                              });
                            },
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.or_register_with_a_phone,
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
                              _registerBy = "email";
                            });
                          },
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.or_register_with_an_email,
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
                          decoration: InputDecorations.buildInputDecoration_1(
                            hintText: "• • • • • • • •",
                          ),
                        ),
                      ),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.password_must_contain_at_least_6_characters,
                        style: TextStyle(
                          color: MyTheme.textfield_grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    AppLocalizations.of(context)!.retype_password_ucf,
                    style: TextStyle(
                      color: MyTheme.accent_color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _passwordConfirmController,
                      autofocus: false,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecorations.buildInputDecoration_1(
                        hintText: "• • • • • • • •",
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 15,
                        width: 15,
                        child: Checkbox(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          value: _isAgree,
                          onChanged: (newValue) {
                            setState(() {
                              _isAgree = newValue;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          maxLines: 2,
                          text: TextSpan(
                            style: TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(text: "I agree to the"),
                              TextSpan(
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CommonWebviewScreen(
                                          pageName: "Terms Conditions",
                                          url:
                                              "${AppConfig.RAW_BASE_URL}/mobile-page/terms",
                                        ),
                                      ),
                                    );
                                  },
                                style: TextStyle(color: MyTheme.accent_color),
                                text: " Terms Conditions",
                              ),
                              TextSpan(text: " &"),
                              TextSpan(
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CommonWebviewScreen(
                                          pageName: "Privacy Policy",
                                          url:
                                              "${AppConfig.RAW_BASE_URL}/mobile-page/privacy-policy",
                                        ),
                                      ),
                                    );
                                  },
                                text: " Privacy Policy",
                                style: TextStyle(color: MyTheme.accent_color),
                              ),
                            ],
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
                        AppLocalizations.of(context)!.sign_up_ucf,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _isAgree!
                          ? () {
                              onPressSignUp();
                            }
                          : null,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!.already_have_an_account,
                          style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      InkWell(
                        child: Text(
                          AppLocalizations.of(context)!.log_in,
                          style: TextStyle(
                            color: MyTheme.accent_color,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          context.push('/users/login');
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
