import 'dart:convert';

import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/payment_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/orders/order_list.dart';
import 'package:active_ecommerce_cms_demo_app/screens/package/packages.dart';
import 'package:active_ecommerce_cms_demo_app/screens/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OnlinePay extends StatefulWidget {
  final String? title;
  final double? amount;
  final String paymentType;
  final String? paymentMethodKey;
  final dynamic packageId;
  final int? orderId;
  const OnlinePay({
    super.key,
    this.amount = 0.00,
    this.orderId = 0,
    this.title = "Pay With Instamojo",
    this.paymentType = "",
    this.packageId = "0",
    this.paymentMethodKey = "",
  });

  @override
  State<OnlinePay> createState() => _OnlinePayState();
}

class _OnlinePayState extends State<OnlinePay> {
  int? _combinedOrderId = 0;
  bool _initialUrlFetched = false;

  final WebViewController _webViewController = WebViewController();

  @override
  void initState() {
    super.initState();
    if (widget.paymentType == "cart_payment") {
      createOrder();
    } else {
      pay(
        Uri.parse(
          "${AppConfig.BASE_URL}/online-pay/init?payment_type=${widget.paymentType}&combined_order_id=$_combinedOrderId&wallet_amount=${widget.amount}&payment_option=${widget.paymentMethodKey}&order_id=${widget.orderId}",
        ),
      );
    }
  }

  createOrder() async {
    var orderCreateResponse = await PaymentRepository().getOrderCreateResponse(
      widget.paymentMethodKey,
    );
    if (!mounted) return;
    if (orderCreateResponse.result == false) {
      ToastComponent.showDialog(orderCreateResponse.message);
      Navigator.of(context).pop();
      return;
    }
    _combinedOrderId = orderCreateResponse.combined_order_id;
    pay(
      Uri.parse(
        "${AppConfig.BASE_URL}/online-pay/init?payment_type=${widget.paymentType}&combined_order_id=$_combinedOrderId&wallet_amount=${widget.amount}&payment_option=${widget.paymentMethodKey}",
      ),
    );
  }

  pay(url) {
    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {},
          onPageFinished: (page) {
            if (page.contains("/online-pay/done")) {
              if (widget.paymentType == "cart_payment") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderList(fromCheckout: true),
                  ),
                );
              } else if (widget.paymentType == "order_re_payment") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderList(fromCheckout: true),
                  ),
                );
              } else if (widget.paymentType == "wallet_payment") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Wallet(fromRecharge: true),
                  ),
                );
              } else if (widget.paymentType == "customer_package_payment") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdatePackage(goHome: true),
                  ),
                );
              }
            }
            if (page.contains("/online-pay/failed")) {
              getData();
              Navigator.pop(context);
            }
          },
        ),
      )
      ..loadRequest(
        url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
          "Accept": "application/json",
          "System-Key": AppConfig.system_key,
        },
      );
    _initialUrlFetched = true;
    setState(() {});
  }

  void getData() {
    _webViewController
        .runJavaScriptReturningResult("document.body.innerText")
        .then((data) {
          var responseJSON = jsonDecode(data as String);

          if (responseJSON.runtimeType == String) {
            responseJSON = jsonDecode(responseJSON);
          }

          ToastComponent.showDialog(responseJSON["message"]);
        });
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
    if (_initialUrlFetched == false &&
        _combinedOrderId == 0 &&
        widget.paymentType == "cart_payment") {
      return Center(child: Text(AppLocalizations.of(context)!.creating_order));
    } else {
      return SizedBox.expand(
        child: WebViewWidget(controller: _webViewController),
      );
    }
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
        widget.title!,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
