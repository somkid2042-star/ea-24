// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:ea24_mobile/custom/toast_component.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/repositories/payment_repository.dart';
import 'package:ea24_mobile/screens/orders/order_list.dart';
import 'package:ea24_mobile/screens/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../helpers/main_helpers.dart';
import '../profile.dart';

class SslCommerzScreen extends StatefulWidget {
  final double? amount;
  final String paymentType;
  final int? orderId;
  final String? paymentMethodKey;
  final dynamic packageId;
  const SslCommerzScreen({
    super.key,
    this.amount = 0.00,
    this.orderId = 0,
    this.paymentType = "",
    this.packageId = "0",
    this.paymentMethodKey = "",
  });

  @override
  State<SslCommerzScreen> createState() => _SslCommerzScreenState();
}

class _SslCommerzScreenState extends State<SslCommerzScreen> {
  int? _combinedOrderId = 0;
  bool _orderInit = false;

  String? _initialUrl = "";
  bool _initialUrlFetched = false;

  final WebViewController _webViewController = WebViewController();

  @override
  void initState() {
    super.initState();
    if (widget.paymentType == "cart_payment") {
      createOrder();
    }
    if (widget.paymentType != "cart_payment") {
      getSetInitialUrl();
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
    _orderInit = true;
    setState(() {});

    getSetInitialUrl();
  }

  sslcommerz() {
    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {},
          onPageFinished: (page) {
            if (page.contains("/sslcommerz/success")) {
              getData();
            } else if (page.contains("/sslcommerz/cancel") ||
                page.contains("/sslcommerz/fail")) {
              ToastComponent.showDialog("Payment cancelled or failed");
              Navigator.of(context).pop();
              return;
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_initialUrl!), headers: commonHeader);
  }

  getSetInitialUrl() async {
    var sslcommerzUrlResponse = await PaymentRepository()
        .getSslcommerzBeginResponse(
          widget.paymentType,
          _combinedOrderId,
          widget.packageId,
          widget.amount,
          widget.orderId!,
        );
    if (!mounted) return;
    if (sslcommerzUrlResponse.result == false) {
      ToastComponent.showDialog(sslcommerzUrlResponse.message!);
      Navigator.of(context).pop();
      return;
    }

    _initialUrl = sslcommerzUrlResponse.url;
    _initialUrlFetched = true;

    setState(() {});
    sslcommerz();
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

  void getData() {
    _webViewController
        .runJavaScriptReturningResult("document.body.innerText")
        .then((data) {
          var responseJSON = jsonDecode(data as String);
          if (responseJSON.runtimeType == String) {
            responseJSON = jsonDecode(responseJSON);
          }

          if (responseJSON["result"] == false) {
            ToastComponent.showDialog(responseJSON["message"]);
            Navigator.pop(context);
          } else if (responseJSON["result"] == true) {
            ToastComponent.showDialog(responseJSON["message"]);
            if (widget.paymentType == "cart_payment") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return OrderList(fromCheckout: true);
                  },
                ),
              );
            } else if (widget.paymentType == "order_re_payment") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return OrderList(fromCheckout: true);
                  },
                ),
              );
            } else if (widget.paymentType == "wallet_payment") {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return Wallet(fromRecharge: true);
                  },
                ),
              );
            } else if (widget.paymentType == "customer_package_payment") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return Profile();
                  },
                ),
              );
            }
          }
        });
  }

  buildBody() {
    if (_orderInit == false &&
        _combinedOrderId == 0 &&
        widget.paymentType == "cart_payment") {
      return Center(child: Text(AppLocalizations.of(context)!.creating_order));
    } else if (_initialUrlFetched == false) {
      return Center(
        child: Text(AppLocalizations.of(context)!.fetching_sslcommerz_url),
      );
    } else {
      return SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: WebViewWidget(controller: _webViewController),
        ),
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
        AppLocalizations.of(context)!.pay_with_sslcommerz,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
