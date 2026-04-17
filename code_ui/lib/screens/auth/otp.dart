import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/input_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/auth_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';

class Otp extends StatefulWidget {
  final String? title;
  const Otp({super.key, this.title});

  @override
  State<Otp> createState() => _OtpState();
}

class _OtpState extends State<Otp> {
  //controllers
  final TextEditingController _verificationCodeController =
      TextEditingController();

  @override
  void initState() {
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

  onTapResend() async {
    var resendCodeResponse = await AuthRepository().getResendCodeResponse();

    if (resendCodeResponse.result == false) {
      ToastComponent.showDialog(resendCodeResponse.message!);
    } else {
      ToastComponent.showDialog(resendCodeResponse.message!);
    }
  }

  onPressConfirm() async {
    var code = _verificationCodeController.text.toString();

    if (code == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_verification_code,
      );
      return;
    }

    var confirmCodeResponse = await AuthRepository().getConfirmCodeResponse(
      code,
    );
    if (!mounted) return;

    if (!(confirmCodeResponse.result)) {
      ToastComponent.showDialog(confirmCodeResponse.message);
    } else {
      ToastComponent.showDialog(confirmCodeResponse.message);
      if (SystemConfig.systemUser != null) {
        SystemConfig.systemUser!.emailVerified = true;
      }
      context.go("/");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Container(
              color: Colors.red,
              width: screenWidth,
              height: 200,
              child: Image.asset(
                "assets/splash_login_registration_background_image.png",
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.title != null)
                      Text(
                        widget.title!,
                        style: TextStyle(
                          fontSize: 25,
                          color: MyTheme.font_grey,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 40.0, bottom: 15),
                      child: SizedBox(
                        width: 75,
                        height: 75,
                        child: Image.asset(
                          'assets/login_registration_form_logo.png',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: screenWidth * (3 / 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SizedBox(
                                  height: 36,
                                  child: TextField(
                                    controller: _verificationCodeController,
                                    autofocus: false,
                                    decoration:
                                        InputDecorations.buildInputDecoration_1(
                                          hintText: "A X B 4 J H",
                                        ),
                                  ),
                                ),
                              ],
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
                      padding: const EdgeInsets.only(top: 60),
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
                    // SizedBox(height: 15,),
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: InkWell(
                        onTap: () {
                          onTapLogout(context);
                        },
                        child: Text(
                          AppLocalizations.of(context)!.logout_ucf,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  onTapLogout(context) {
    try {
      AuthHelper().clearUserData();
      routes.push("/");
      // ignore: empty_catches
    } catch (e) {}
  }
}
