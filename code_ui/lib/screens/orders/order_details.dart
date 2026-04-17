import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/custom/box_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/confirm_dialog.dart';
import 'package:active_ecommerce_cms_demo_app/custom/enum_classes.dart';
import 'package:active_ecommerce_cms_demo_app/custom/lang_text.dart';
import 'package:active_ecommerce_cms_demo_app/custom/loading.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/order_detail_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/main_helpers.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/order_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/refund_request_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/checkout/checkout.dart';
import 'package:active_ecommerce_cms_demo_app/screens/main.dart';
import 'package:active_ecommerce_cms_demo_app/screens/refund_request.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../../custom/dash_divider.dart';
import '../checkout/cart.dart';

class OrderDetails extends StatefulWidget {
  final int? id;
  final bool fromNotification;
  final bool goBack;

  const OrderDetails({
    super.key,
    this.id,
    this.fromNotification = false,
    this.goBack = true,
  });

  @override
  State<OrderDetails> createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  final ScrollController _mainScrollController = ScrollController();
  final _steps = [
    'pending',
    'confirmed',
    'on_delivery',
    'picked_up',
    'on_the_way',
    'delivered',
  ];

  final TextEditingController _refundReasonController = TextEditingController();
  bool _showReasonWarning = false;

  //init
  int _stepIndex = 0;
  final ReceivePort _port = ReceivePort();
  DetailedOrder? _orderDetails;
  final List<dynamic> _orderedItemList = [];
  bool _orderItemsInit = false;

  @override
  void initState() {
    fetchAll();

    IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );

    _port.listen((dynamic data) {
      if (data[2] >= 100) {
        ToastComponent.showDialog("File has downloaded successfully.");
      }
      setState(() {});
    });
    FlutterDownloader.registerCallback(downloadCallback);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _downloadInvoice(id) async {
    var folder = await createFolder();
    try {
      await FlutterDownloader.enqueue(
        url: "${AppConfig.BASE_URL}/invoice/download/$id",
        saveInPublicStorage: true,
        savedDir: folder,
        showNotification: true,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "Currency-Code": SystemConfig.systemCurrency!.code!,
          "Currency-Exchange-Rate": SystemConfig.systemCurrency!.exchangeRate
              .toString(),
          "App-Language": app_language.$!,
          "System-Key": AppConfig.system_key,
        },
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        print('error:$e');
      }
    }
  }

  Future<String> createFolder() async {
    var mPath = "storage/emulated/0/Download/";
    if (Platform.isIOS) {
      var iosPath = await getApplicationDocumentsDirectory();
      mPath = iosPath.path;
    }
    final dir = Directory(mPath);

    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    if ((await dir.exists())) {
      return dir.path;
    } else {
      await dir.create();
      return dir.path;
    }
  }

  fetchAll() {
    fetchOrderDetails();
    fetchOrderedItems();
  }

  fetchOrderDetails() async {
    var orderDetailsResponse = await OrderRepository().getOrderDetails(
      id: widget.id,
    );

    if (orderDetailsResponse.detailed_orders.length > 0) {
      _orderDetails = orderDetailsResponse.detailed_orders[0];
      setStepIndex(_orderDetails!.delivery_status);
    }

    setState(() {});
  }

  setStepIndex(key) {
    _stepIndex = _steps.indexOf(key);
    setState(() {});
  }

  fetchOrderedItems() async {
    var orderItemResponse = await OrderRepository().getOrderItems(
      id: widget.id,
    );
    _orderedItemList.addAll(orderItemResponse.ordered_items);
    _orderItemsInit = true;

    setState(() {});
  }

  reset() {
    _stepIndex = 0;
    _orderDetails = null;
    _orderedItemList.clear();
    _orderItemsInit = false;
    setState(() {});
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchAll();
  }

  _onPressCancelOrder(id) async {
    Loading.show(context);
    var response = await OrderRepository().cancelOrder(id: id);
    Loading.close();
    if (response.result) {
      _onPageRefresh();
    }
    ToastComponent.showDialog(response.message);
  }

  _onPressReorder(id) async {
    Loading.show(context);
    var response = await OrderRepository().reOrder(id: id);
    Loading.close();
    Widget successWidget = SizedBox.shrink();
    if (response.successMsgs != null && response.successMsgs!.isNotEmpty) {
      successWidget = Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: .3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                response.successMsgs!.join("\n"),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.green[900],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Build Failed Widget (Red Box)
    Widget failedWidget = SizedBox.shrink();
    if (response.failedMsgs != null && response.failedMsgs!.isNotEmpty) {
      failedWidget = Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                response.failedMsgs!.join("\n"),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red[900],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3. Show the AlertDialog
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.info_outline, color: MyTheme.accent_color),
              SizedBox(width: 10),
              Text(
                "Reorder Status",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MyTheme.dark_font_grey,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [successWidget, failedWidget],
          ),
          actions: [
            // Cancel / Close Button
            TextButton(
              child: Text("Close", style: TextStyle(color: MyTheme.font_grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),

            if (response.successMsgs != null &&
                response.successMsgs!.isNotEmpty)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyTheme.accent_color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Go to Cart",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return Cart(hasBottomnav: false);
                      },
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  _showCancelDialog(id) {
    return ConfirmDialog.show(
      context,
      title: "Please ensure us.",
      message: "Do you want to cancel this order?",
      yesText: "Yes",
      noText: "No",
      pressYes: () {
        _onPressCancelOrder(id);
      },
    );
  }

  _makeRePayment(amount) {
    String currencyPattern = r"^[A-Z]{3}(?:[,.]?)";
    amount.replaceAll(RegExp(currencyPattern), "");

    double convertToDouble(String amountStr) {
      String amountWithoutCurrency = amountStr.replaceAll(
        RegExp(currencyPattern),
        "",
      );

      try {
        return double.parse(amountWithoutCurrency.replaceAll(",", ""));
      } on FormatException catch (e) {
        if (kDebugMode) {
          print('Error parsing amount: $e');
        }
        return double.nan;
      }
    }

    double convertedAmount = convertToDouble(amount);
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Checkout(
          title: "Order Re Payment",
          rechargeAmount: convertedAmount,
          paymentFor: PaymentFor.orderRePayment,
          packageId: 0,
          orderId: _orderDetails!.id,
        ),
      ),
    );
  }

  onPressOfflinePaymentButton() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Checkout(
            orderId: widget.id,
            title: AppLocalizations.of(context)!.checkout_ucf,
            list: "offline",
            paymentFor: PaymentFor.manualPayment,
            rechargeAmount: double.parse(
              _orderDetails!.plane_grand_total.toString(),
            ),
          );
        },
      ),
    ).then((value) {
      onPopped(value);
    });
  }

  onTapAskRefund(itemId, itemName, orderCode) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: MyTheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              insetPadding: EdgeInsets.symmetric(horizontal: 24),
              contentPadding: EdgeInsets.only(
                top: 36.0,
                left: 36.0,
                right: 36.0,
                bottom: 2.0,
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Text(
                              "${AppLocalizations.of(context)!.product_name_ucf}:",

                              style: TextStyle(
                                color: MyTheme.font_grey,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(
                              width: 200,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  itemName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: TextStyle(
                                    color: MyTheme.font_grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            headingText(
                              AppLocalizations.of(context)!.order_code_ucf,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                orderCode,
                                style: TextStyle(
                                  color: MyTheme.font_grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Text(
                              "${AppLocalizations.of(context)!.reason_ucf} *",
                              style: TextStyle(
                                color: MyTheme.font_grey,
                                fontSize: 12,
                              ),
                            ),
                            _showReasonWarning
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.reason_cannot_be_empty,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: SizedBox(
                          // height: 55,
                          child: TextField(
                            controller: _refundReasonController,
                            autofocus: false,
                            minLines: 2,
                            maxLines: 7,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(
                                context,
                              )!.enter_reason_ucf,
                              hintStyle: TextStyle(
                                fontSize: 12.0,
                                color: MyTheme.textfield_grey,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: MyTheme.textfield_grey,
                                  width: 0.5,
                                ),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: MyTheme.textfield_grey,
                                  width: 1.0,
                                ),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              contentPadding: EdgeInsets.only(
                                left: 8.0,
                                top: 16.0,
                                bottom: 16.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Btn.minWidthFixHeight(
                        minWidth: 75,
                        height: 30,
                        color: Color.fromRGBO(253, 253, 253, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(
                            color: MyTheme.light_grey,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.close_all_capital,
                          style: TextStyle(color: MyTheme.font_grey),
                        ),
                        onPressed: () {
                          _refundReasonController.clear();
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Btn.minWidthFixHeight(
                        minWidth: 75,
                        height: 30,
                        color: MyTheme.accent_color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(
                            color: MyTheme.light_grey,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.submit_ucf,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          onPressSubmitRefund(itemId, setState);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  shoWReasonWarning(setState) {
    setState(() {
      _showReasonWarning = true;
    });
  }

  onPressSubmitRefund(itemId, setState) async {
    var reason = _refundReasonController.text.toString();

    if (reason == "") {
      shoWReasonWarning(setState);
      return;
    }

    var refundRequestSendResponse = await RefundRequestRepository()
        .getRefundRequestSendResponse(id: itemId, reason: reason);

    if (refundRequestSendResponse.result == false) {
      ToastComponent.showDialog(refundRequestSendResponse.message);
      return;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    _refundReasonController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          refundRequestSendResponse.message,
          style: TextStyle(color: MyTheme.font_grey),
        ),
        backgroundColor: MyTheme.soft_accent_color,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.show_request_list_ucf,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return RefundRequest();
                },
              ),
            ).then((value) {
              onPopped(value);
            });
          },
          textColor: MyTheme.accent_color,
          disabledTextColor: Colors.grey,
        ),
      ),
    );

    reset();
    fetchAll();
    setState(() {});
  }

  onPopped(value) async {
    reset();
    fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !(widget.fromNotification || widget.goBack == false),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && (widget.fromNotification || widget.goBack == false)) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => Main()),
            (route) => false,
          );
        }
      },
      child: Directionality(
        textDirection: app_language_rtl.$!
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: buildAppBar(context),
          body: RefreshIndicator(
            color: MyTheme.accent_color,
            backgroundColor: Colors.white,
            onRefresh: _onPageRefresh,
            child: CustomScrollView(
              controller: _mainScrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18.0,
                      //  vertical: 20.0,
                    ),
                    child: _orderDetails != null
                        ? buildTimeLineTiles()
                        : buildTimeLineShimmer(),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([buildActionButton()]),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 18.0,
                        right: 18.0,
                        bottom: 0.0,
                      ),
                      child: _orderDetails != null
                          ? buildOrderDetailsTopCard()
                          : ShimmerHelper().buildBasicShimmer(height: 150.0),
                    ),
                  ]),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!.ordered_product_ucf,
                        style: TextStyle(
                          color: MyTheme.blackColour,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 18.0,
                        right: 18.0,
                        top: 0.0,
                      ),
                      child: _orderedItemList.isEmpty && _orderItemsInit
                          ? ShimmerHelper().buildBasicShimmer(height: 100.0)
                          : (_orderedItemList.isNotEmpty
                                ? buildOrderdProductList()
                                : SizedBox(
                                    height: 100,
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.ordered_product_ucf,
                                      style: TextStyle(
                                        color: MyTheme.font_grey,
                                      ),
                                    ),
                                  )),
                    ),
                  ]),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25.0,
                        vertical: 20,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Container(width: 75), buildBottomSection()],
                      ),
                    ),
                  ]),
                ),

                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: buildCancleOrPaymentButton(),
                    ),

                    Container(height: 40),
                    SizedBox(
                      height: MediaQuery.of(context).viewPadding.bottom > 0
                          ? MediaQuery.of(context).viewPadding.bottom
                          : 20,
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  buildBottomSection() {
    bool isGst = false;

    if (_orderedItemList.isNotEmpty &&
        _orderedItemList[0].gst_applicable == 1) {
      isGst = true;
    } else if (gst_addon_installed.$ == true) {
      isGst = true;
    }
    var taxValueToShow = convertPrice(_orderDetails?.tax ?? "0");
    if (_orderDetails?.gst_amount != null &&
        _orderDetails!.gst_amount!.isNotEmpty &&
        _orderDetails!.gst_amount != convertPrice("0")) {
      taxValueToShow = _orderDetails!.gst_amount!;
    }

    double discountValue = 0.0;
    try {
      if (_orderDetails != null && _orderDetails!.coupon_discount != null) {
        String cleanDiscount = _orderDetails!.coupon_discount!.replaceAll(
          RegExp(r'[^0-9.]'),
          '',
        );
        discountValue = double.tryParse(cleanDiscount) ?? 0.0;
      }
    } catch (e) {
      discountValue = 0.0;
    }

    return Expanded(
      child: _orderDetails != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _priceRow(
                  context,
                  label: AppLocalizations.of(context)!.sub_total_all_capital,
                  value: convertPrice(_orderDetails!.subtotal!),
                ),
                _priceRow(
                  context,
                  label: isGst
                      ? "GST"
                      : AppLocalizations.of(context)!.tax_all_capital,
                  value: convertPrice(taxValueToShow),
                ),
                _priceRow(
                  context,
                  label: AppLocalizations.of(
                    context,
                  )!.shipping_cost_all_capital,
                  value: convertPrice(_orderDetails!.shipping_cost!),
                ),

                if (discountValue > 0)
                  _priceRow(
                    context,
                    label: AppLocalizations.of(context)!.discount_all_capital,
                    value: convertPrice(_orderDetails!.coupon_discount!),
                  ),

                const Divider(),

                _priceRow(
                  context,
                  label: AppLocalizations.of(context)!.grand_total_all_capital,
                  value: convertPrice(_orderDetails!.grand_total!),
                  valueColor: MyTheme.accent_color,
                ),
              ],
            )
          : ShimmerHelper().buildBasicShimmer(height: 100.0),
    );
  }

  buildTimeLineShimmer() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: ShimmerHelper().buildBasicShimmer(height: 40, width: 40.0),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: ShimmerHelper().buildBasicShimmer(height: 40, width: 40.0),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: ShimmerHelper().buildBasicShimmer(height: 40, width: 40.0),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: ShimmerHelper().buildBasicShimmer(height: 40, width: 40.0),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: ShimmerHelper().buildBasicShimmer(height: 20, width: 250.0),
        ),
      ],
    );
  }

  buildTimeLineTiles() {
    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STEP 1: Order Placed
          Expanded(
            child: TimelineTile(
              axis: TimelineAxis.horizontal,
              alignment: TimelineAlign.start,
              isFirst: true,
              endChild: _orderDetails!.delivery_status == "pending"
                  ? Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        AppLocalizations.of(context)!.order_placed,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: MyTheme.blackColour,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
              indicatorStyle: IndicatorStyle(
                color: _stepIndex >= 0 ? Colors.green : MyTheme.medium_grey,
                height: 30,
                width: 30,
                padding: const EdgeInsets.all(0),
                indicator: Container(
                  decoration: BoxDecoration(
                    color: _stepIndex >= 0 ? Colors.green : MyTheme.medium_grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _orderDetails!.delivery_status == "pending"
                          ? Colors.green
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.list_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              afterLineStyle: _stepIndex >= 1
                  ? const LineStyle(color: Colors.green, thickness: 4)
                  : LineStyle(color: MyTheme.medium_grey, thickness: 3),
            ),
          ),

          // ----------------------------------------------------------------
          // STEP 2: Confirmed
          // ----------------------------------------------------------------
          Expanded(
            child: TimelineTile(
              axis: TimelineAxis.horizontal,
              alignment: TimelineAlign.start,
              endChild: _orderDetails!.delivery_status == "confirmed"
                  ? Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        AppLocalizations.of(context)!.confirmed_ucf,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: MyTheme.blackColour,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
              indicatorStyle: IndicatorStyle(
                color: _stepIndex >= 1 ? Colors.green : MyTheme.medium_grey,
                height: 30,
                width: 30,
                padding: const EdgeInsets.all(0),
                indicator: Container(
                  decoration: BoxDecoration(
                    color: _stepIndex >= 1 ? Colors.green : MyTheme.medium_grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _orderDetails!.delivery_status == "confirmed"
                          ? Colors.blue
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.thumb_up_sharp,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              beforeLineStyle: _stepIndex >= 1
                  ? const LineStyle(color: Colors.green, thickness: 4)
                  : LineStyle(color: MyTheme.medium_grey, thickness: 3),
              afterLineStyle: _stepIndex >= 2
                  ? const LineStyle(color: Colors.green, thickness: 4)
                  : LineStyle(color: MyTheme.medium_grey, thickness: 3),
            ),
          ),

          // ----------------------------------------------------------------
          // STEP 3: On The Way
          // ----------------------------------------------------------------
          Expanded(
            child: TimelineTile(
              axis: TimelineAxis.horizontal,
              alignment: TimelineAlign.start,
              endChild:
                  (_orderDetails!.delivery_status == "on_the_way" ||
                      _orderDetails!.delivery_status == "picked_up" ||
                      _orderDetails!.delivery_status == "on_delivery")
                  ? Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        AppLocalizations.of(context)!.on_the_way_ucf,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: MyTheme.blackColour,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
              indicatorStyle: IndicatorStyle(
                color: _stepIndex >= 2 ? Colors.green : MyTheme.medium_grey,
                height: 30,
                width: 30,
                padding: const EdgeInsets.all(0),
                indicator: Container(
                  decoration: BoxDecoration(
                    color: _stepIndex >= 2 ? Colors.green : MyTheme.medium_grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          (_orderDetails!.delivery_status == "on_the_way" ||
                              _orderDetails!.delivery_status == "picked_up" ||
                              _orderDetails!.delivery_status == "on_delivery")
                          ? Colors.green
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              beforeLineStyle: _stepIndex >= 2
                  ? const LineStyle(color: Colors.green, thickness: 4)
                  : LineStyle(color: MyTheme.medium_grey, thickness: 3),
              afterLineStyle: _stepIndex >= 5
                  ? const LineStyle(color: Colors.green, thickness: 4)
                  : LineStyle(color: MyTheme.medium_grey, thickness: 3),
            ),
          ),

          // ----------------------------------------------------------------
          // STEP 4: Delivered
          // ----------------------------------------------------------------
          Expanded(
            child: TimelineTile(
              axis: TimelineAxis.horizontal,
              alignment: TimelineAlign.start,
              isLast: true,
              endChild: _orderDetails!.delivery_status == "delivered"
                  ? Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        AppLocalizations.of(context)!.delivered_ucf,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: MyTheme.blackColour,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
              indicatorStyle: IndicatorStyle(
                color: _stepIndex >= 5 ? Colors.green : MyTheme.medium_grey,
                height: 30,
                width: 30,
                padding: const EdgeInsets.all(0),
                indicator: Container(
                  decoration: BoxDecoration(
                    color: _stepIndex >= 5 ? Colors.green : MyTheme.medium_grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _orderDetails!.delivery_status == "delivered"
                          ? Colors.green
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.done_all,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              beforeLineStyle: _stepIndex >= 5
                  ? const LineStyle(color: Colors.green, thickness: 4)
                  : LineStyle(color: MyTheme.medium_grey, thickness: 3),
            ),
          ),
        ],
      ),
    );
  }

  buildActionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Row(
        children: [
          //  Reorder Button
          Expanded(
            child: Btn.basic(
              padding: EdgeInsets.zero,
              onPressed: () {
                _onPressReorder(_orderDetails!.id);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MyTheme.light_grey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, color: MyTheme.grey_153, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      LangText(context).local.re_order_ucf,
                      style: TextStyle(color: MyTheme.grey_153, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 15),

          // Invoice Button
          Expanded(
            child: Btn.basic(
              padding: EdgeInsets.zero,
              onPressed: () {
                _downloadInvoice(_orderDetails!.id);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MyTheme.light_grey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.file_download_outlined,
                      color: MyTheme.grey_153,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      LangText(context).local.invoice_ucf,
                      style: TextStyle(color: MyTheme.grey_153, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  buildOrderDetailsTopCard() {
    return Container(
      decoration: BoxDecorations.buildBoxDecoration_1(),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                headingText(AppLocalizations.of(context)!.order_code_ucf),
                Spacer(),
                headingText(AppLocalizations.of(context)!.shipping_method_ucf),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(
                    _orderDetails!.code!,
                    style: TextStyle(
                      color: MyTheme.accent_color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  hedingValue(_orderDetails!.shipping_type_string!),
                ],
              ),
            ),

            // Order Date and Payment Method Row
            Row(
              children: [
                headingText(AppLocalizations.of(context)!.order_date_ucf),
                Spacer(),
                headingText(AppLocalizations.of(context)!.payment_method_ucf),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  hedingValue(_orderDetails!.date!),
                  Spacer(),
                  hedingValue(_orderDetails!.payment_type!),
                ],
              ),
            ),

            // Seller Address, GSTIN, and Delivery Status / Payment Status Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Seller Address and GSTIN
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      headingText('Seller Address'),
                      const SizedBox(height: 2),
                      Text(_orderDetails!.seller_address!, style: addressStyle),
                      const SizedBox(height: 5),

                      if (_orderDetails!.gstin != null &&
                          _orderDetails!.gstin!.trim().isNotEmpty &&
                          _orderDetails!.gst_amount != null &&
                          _orderDetails!.gst_amount!.trim().isNotEmpty &&
                          _orderDetails!.gst_amount != convertPrice("0"))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            headingText("GSTIN"),
                            Text(
                              _orderDetails!.gstin!,
                              maxLines: 2,
                              style: addressStyle,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Right Column: Delivery Status and Payment Status
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Delivery Status
                      headingText(
                        AppLocalizations.of(context)!.delivery_status_ucf,
                      ),
                      const SizedBox(height: 2),
                      hedingValue(_orderDetails!.delivery_status_string!),

                      const SizedBox(height: 8),

                      // Payment Status
                      headingText(
                        AppLocalizations.of(context)!.payment_status_ucf,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          hedingValue(_orderDetails!.payment_status_string!),
                          const SizedBox(width: 4),
                          buildPaymentStatusCheckContainer(
                            _orderDetails!.payment_status,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Total Amount Row
            Row(
              mainAxisAlignment: .end,
              children: [
                // Right side: Total Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    headingText(AppLocalizations.of(context)!.total_amount_ucf),
                    Text(
                      convertPrice(_orderDetails!.grand_total!),
                      style: TextStyle(
                        color: MyTheme.accent_color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: DashedDivider(),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_orderDetails!.shipping_address != null) ...[
                  if (_orderDetails!.shipping_address!.name != null)
                    Text(
                      "${_orderDetails!.shipping_address!.name}",
                      style: addressStyle.copyWith(fontWeight: FontWeight.bold),
                    ),
                  if (_orderDetails!.shipping_address!.email != null)
                    Text(
                      "${_orderDetails!.shipping_address!.email}",
                      style: addressStyle.copyWith(fontWeight: FontWeight.bold),
                    ),
                ] else if (_orderDetails!.pickupPoint != null &&
                    _orderDetails!.pickupPoint!.name != null) ...[
                  Text(
                    "${AppLocalizations.of(context)!.name_ucf}: ${_orderDetails!.pickupPoint!.name}",
                    style: addressStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
            // Shipping & Billing Details
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //  LEFT SIDE: Shipping Info -----
                  Expanded(
                    child: _orderDetails!.shipping_address != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              headingText(
                                _orderDetails!.shipping_address != null
                                    ? AppLocalizations.of(
                                        context,
                                      )!.shipping_address_ucf
                                    : AppLocalizations.of(
                                        context,
                                      )!.pickup_point_ucf,
                              ),
                              Text(
                                "${_orderDetails!.shipping_address!.address}",
                                maxLines: 3,
                                style: addressStyle,
                              ),
                              Text(
                                "${AppLocalizations.of(context)!.city_ucf}: ${_orderDetails!.shipping_address!.city}",
                                maxLines: 3,
                                style: addressStyle,
                              ),
                              Text(
                                "${AppLocalizations.of(context)!.country_ucf}: ${_orderDetails!.shipping_address!.country}",
                                maxLines: 3,
                                style: addressStyle,
                              ),
                              Text(
                                "${AppLocalizations.of(context)!.state_ucf}: ${_orderDetails!.shipping_address!.state}",
                                maxLines: 3,
                                style: addressStyle,
                              ),
                              Text(
                                _orderDetails!.shipping_address!.phone ?? '',
                                maxLines: 3,
                                style: addressStyle,
                              ),
                              Text(
                                "${AppLocalizations.of(context)!.postal_code}: ${_orderDetails!.shipping_address!.postal_code ?? ''}",
                                maxLines: 3,
                                style: addressStyle,
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${AppLocalizations.of(context)!.address_ucf}: ${_orderDetails!.pickupPoint!.address}",
                                maxLines: 3,
                                style: TextStyle(color: MyTheme.grey_153),
                              ),
                              Text(
                                "${AppLocalizations.of(context)!.phone_ucf}: ${_orderDetails!.pickupPoint!.phone}",
                                maxLines: 3,
                                style: TextStyle(color: MyTheme.grey_153),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(width: 15),

                  // RIGHT SIDE: Billing Info -----
                  Expanded(
                    child: _orderDetails!.billing_address != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              headingText('Billing Address'),
                              const SizedBox(height: 4),
                              Text(
                                " ${_orderDetails!.billing_address!.address}",
                                maxLines: 3,
                                style: addressStyle,
                              ),
                              Text(
                                "${AppLocalizations.of(context)!.city_ucf}: ${_orderDetails!.billing_address!.city}",
                                maxLines: 3,
                                style: addressStyle,
                              ),
                              Text(
                                "${AppLocalizations.of(context)!.country_ucf}: ${_orderDetails!.billing_address!.country}",
                                maxLines: 3,
                                style: addressStyle,
                              ),
                              Text(
                                "${AppLocalizations.of(context)!.state_ucf}: ${_orderDetails!.billing_address!.state}",
                                maxLines: 3,
                                style: addressStyle,
                              ),
                              Text(
                                _orderDetails!.billing_address!.phone ?? '',
                                maxLines: 3,
                                style: addressStyle,
                              ),
                              Text(
                                "${AppLocalizations.of(context)!.postal_code}: ${_orderDetails!.billing_address!.postal_code ?? ''}",
                                maxLines: 3,
                                style: addressStyle,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildOrderedProductItemsCard(index) {
    final item = _orderedItemList[index];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// PRODUCT NAME + PRICE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "${item.quantity} x ${item.product_name}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: MyTheme.blackColour,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                convertPrice(item.price),
                style: TextStyle(
                  color: MyTheme.accent_color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// VARIATION
              Expanded(
                child:
                    item.variation != null &&
                        item.variation.toString().isNotEmpty
                    ? RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "Variation: ",
                              style: TextStyle(
                                color: MyTheme.grey_153,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: item.variation,
                              style: const TextStyle(
                                color: MyTheme.grey_153,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              /// ASK FOR REFUND
              if (item.refund_section && item.refund_button)
                InkWell(
                  onTap: () {
                    onTapAskRefund(
                      item.id,
                      item.product_name,
                      _orderDetails!.code,
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.ask_for_refund_ucf,
                        style: TextStyle(
                          color: MyTheme.accent_color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.rotate_left,
                        size: 14,
                        color: MyTheme.accent_color,
                      ),
                    ],
                  ),
                )
              /// REFUND STATUS
              else if (item.refund_section &&
                  item.refund_label != null &&
                  item.refund_label!.trim().isNotEmpty)
                RichText(
                  textAlign: TextAlign.end,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text:
                            "${AppLocalizations.of(context)!.refund_status_ucf}: ",
                        style: const TextStyle(
                          color: MyTheme.font_grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: item.refund_label!,
                        style: TextStyle(
                          fontSize: 12,
                          color: getRefundRequestLabelColor(
                            item.refund_request_status,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  getRefundRequestLabelColor(status) {
    if (status == 0) {
      return Colors.blue;
    } else if (status == 2) {
      return Colors.orange;
    } else if (status == 1) {
      return Colors.green;
    } else {
      return MyTheme.font_grey;
    }
  }

  buildOrderdProductList() {
    return Container(
      decoration: BoxDecorations.buildBoxDecoration_1(),
      child: SingleChildScrollView(
        child: ListView.separated(
          separatorBuilder: (context, index) => DashedDivider(),
          itemCount: _orderedItemList.length,
          scrollDirection: Axis.vertical,
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return buildOrderedProductItemsCard(index);
          },
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,

      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () {
            if (widget.fromNotification || widget.goBack == false) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return Main();
                  },
                ),
              );
            } else {
              return Navigator.of(context).pop();
            }
          },
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.order_details_ucf,
        style: TextStyle(
          fontSize: 16,
          color: MyTheme.dark_font_grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  Widget buildCancleOrPaymentButton() {
    if (_orderDetails == null) {
      return const SizedBox.shrink();
    }

    if (_orderDetails!.delivery_status == "pending" &&
        _orderDetails!.payment_status == "unpaid") {
      bool isManualPayment = _orderDetails!.manually_payable ?? false;

      return Row(
        children: [
          Expanded(
            child: Btn.basic(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: MyTheme.font_grey,
              onPressed: () {
                if (_orderDetails?.id != null) {
                  _showCancelDialog(_orderDetails!.id);
                }
              },
              child: Text(
                LangText(context).local.cancel_order_ucf,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Btn.basic(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: MyTheme.accent_color,
              onPressed: () {
                if (isManualPayment) {
                  onPressOfflinePaymentButton();
                } else {
                  if (_orderDetails?.grand_total != null) {
                    _makeRePayment(_orderDetails!.grand_total);
                  }
                }
              },
              child: Text(
                isManualPayment
                    ? AppLocalizations.of(context)!.make_offline_payment_ucf
                    : LangText(context).local.make_payment_ucf,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Container buildPaymentStatusCheckContainer(String? paymentStatus) {
    return Container(
      height: 16,
      width: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: paymentStatus == "paid" ? Colors.green : Colors.red,
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(
          paymentStatus == "paid" ? Icons.check : Icons.check,
          color: Colors.white,
          size: 10,
        ),
      ),
    );
  }

  Widget _priceRow(
    BuildContext context, {
    required String label,
    required String value,
    Color valueColor = Colors.black,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: MyTheme.blackColour,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Text headingText(text) {
    return Text(
      text,
      style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: .bold),
    );
  }

  Text hedingValue(text) {
    return Text(text, style: TextStyle(color: Colors.black));
  }

  TextStyle addressStyle = TextStyle(color: Colors.black, fontSize: 12);
}

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName(
    'downloader_send_port',
  );
  send?.send([id, status, progress]);
}
