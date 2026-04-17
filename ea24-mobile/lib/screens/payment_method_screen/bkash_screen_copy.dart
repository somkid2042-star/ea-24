import 'dart:convert';

import 'package:ea24_mobile/custom/toast_component.dart';
import 'package:ea24_mobile/helpers/main_helpers.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/repositories/payment_repository.dart';
import 'package:ea24_mobile/screens/orders/order_list.dart';
import 'package:ea24_mobile/screens/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../profile.dart';

class BkashScreen extends StatefulWidget {
  final double? amount;
  final String paymentType;
  final String? paymentMethodKey;
  final dynamic packageId;
  final int? orderId;

  const BkashScreen({
    super.key,
    this.amount = 0.00,
    this.orderId = 0,
    this.paymentType = "",
    this.paymentMethodKey = "",
    this.packageId = "0",
  });

  @override
  State<BkashScreen> createState() => _BkashScreenState();
}

class _BkashScreenState extends State<BkashScreen> {
  int? _combinedOrderId = 0;
  bool _orderInit = false;
  String? _initialUrl = "";
  bool _initialUrlFetched = false;

  String? _token = "";
  bool showLoading = false;

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
    var bkashUrlResponse = await PaymentRepository().getBkashBeginResponse(
      widget.paymentType,
      _combinedOrderId,
      widget.packageId,
      widget.amount,
      widget.orderId!,
    );
    if (!mounted) return;
    if (bkashUrlResponse.result == false) {
      ToastComponent.showDialog(bkashUrlResponse.message!);
      Navigator.of(context).pop();
      return;
    }
    _token = bkashUrlResponse.token;

    _initialUrl = bkashUrlResponse.url;
    _initialUrlFetched = true;

    setState(() {});
    bkash();
  }

  bkash() {
    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {},
          onPageFinished: (page) {
            if (page.contains("/bkash/api/callback")) {
              getData();
            } else if (page.contains("/bkash/api/fail")) {
              ToastComponent.showDialog("Payment cancelled");
              Navigator.of(context).pop();
              return;
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_initialUrl!), headers: commonHeader);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context),
      body: buildBody(),
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
            if (!mounted) return;
            Navigator.pop(context);
          } else if (responseJSON["result"] == true) {
            onPaymentSuccess(responseJSON);
          }
        });
  }

  onPaymentSuccess(paymentDetails) async {
    showLoading = true;
    setState(() {});

    var bkashPaymentProcessResponse = await PaymentRepository()
        .getBkashPaymentProcessResponse(
          amount: widget.amount,
          token: _token,
          payment_type: widget.paymentType,
          combined_order_id: _combinedOrderId,
          package_id: widget.packageId,
          payment_id: paymentDetails['paymentID'],
        );
    if (!mounted) return;
    if (bkashPaymentProcessResponse.result == false) {
      ToastComponent.showDialog(bkashPaymentProcessResponse.message!);
      Navigator.pop(context);
      return;
    }

    ToastComponent.showDialog(bkashPaymentProcessResponse.message!);
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

  buildBody() {
    if (_orderInit == false &&
        _combinedOrderId == 0 &&
        widget.paymentType == "cart_payment") {
      return Center(child: Text(AppLocalizations.of(context)!.creating_order));
    } else if (_initialUrlFetched == false) {
      return Center(
        child: Text(AppLocalizations.of(context)!.fetching_bkash_url),
      );
    } else {
      return SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: showLoading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 1, height: 1),
                    CircularProgressIndicator(strokeWidth: 3),
                  ],
                )
              : WebViewWidget(controller: _webViewController),
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
        AppLocalizations.of(context)!.pay_with_bkash,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
