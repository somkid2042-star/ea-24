import 'dart:convert';

import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/payment_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/profile_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/orders/order_list.dart';
import 'package:active_ecommerce_cms_demo_app/screens/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../custom/lang_text.dart';
import '../profile.dart';

class KhaltiScreen extends StatefulWidget {
  final double? amount;
  final String paymentType;
  final String? paymentMethodKey;
  final dynamic packageId;
  final int? orderId;
  const KhaltiScreen({
    super.key,
    this.amount = 0.00,
    this.orderId = 0,
    this.paymentType = "",
    this.packageId = "0",
    this.paymentMethodKey = "",
  });

  @override
  State<KhaltiScreen> createState() => _KhaltiScreenState();
}

class _KhaltiScreenState extends State<KhaltiScreen> {
  int? _combinedOrderId = 0;
  bool _orderInit = false;

  final WebViewController _webViewController = WebViewController();

  @override
  void initState() {
    super.initState();
    checkPhoneAvailability().then((val) {
      if (widget.paymentType == "cart_payment") {
        createOrder();
      } else {
        khalti();
      }
    });
  }

  khalti() {
    String initialUrl =
        "${AppConfig.BASE_URL}/khalti/payment/pay?payment_type=${widget.paymentType}&combined_order_id=$_combinedOrderId&amount=${widget.amount}&user_id=${user_id.$}&package_id=${widget.packageId}&order_id=${widget.orderId}";

    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {},
          onPageFinished: (page) {
            if (page.contains("/khalti/payment/success")) {
              getData();
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(initialUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$!,
          "Accept": "application/json",
          "System-Key": AppConfig.system_key,
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
    khalti();
  }

  checkPhoneAvailability() async {
    var phoneEmailAvailabilityResponse = await ProfileRepository()
        .getPhoneEmailAvailabilityResponse();
    if (!mounted) return;
    if (phoneEmailAvailabilityResponse.phone_available == false) {
      ToastComponent.showDialog(
        phoneEmailAvailabilityResponse.phone_available_message,
      );
      Navigator.of(context).pop();
      return;
    }
    return;
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
            if (!mounted) return;
            ToastComponent.showDialog(responseJSON["message"]);
            Navigator.pop(context);
          } else if (responseJSON["result"] == true) {
            ToastComponent.showDialog(responseJSON["message"]);

            if (widget.paymentType == "cart_payment") {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return OrderList(fromCheckout: true);
                  },
                ),
              );
            } else if (widget.paymentType == "order_re_payment") {
              if (!mounted) return;
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
              if (!mounted) return;
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
        LangText(context).local.pay_with_khalti,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
