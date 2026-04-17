import 'dart:developer';
import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/input_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/auth_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/auth/password_otp.dart';
import 'package:active_ecommerce_cms_demo_app/ui_elements/auth_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../app_config.dart';
import '../../custom/intl_phone_input.dart';
import '../../repositories/address_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class PasswordForget extends StatefulWidget {
  const PasswordForget({super.key});

  @override
  State<PasswordForget> createState() => _PasswordForgetState();
}

class _PasswordForgetState extends State<PasswordForget> {
  String _sendCodeBy = "email";
  String initialCountry = 'US';
  WebViewController? _controller;
  final String _recaptchaUrl = "${AppConfig.BASE_URL}/google-recaptcha";
  String googleRecaptchaKey = "";
  bool _isRecaptchaVerifying = false;

  String? _phone = "";
  var countriesCode = <String?>[];

  //controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    super.initState();
    fetchCountry();

    if (recaptcha_forgot_password.$) {
      setState(() {
        _isRecaptchaVerifying = true;
      });
      _setupWebViewController();
      _startRecaptchaTimeout();
    }
  }

  void _setupWebViewController() {
    late final PlatformWebViewControllerCreationParams params;
    params = const PlatformWebViewControllerCreationParams();

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'Captcha',
        onMessageReceived: (JavaScriptMessage message) {
          log("reCAPTCHA v3 Token Received: '${message.message}'");
          if (mounted &&
              message.message.isNotEmpty &&
              message.message != "error") {
            setState(() {
              googleRecaptchaKey = message.message;
              _isRecaptchaVerifying = false;
              log("reCAPTCHA key has been SET successfully!");
            });
          } else {
            setState(() {
              _isRecaptchaVerifying = false;
            });
            ToastComponent.showDialog(
              "Could not complete verification. Please try again.",
            );
            log("reCAPTCHA key was EMPTY or an ERROR.");
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            log('WebView page finished loading: $url');
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
                _isRecaptchaVerifying = false;
              });
              ToastComponent.showDialog(
                "Error loading verification. Check your connection.",
              );
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url == _recaptchaUrl) {
              return NavigationDecision.navigate;
            } else {
              _launchUrl(request.url);
              return NavigationDecision.prevent;
            }
          },
        ),
      );
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller.loadRequest(Uri.parse(_recaptchaUrl));
    _controller = controller;
  }

  void _startRecaptchaTimeout() {
    // Failsafe in case WebView never returns a key
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted && googleRecaptchaKey.isEmpty) {
        log("reCAPTCHA verification timed out.");
        setState(() {
          _isRecaptchaVerifying = false;
        });
        ToastComponent.showDialog("Verification timed out. Please try again.");
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      log('Could not launch $url');
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    super.dispose();
  }

  onPressSendCode() async {
    var email = _emailController.text.toString();

    if (_sendCodeBy == 'email' && email.isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_email);
      return;
    } else if (_sendCodeBy == 'phone' && (_phone == null || _phone!.isEmpty)) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_phone_number,
      );
      return;
    }

    if (recaptcha_forgot_password.$ && googleRecaptchaKey.isEmpty) {
      ToastComponent.showDialog("Please wait for verification to complete.");
      return;
    }

    var passwordForgetResponse = await AuthRepository()
        .getPasswordForgetResponse(
          _sendCodeBy == 'email' ? email : _phone,
          _sendCodeBy,
          googleRecaptchaKey,
        );

    if (!mounted) return;
    if (passwordForgetResponse.result == false) {
      ToastComponent.showDialog(passwordForgetResponse.message!);
    } else {
      ToastComponent.showDialog(passwordForgetResponse.message!);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return PasswordOtp(verifyBy: _sendCodeBy);
          },
        ),
      );
    }
  }

  fetchCountry() async {
    var data = await AddressRepository().getCountryList();
    data.countries.forEach((c) => countriesCode.add(c.code));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        AuthScreen.buildScreen(
          context,
          "Forget Password!",
          buildBody(screenWidth, context),
        ),
        if (recaptcha_forgot_password.$)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: SizedBox(
              width: 250,
              height: 80,
              child: WebViewWidget(controller: _controller!),
            ),
          ),
      ],
    );
  }

  Column buildBody(double screenWidth, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 20),
        SizedBox(
          width: screenWidth * (3 / 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  _sendCodeBy == "email"
                      ? AppLocalizations.of(context)!.email_ucf
                      : AppLocalizations.of(context)!.phone_ucf,
                  style: TextStyle(
                    color: MyTheme.accent_color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_sendCodeBy == "email")
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
                              _sendCodeBy = "phone";
                            });
                          },
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.or_send_code_via_phone_number,
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
                                hintText: "01710 333 558",
                              ),
                          onSaved: (PhoneNumber number) {},
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _sendCodeBy = "email";
                          });
                        },
                        child: Text(
                          AppLocalizations.of(context)!.or_send_code_via_email,
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
                padding: const EdgeInsets.only(top: 40.0),
                child: SizedBox(
                  height: 45,
                  child: Btn.basic(
                    minWidth: MediaQuery.of(context).size.width,
                    color: MyTheme.accent_color,
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(6.0),
                      ),
                    ),

                    onPressed: _isRecaptchaVerifying
                        ? null
                        : () {
                            onPressSendCode();
                          },
                    child: _isRecaptchaVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                        : Text(
                            "Send Code",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
