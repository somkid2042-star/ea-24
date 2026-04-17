import 'dart:convert';
import 'dart:developer';

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
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import 'package:http/http.dart' as http;

class PhonePeScreen extends StatefulWidget {
  final double? amount;
  final String paymentType;
  final String? paymentMethodKey;
  final dynamic packageId;
  final int? orderId;
  const PhonePeScreen({
    super.key,
    this.amount = 0.00,
    this.paymentType = "",
    this.paymentMethodKey = "",
    this.packageId = 0,
    this.orderId = 0,
  });

  @override
  State<PhonePeScreen> createState() => _PhonePeScreenState();
}

class _PhonePeScreenState extends State<PhonePeScreen> {
  String _mode = "SANDBOX";
  final String _appSchema = "yourappschema";
  int? _combinedOrderId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.paymentType == "cart_payment") {
        createOrder();
      } else {
        _fetchCredentialsAndInitiatePayment();
      }
    });
  }

  Future<void> createOrder() async {
    try {
      var orderCreateResponse = await PaymentRepository()
          .getOrderCreateResponse(widget.paymentMethodKey);
      if (!mounted) return;
      if (orderCreateResponse.result == false) {
        ToastComponent.showDialog(orderCreateResponse.message);
        Navigator.of(context).pop();
        return;
      }
      _combinedOrderId = orderCreateResponse.combined_order_id;
      _fetchCredentialsAndInitiatePayment();
    } catch (e) {
      log("Error creating order: $e");
      showError("Failed to create the order. Please try again.");
    }
  }

  Future<void> _fetchCredentialsAndInitiatePayment() async {
    final accessToken = access_token.$;

    if (accessToken == null || accessToken.isEmpty) {
      log("Authentication error: Access Token is missing.");
      showError("Your session has expired. Please log in again.");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("${AppConfig.BASE_URL}/phonepe-credentials"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $accessToken",
          "System-key": AppConfig.system_key,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('client_id') && data['client_id'] != null) {
          _initiateV2Payment(data);
        } else {
          showError("Invalid PhonePe credentials from server.");
        }
      } else {
        showError("Failed to fetch credentials from server.");
      }
    } catch (e) {
      log("Error fetching credentials: $e");
      showError("A network error occurred.");
    }
  }

  Future<void> _initiateV2Payment(Map<String, dynamic> credentials) async {
    String? merchantId = credentials["client_id"]?.toString();
    if (merchantId == null || merchantId.isEmpty) {
      showError("PhonePe Merchant ID is missing from server credentials.");
      return;
    }
    _mode = credentials["mode"] ?? "SANDBOX";

    final userId = user_id.$.toString();
    if (userId == "null" || userId == "0" || userId.isEmpty) {
      log("Authentication error: User ID is invalid.");
      showError("Your session has expired. Please log in again.");
      return;
    }

    final accessToken = access_token.$;

    if (accessToken == null || accessToken.isEmpty) {
      log("Authentication error: Access Token is missing.");
      showError("Your session has expired. Please log in again.");
      return;
    }

    var paymentPayload = {
      "user_id": userId,
      "payment_type": widget.paymentType,
      "amount": widget.amount,
      "package_id": widget.packageId,
      "combined_order_id": _combinedOrderId,
      "order_id": widget.orderId,
    };

    try {
      final response = await http.post(
        Uri.parse("${AppConfig.BASE_URL}/phonepe/payment/pay"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
          "System-key": AppConfig.system_key,
        },
        body: jsonEncode(paymentPayload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String token = data['token'];
        final String orderId = data['orderId'];
        final String responseAccessToken = data['accessToken'];
        final String merchantTransactionId = data['merchantTransactionId'];

        bool isInitialized = await PhonePePaymentSdk.init(
          _mode,
          merchantId,
          _appSchema,
          true,
        );
        if (isInitialized) {
          _startV2Transaction(
            token,
            orderId,
            merchantId,
            _appSchema,
            responseAccessToken,
            merchantTransactionId,
          );
        } else {
          showError("Failed to initialize PhonePe SDK.");
        }
      } else {
        log("Failed to get token: ${response.statusCode} - ${response.body}");
        showError("Could not start payment. Please try again.");
      }
    } catch (e) {
      log("Error initiating payment: $e");
      showError("An unexpected error occurred.");
    }
  }

  void _startV2Transaction(
    String token,
    String orderId,
    String merchantId,
    String appSchema,
    String accessToken,
    String merchantTransactionId,
  ) async {
    try {
      Map<String, dynamic> payload = {
        "orderId": orderId,
        "merchantId": merchantId,
        "token": token,
        "paymentMode": {"type": "PAY_PAGE"},
      };
      String requestPayload = jsonEncode(payload);

      Map<dynamic, dynamic>? response =
          await PhonePePaymentSdk.startTransaction(requestPayload, appSchema);

      if (response != null && response['status'].toString() == 'SUCCESS') {
        log("V2 Payment Success: $response");
        Map<String, dynamic> dataPayload = {
          "merchantOrderId": orderId,
          "accessToken": accessToken,
          "merchantTransactionId": merchantTransactionId,
          "amount": widget.amount,
        };
        String base64Payload = base64Encode(
          utf8.encode(jsonEncode({"data": dataPayload})),
        );
        await notifyServerOfSuccess(base64Payload);
        navigateToSuccessScreen();
      } else {
        log("V2 Payment Failed/Cancelled: $response");
        handlePaymentFailure();
      }
    } catch (e) {
      log("V2 Transaction Error: $e");
      handlePaymentFailure();
    }
  }

  Future<void> notifyServerOfSuccess(String encodedPayload) async {
    final accessToken = access_token.$;
    if (accessToken == null || accessToken.isEmpty) return;

    try {
      await http.post(
        Uri.parse("${AppConfig.BASE_URL}/phonepe/callbackUrl"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode({"response": encodedPayload}),
      );
    } catch (e) {
      log("Error notifying server: $e");
    }
  }

  void navigateToSuccessScreen() {
    if (!mounted) return;

    if (widget.paymentType == "cart_payment" ||
        widget.paymentType == "order_re_payment") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OrderList(fromCheckout: true)),
      );
    } else if (widget.paymentType == "wallet_payment") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Wallet(fromRecharge: true)),
      );
    } else if (widget.paymentType == "customer_package_payment") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UpdatePackage(goHome: true)),
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  void handlePaymentFailure() {
    if (!mounted) return;
    ToastComponent.showDialog("Payment Failed or Cancelled");
    Navigator.pop(context);
  }

  void showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Payment Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          "Pay With PhonePe",
          style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
        ),
        elevation: 0.0,
        titleSpacing: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Initiating Payment..."),
          ],
        ),
      ),
    );
  }
}
