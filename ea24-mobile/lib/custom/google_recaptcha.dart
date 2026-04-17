import 'package:ea24_mobile/app_config.dart';
import 'package:ea24_mobile/custom/device_info.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Captcha extends StatefulWidget {
  final Function(String) callback;
  final Function(bool)? handleCaptcha;

  const Captcha(this.callback, {super.key, this.handleCaptcha});

  @override
  State<Captcha> createState() => _CaptchaState();
}

class _CaptchaState extends State<Captcha> {
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController();
    _initializeGoogleRecaptcha();
  }

  @override
  void dispose() {
    _webViewController.removeJavaScriptChannel('Captcha');
    _webViewController.removeJavaScriptChannel('CaptchaShowValidation');
    super.dispose();
  }

  void _initializeGoogleRecaptcha() {
    final recaptchaUrl = Uri.parse("${AppConfig.BASE_URL}/google-recaptcha");

    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (String url) {}),
      )
      ..addJavaScriptChannel(
        'Captcha',
        onMessageReceived: (JavaScriptMessage message) {
          if (mounted) {
            widget.callback(message.message);
          }
        },
      )
      ..addJavaScriptChannel(
        'CaptchaShowValidation',
        onMessageReceived: (JavaScriptMessage message) {
          if (mounted && widget.handleCaptcha != null) {
            bool value = message.message.toLowerCase() == "true";
            widget.handleCaptcha!(value);
          }
        },
      )
      ..loadRequest(recaptchaUrl);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: DeviceInfo(context).width,
      child: WebViewWidget(controller: _webViewController),
    );
  }
}
