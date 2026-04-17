import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ea24_mobile/app_config.dart';
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

class CybersourceScreen extends StatefulWidget {
  final double? amount;
  final String paymentType;
  final String? paymentMethodKey;
  final dynamic packageId;
  final int? orderId;

  const CybersourceScreen({
    super.key,
    this.amount = 0.00,
    this.orderId = 0,
    required this.paymentType,
    this.packageId = "0",
    this.paymentMethodKey = "",
  });

  @override
  State<CybersourceScreen> createState() => _CybersourceScreenState();
}

class _CybersourceScreenState extends State<CybersourceScreen> {
  int? _combinedOrderId = 0;
  bool _orderInit = false;
  bool _isLoading = true;
  bool _paymentCompleted = false;
  String? _errorMessage;

  late WebViewController _webViewController;
  final Completer<WebViewController> _controllerCompleter =
      Completer<WebViewController>();

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();

    if (widget.paymentType == "cart_payment") {
      createOrder();
    } else {
      _orderInit = true;
      initiateCybersourcePayment();
    }
  }

  void _initializeWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (kDebugMode) {
              print('WebView loading: $progress%');
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });

            if (url.contains('${AppConfig.BASE_URL}/payment/success') ||
                url.contains(
                  '${AppConfig.BASE_URL}/cyber-source/payment/callback',
                )) {
              _handlePaymentSuccess();
            } else if (url.contains('/payment/failure') ||
                url.contains('/payment/error')) {
              _handlePaymentFailure();
            }
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _errorMessage = 'Payment failed: ${error.description}';
              _isLoading = false;
            });
            if (kDebugMode) {
              print('WebView error: ${error.description}');
            }
          },
          onUrlChange: (UrlChange change) {
            if (kDebugMode) {
              print('URL changed to: ${change.url}');
            }
            setState(() {});
          },
        ),
      )
      ..addJavaScriptChannel(
        'PaymentHandler',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'payment_success') {
            _handlePaymentSuccess();
          } else if (message.message == 'payment_failure') {
            _handlePaymentFailure();
          }
        },
      );

    _controllerCompleter.complete(_webViewController);
  }

  void createOrder() async {
    try {
      final orderCreateResponse = await PaymentRepository()
          .getOrderCreateResponse(widget.paymentMethodKey);

      if (orderCreateResponse.result == false) {
        _showErrorAndClose(orderCreateResponse.message);
        return;
      }

      setState(() {
        _combinedOrderId = orderCreateResponse.combined_order_id;
        _orderInit = true;
      });

      initiateCybersourcePayment();
    } catch (e) {
      _showErrorAndClose('Failed to create order: $e');
    }
  }

  Future<void> initiateCybersourcePayment() async {
    try {
      final postData = _buildPaymentPostData();
      final response = await http.post(
        Uri.parse("${AppConfig.BASE_URL}/cyber-source/payment/pay"),
        headers: commonHeader,
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        await _webViewController.loadHtmlString(response.body);
      } else {
        _showErrorAndClose(
          'Failed to initiate payment: ${response.statusCode}',
        );
      }
    } catch (e) {
      _showErrorAndClose('Payment initialization error: $e');
    }
  }

  Map<String, dynamic> _buildPaymentPostData() {
    final postData = {
      "payment_type": widget.paymentType,
      "user_id": user_id.$,
      "amount": widget.amount,
    };

    if (widget.paymentType == 'cart_payment') {
      postData['combined_order_id'] = _combinedOrderId;
    } else if (widget.paymentType == 'wallet_payment') {
      postData['payment_method'] = "cybersource";
    } else if (widget.paymentType == 'order_re_payment') {
      postData['order_id'] = widget.orderId;
    } else if (widget.paymentType == 'customer_package_payment') {
      postData['package_id'] = widget.packageId;
    }

    return postData;
  }

  void _handlePaymentSuccess() {
    if (_paymentCompleted) return;

    setState(() {
      _paymentCompleted = true;
      _isLoading = false;
    });

    ToastComponent.showDialog("Payment completed successfully!");
    _navigateAfterPayment();
  }

  void _handlePaymentFailure() {
    setState(() {
      _errorMessage = "Payment failed. Please try again.";
      _isLoading = false;
    });
  }

  void _navigateAfterPayment() {
    Widget targetScreen;

    if (widget.paymentType == "cart_payment" ||
        widget.paymentType == "order_re_payment") {
      targetScreen = OrderList(fromCheckout: true);
    } else if (widget.paymentType == "wallet_payment") {
      targetScreen = Wallet(fromRecharge: true);
    } else if (widget.paymentType == "customer_package_payment") {
      targetScreen = Profile();
    } else {
      targetScreen = Profile();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
      (Route<dynamic> route) => false,
    );
  }

  void _showErrorAndClose(String message) {
    ToastComponent.showDialog(message);
    if (mounted) {
      Navigator.of(context).pop();
    }
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
        body: _buildPaymentView(),
      ),
    );
  }

  Widget _buildPaymentView() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Go Back'),
            ),
          ],
        ),
      );
    }

    if (!_orderInit && widget.paymentType == "cart_payment") {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(LangText(context).local.creating_order),
          ],
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_isLoading)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  _paymentCompleted
                      ? "Processing payment..."
                      : "Loading payment gateway...",
                ),
              ],
            ),
          ),
      ],
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
        onPressed: () {
          if (!_paymentCompleted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Cancel Payment?"),
                content: Text("Are you sure you want to cancel this payment?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("No"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: Text("Yes"),
                  ),
                ],
              ),
            );
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Text(
        "Pay with CyberSource",
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}
