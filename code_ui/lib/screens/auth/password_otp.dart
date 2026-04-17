import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/device_info.dart';
import 'package:active_ecommerce_cms_demo_app/custom/input_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/custom/lang_text.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/auth_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/auth/login.dart';
import 'package:active_ecommerce_cms_demo_app/ui_elements/auth_ui.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';

class PasswordOtp extends StatefulWidget {
  final String verifyBy;
  final String? emailOrCode;
  const PasswordOtp({super.key, this.verifyBy = "email", this.emailOrCode});
  @override
  State<PasswordOtp> createState() => _PasswordOtpState();
}

class _PasswordOtpState extends State<PasswordOtp> {
  //controllers
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  String headeText = "";

  FlipCardController cardController = FlipCardController();

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      headeText = AppLocalizations.of(context)!.enter_the_code_sent;
      setState(() {});
    });
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    super.initState();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    super.dispose();
  }

  onPressConfirm() async {
    var code = _codeController.text.toString();
    var password = _passwordController.text.toString();
    var passwordConfirm = _passwordConfirmController.text.toString();

    if (code == "") {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_the_code);
      return;
    } else if (password == "") {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_password);
      return;
    } else if (passwordConfirm == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.confirm_your_password,
      );
      return;
    } else if (password.length < 6) {
      ToastComponent.showDialog(
        AppLocalizations.of(
          context,
        )!.password_must_contain_at_least_6_characters,
      );
      return;
    } else if (password != passwordConfirm) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.passwords_do_not_match,
      );
      return;
    }

    var passwordConfirmResponse = await AuthRepository()
        .getPasswordConfirmResponse(code, password);
    if (!mounted) return;

    if (passwordConfirmResponse.result == false) {
      ToastComponent.showDialog(passwordConfirmResponse.message!);
    } else {
      ToastComponent.showDialog(passwordConfirmResponse.message!);

      headeText = AppLocalizations.of(context)!.password_changed_ucf;
      cardController.toggleCard();
      setState(() {});
    }
  }

  onTapResend() async {
    var passwordResendCodeResponse = await AuthRepository()
        .getPasswordResendCodeResponse(widget.emailOrCode, widget.verifyBy);

    if (passwordResendCodeResponse.result == false) {
      ToastComponent.showDialog(passwordResendCodeResponse.message!);
    } else {
      ToastComponent.showDialog(passwordResendCodeResponse.message!);
    }
  }

  gotoLoginScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    String verifyBy = widget.verifyBy; //phone or email
    final screenWidth = MediaQuery.of(context).size.width;
    return AuthScreen.buildScreen(
      context,
      headeText,
      PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          gotoLoginScreen();
        },
        child: buildBody(context, screenWidth, verifyBy),
      ),
    );
  }

  Widget buildBody(BuildContext context, double screenWidth, String verifyBy) {
    return FlipCard(
      flipOnTouch: false,
      controller: cardController,
      direction: FlipDirection.HORIZONTAL,
      front: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SizedBox(
              width: screenWidth * (3 / 4),
              child: verifyBy == "email"
                  ? Text(
                      AppLocalizations.of(
                        context,
                      )!.enter_the_verification_code_that_sent_to_your_email_recently,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MyTheme.dark_grey, fontSize: 14),
                    )
                  : Text(
                      AppLocalizations.of(
                        context,
                      )!.enter_the_verification_code_that_sent_to_your_phone_recently,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MyTheme.dark_grey, fontSize: 14),
                    ),
            ),
          ),
          SizedBox(
            width: screenWidth * (3 / 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    AppLocalizations.of(context)!.enter_the_code,
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
                          controller: _codeController,
                          autofocus: false,
                          decoration: InputDecorations.buildInputDecoration_1(
                            hintText: "A X B 4 J H",
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
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: MyTheme.textfield_grey,
                        width: 1,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(12.0),
                      ),
                    ),
                    child: Btn.basic(
                      minWidth: MediaQuery.of(context).size.width,
                      color: MyTheme.accent_color,
                      shape: RoundedRectangleBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12.0),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.confirm_ucf,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        onPressConfirm();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: InkWell(
              onTap: () {
                onTapResend();
              },
              child: Text(
                AppLocalizations.of(context)!.resend_code_ucf,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: MyTheme.accent_color,
                  decoration: TextDecoration.underline,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      back: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SizedBox(
              width: screenWidth * (3 / 4),
              child: Text(
                LangText(context).local.congratulations_ucf,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: MyTheme.accent_color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SizedBox(
              width: screenWidth * (3 / 4),
              child: Text(
                LangText(
                  context,
                ).local.you_have_successfully_changed_your_password,
                textAlign: TextAlign.center,
                style: TextStyle(color: MyTheme.accent_color, fontSize: 13),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: Image.asset(
              'assets/changed_password.png',
              width: DeviceInfo(context).width! / 2,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 40.0),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              height: 45,
              child: Btn.basic(
                minWidth: MediaQuery.of(context).size.width,
                color: MyTheme.accent_color,
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(6.0)),
                ),
                child: Text(
                  AppLocalizations.of(context)!.back_to_Login_ucf,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  gotoLoginScreen();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
