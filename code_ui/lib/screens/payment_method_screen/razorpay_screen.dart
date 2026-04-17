// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/payment_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/orders/order_list.dart';
import 'package:active_ecommerce_cms_demo_app/screens/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../helpers/system_config.dart';
import '../profile.dart';

class RazorpayScreen extends StatefulWidget {
  final double? amount;
  final String paymentType;
  final String? paymentMethodKey;
  final int? orderId;
  final dynamic packageId;

  const RazorpayScreen({
    super.key,
    this.amount = 0.00,
    this.orderId = 0,
    this.paymentType = "",
    this.packageId = "0",
    this.paymentMethodKey = "",
  });

  @override
  State<RazorpayScreen> createState() => _RazorpayScreenState();
}

class _RazorpayScreenState extends State<RazorpayScreen> {
  int? _combinedOrderId = 0;
  bool _orderInit = false;

  final WebViewController _webViewController = WebViewController();

  @override
  void initState() {
    super.initState();

    if (widget.paymentType == "cart_payment") {
      createOrder();
    } else {
      razorpay();
    }
  }

  razorpay() {
    String initialUrl =
        "${AppConfig.BASE_URL}/razorpay/pay-with-razorpay?payment_type=${widget.paymentType}&combined_order_id=$_combinedOrderId&amount=${widget.amount}&user_id=${user_id.$}&package_id=${widget.packageId}&order_id${widget.orderId}";

    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {},
          onPageFinished: (page) {
            if (page.contains("/razorpay/success")) {
              getData();
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(initialUrl),
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
          "Accept": "application/json",
          "System-Key": AppConfig.system_key,
          "Authorization": "Bearer ${access_token.$}",
          "Currency-Code": SystemConfig.systemCurrency!.code!,
          "Currency-Exchange-Rate": SystemConfig.systemCurrency!.exchangeRate
              .toString(),
        },
      );
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
    razorpay();
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
    String? paymentDetails = '';
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
            paymentDetails = responseJSON['payment_details'];
            onPaymentSuccess(paymentDetails);
          }
        });
  }

  onPaymentSuccess(paymentDetails) async {
    var razorpayPaymentSuccessResponse = await PaymentRepository()
        .getRazorpayPaymentSuccessResponse(
          widget.paymentType,
          widget.amount,
          _combinedOrderId,
          paymentDetails,
        );

    if (razorpayPaymentSuccessResponse.result == false) {
      ToastComponent.showDialog(razorpayPaymentSuccessResponse.message!);
      Navigator.pop(context);
      return;
    }

    ToastComponent.showDialog(razorpayPaymentSuccessResponse.message!);

    if (widget.paymentType == "cart_payment") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return OrderList(fromCheckout: true);
          },
        ),
      );
    } else if (widget.paymentType == "wallet_payment") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return Wallet(fromRecharge: true);
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

  buildBody() {
    if (_orderInit == false &&
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
        AppLocalizations.of(context)!.pay_with_razorpay,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
