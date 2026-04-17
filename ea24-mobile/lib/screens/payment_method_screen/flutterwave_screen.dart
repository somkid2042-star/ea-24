import 'dart:convert';

import 'package:ea24_mobile/custom/toast_component.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/repositories/payment_repository.dart';
import 'package:ea24_mobile/screens/orders/order_list.dart';
import 'package:ea24_mobile/screens/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../custom/lang_text.dart';
import '../../helpers/main_helpers.dart';
import '../profile.dart';

class FlutterwaveScreen extends StatefulWidget {
  final double? amount;
  final String paymentType;
  final String? paymentMethodKey;
  final dynamic packageId;
  final int? orderId;
  const FlutterwaveScreen({
    super.key,
    this.amount = 0.00,
    this.orderId = 0,
    this.paymentType = "",
    this.packageId = "0",
    this.paymentMethodKey = "",
  });

  @override
  State<FlutterwaveScreen> createState() => _FlutterwaveScreenState();
}

class _FlutterwaveScreenState extends State<FlutterwaveScreen> {
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

  getSetInitialUrl() async {
    var flutterwaveUrlResponse = await PaymentRepository()
        .getFlutterwaveUrlResponse(
          widget.paymentType,
          _combinedOrderId,
          widget.packageId,
          widget.amount,
          widget.orderId!,
        );
    if (!mounted) return;
    if (flutterwaveUrlResponse.result == false) {
      ToastComponent.showDialog(flutterwaveUrlResponse.message!);
      Navigator.of(context).pop();
      return;
    }

    _initialUrl = flutterwaveUrlResponse.url;
    _initialUrlFetched = true;

    setState(() {});

    flutterWave();
  }

  flutterWave() {
    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {},
          onPageFinished: (page) {
            if (page.contains("/flutterwave/payment/callback")) {
              getData();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_initialUrl!), headers: commonHeader);
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

  Future<void> getData() async {
    final data = await _webViewController.runJavaScriptReturningResult(
      "document.body.innerText",
    );

    if (!mounted) return; // ✅ VERY IMPORTANT

    dynamic responseJSON = jsonDecode(data as String);

    if (responseJSON is String) {
      responseJSON = jsonDecode(responseJSON);
    }

    ToastComponent.showDialog(responseJSON["message"]);

    if (responseJSON["result"] == false) {
      Navigator.pop(context);
      return;
    }

    // ✅ result == true
    if (widget.paymentType == "cart_payment") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderList(fromCheckout: true)),
      );
    } else if (widget.paymentType == "order_re_payment") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderList(fromCheckout: true)),
      );
    } else if (widget.paymentType == "wallet_payment") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Wallet(fromRecharge: true)),
      );
    } else if (widget.paymentType == "customer_package_payment") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Profile()),
      );
    }
  }

  buildBody() {
    if (_orderInit == false &&
        _combinedOrderId == 0 &&
        widget.paymentType == "cart_payment") {
      return Center(child: Text(LangText(context).local.creating_order));
    } else if (_initialUrlFetched == false) {
      return Center(child: Text("Fetching Flutterwave url ..."));
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
        LangText(context).local.pay_with_flutterwave,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
