import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CommonWebviewScreen extends StatefulWidget {
  final String url;
  final String pageName;

  const CommonWebviewScreen({super.key, this.url = "", this.pageName = ""});

  @override
  State<CommonWebviewScreen> createState() => _CommonWebviewScreenState();
}

class _CommonWebviewScreenState extends State<CommonWebviewScreen> {
  final WebViewController _webViewController = WebViewController();

  @override
  void initState() {
    super.initState();
    webView();
  }

  webView() {
    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {},
          onPageFinished: (page) {},
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: buildAppBar(context),
        body: buildBody(),
      ),
    );
  }

  buildBody() {
    return SizedBox.expand(
      child: WebViewWidget(controller: _webViewController),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        widget.pageName,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
