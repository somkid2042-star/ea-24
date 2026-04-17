import 'dart:convert';

import 'package:ea24_mobile/custom/toast_component.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/repositories/payment_repository.dart';
import 'package:ea24_mobile/screens/orders/order_list.dart';
import 'package:ea24_mobile/screens/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../app_config.dart';
import '../../helpers/shared_value_helper.dart';
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

  bool showLoading = false;

  final WebViewController _webViewController = WebViewController();

  @override
  void initState() {
    super.initState();
    if (widget.paymentType == "cart_payment") {
      createOrder();
    }
    if (widget.paymentType != "cart_payment") {
      bkash();
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
    bkash();
  }

  bkash() {
    _initialUrl =
        ("${AppConfig.BASE_URL}/bkash/begin?payment_type=${widget.paymentType}&combined_order_id=$_combinedOrderId&amount=${widget.amount}&user_id=${user_id.$}&package_id=${widget.packageId}&order_id=${widget.orderId}");

    _initialUrlFetched = true;
    setState(() {});

    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {},
          onPageFinished: (page) {
            if (page.contains("/bkash/api/callback")) {
              getData();
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(_initialUrl!),
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$!,
          "Accept": "application/json",
          "System-Key": AppConfig.system_key,
          "Authorization": "Bearer ${access_token.$}",
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context),
      body: buildBody(),
    );
  }

  Future<void> getData() async {
    final data = await _webViewController.runJavaScriptReturningResult(
      "document.body.innerText",
    );

    if (!mounted) return;

    var responseJSON = jsonDecode(data as String);

    if (responseJSON is String) {
      responseJSON = jsonDecode(responseJSON);
    }

    ToastComponent.showDialog(responseJSON["message"]);

    if (responseJSON["result"] == false) {
      Navigator.pop(context);
      return;
    }

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
        AppLocalizations.of(context)!.pay_with_bkash,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
