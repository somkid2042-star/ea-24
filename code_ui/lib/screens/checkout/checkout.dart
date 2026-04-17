import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/enum_classes.dart';
import 'package:active_ecommerce_cms_demo_app/custom/lang_text.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/cart_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/coupon_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/payment_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/orders/order_list.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/amarpay_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/bkash_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/flutterwave_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/iyzico_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/khalti_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/my_fatoora_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/nagad_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/offline_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/online_pay.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/payfast_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/paypal_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/paystack_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/paytm_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/razorpay_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/sslcommerz_screen.dart';
import 'package:active_ecommerce_cms_demo_app/screens/payment_method_screen/stripe_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:one_context/one_context.dart';

import '../../custom/loading.dart';
import '../../helpers/auth_helper.dart';
import '../../repositories/guest_checkout_repository.dart';
import '../guest_checkout_pages/guest_checkout_address.dart';

import '../payment_method_screen/cybersource_screen.dart';
import '../payment_method_screen/phonepay_screen.dart';

class Checkout extends StatefulWidget {
  final int? orderId;
  final String list;
  final PaymentFor? paymentFor;
  final double rechargeAmount;
  final String? title;
  final dynamic packageId;
  final String? guestCheckOutShippingAddress;

  const Checkout({
    super.key,
    this.guestCheckOutShippingAddress,
    this.orderId = 0,
    this.paymentFor,
    this.list = "both",
    this.rechargeAmount = 0.0,
    this.title,
    this.packageId = 0,
  });

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var _selectedPaymentMethodIndex = 0;
  String? _selectedPaymentMethod = "";
  String? _selectedPaymentMethodKey = "";

  final ScrollController _mainScrollController = ScrollController();
  final TextEditingController _couponController = TextEditingController();
  final _paymentTypeList = [];
  bool _isInitial = true;
  String? _totalString = ". . .";
  double? _grandTotalValue = 0.00;
  String? _subTotalString = ". . .";
  String? _taxString = ". . .";
  String? _gstString = ". . .";
  String _shippingCostString = ". . .";
  String? _discountString = ". . .";
  String _usedCouponCode = "";
  bool? _couponApplied = false;
  late BuildContext loadingcontext;
  String paymentType = "cart_payment";
  String? _title;

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_title == null) {
      if (widget.paymentFor == PaymentFor.walletRecharge) {
        _title = AppLocalizations.of(context)!.recharge_wallet_ucf;
      } else if (widget.paymentFor == PaymentFor.packagePay) {
        _title = AppLocalizations.of(context)!.buy_package_ucf;
      } else if (widget.paymentFor == PaymentFor.orderRePayment) {
        _title = AppLocalizations.of(context)!.re_order_ucf;
      } else if (widget.paymentFor == PaymentFor.manualPayment) {
        _title = AppLocalizations.of(context)!.make_offline_payment_ucf;
      } else {
        _title = AppLocalizations.of(context)!.checkout_ucf;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _mainScrollController.dispose();
  }

  String balance() {
    String? displayValue;

    if (widget.paymentFor == PaymentFor.manualPayment ||
        widget.paymentFor == PaymentFor.walletRecharge ||
        widget.paymentFor == PaymentFor.packagePay ||
        widget.paymentFor == PaymentFor.orderRePayment) {
      displayValue = SystemConfig.systemCurrency != null
          ? "${SystemConfig.systemCurrency!.symbol!} ${widget.rechargeAmount.toStringAsFixed(2)}"
          : widget.rechargeAmount.toStringAsFixed(2);
    } else {
      displayValue = SystemConfig.systemCurrency != null
          ? _totalString?.replaceAll(
              SystemConfig.systemCurrency!.code!,
              SystemConfig.systemCurrency!.symbol!,
            )
          : _totalString;
    }

    return displayValue ?? '';
  }

  fetchAll() async {
    String mode = '';
    setState(() {
      mode =
          widget.paymentFor != PaymentFor.order &&
              widget.paymentFor != PaymentFor.manualPayment
          ? "wallet"
          : "order";
    });

    // Fetch payment list first
    var paymentTypeResponseList = await PaymentRepository()
        .getPaymentResponseList(list: widget.list, mode: mode);

    _paymentTypeList.clear();
    _paymentTypeList.addAll(paymentTypeResponseList);
    if (_paymentTypeList.isNotEmpty) {
      _selectedPaymentMethod = _paymentTypeList[0].paymentType;
      _selectedPaymentMethodKey = _paymentTypeList[0].paymentTypeKey;
    }
    _isInitial = false;
    setState(() {});

    await fetchSummary();

    if (widget.paymentFor == PaymentFor.walletRecharge ||
        widget.paymentFor == PaymentFor.packagePay ||
        widget.paymentFor == PaymentFor.orderRePayment ||
        widget.paymentFor == PaymentFor.manualPayment) {
      setState(() {
        _grandTotalValue = widget.rechargeAmount;
      });
      if (widget.paymentFor == PaymentFor.orderRePayment) {
        paymentType = 'order_re_payment';
      } else if (widget.paymentFor == PaymentFor.walletRecharge) {
        paymentType = "wallet_payment";
      } else if (widget.paymentFor == PaymentFor.packagePay) {
        paymentType = "customer_package_payment";
      } else if (widget.paymentFor == PaymentFor.manualPayment) {}
    } else {
      paymentType = 'cart_payment';
    }
    setState(() {});
  }

  fetchSummary() async {
    var cartSummaryResponse = await CartRepository().getCartSummaryResponse();

    if (cartSummaryResponse != null) {
      setState(() {
        _subTotalString = cartSummaryResponse.subTotal;
        _taxString = cartSummaryResponse.tax;
        _shippingCostString = cartSummaryResponse.shippingCost;
        _discountString = cartSummaryResponse.discount;
        _totalString = cartSummaryResponse.grandTotal;
        _grandTotalValue = cartSummaryResponse.grandTotalValue;
        _usedCouponCode = cartSummaryResponse.couponCode ?? _usedCouponCode;
        _couponController.text = _usedCouponCode;
        _couponApplied = cartSummaryResponse.couponApplied;
        _gstString = cartSummaryResponse.gst;
      });
    }
  }

  reset() {
    _paymentTypeList.clear();
    _isInitial = true;
    _selectedPaymentMethodIndex = 0;
    _selectedPaymentMethod = "";
    _selectedPaymentMethodKey = "";
    setState(() {});

    resetSummary();
  }

  resetSummary() {
    _totalString = ". . .";
    _grandTotalValue = 0.00;
    _subTotalString = ". . .";
    _taxString = ". . .";
    _shippingCostString = ". . .";
    _discountString = ". . .";
    _usedCouponCode = "";
    _couponController.text = _usedCouponCode;
    _couponApplied = false;
    _gstString = ". . .";
    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    await fetchAll();
  }

  onPopped(value) {
    fetchAll();
  }

  onCouponApply() async {
    var couponCode = _couponController.text.toString();
    if (couponCode == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_coupon_code,
      );
      return;
    }

    var couponApplyResponse = await CouponRepository().getCouponApplyResponse(
      couponCode,
    );
    if (couponApplyResponse.result == false) {
      ToastComponent.showDialog(couponApplyResponse.message);
      return;
    }

    resetSummary();
    await fetchSummary();
  }

  onCouponRemove() async {
    var couponRemoveResponse = await CouponRepository()
        .getCouponRemoveResponse();

    if (couponRemoveResponse.result == false) {
      ToastComponent.showDialog(couponRemoveResponse.message);
      return;
    }

    resetSummary();
    await fetchSummary();
  }

  onPressPlaceOrderOrProceed() async {
    if (guest_checkout_status.$ && !is_logged_in.$) {
      Loading.show(context);
      // guest checkout user create response
      var guestUserAccountCreateResponse = await GuestCheckoutRepository()
          .guestUserAccountCreate(widget.guestCheckOutShippingAddress);
      Loading.close();

      AuthHelper().setUserData(guestUserAccountCreateResponse);
      if (!mounted) return;

      if (!guestUserAccountCreateResponse.result!) {
        ToastComponent.showDialog(LangText(context).local.already_have_account);

        Navigator.pushAndRemoveUntil(
          OneContext().context!,
          MaterialPageRoute(
            builder: (context) {
              return GuestCheckoutAddress();
            },
          ),
          (Route<dynamic> route) => true,
        );
        return;
      }
    }

    if (_selectedPaymentMethod == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.please_choose_one_option_to_pay,
      );
      return;
    }
    if (_grandTotalValue == null || _grandTotalValue! <= 0.00) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.nothing_to_pay);
      return;
    }

    if (_selectedPaymentMethod == "bkash") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return BkashScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    }
    if (_selectedPaymentMethod == "stripe") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return StripeScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    }
    if (_selectedPaymentMethod == "aamarpay") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return AmarpayScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethod == "paypal") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return PaypalScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethod == "razorpay") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return RazorpayScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethod == "paystack") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return PaystackScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethod == "iyzico") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return IyzicoScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethod == "iyzico") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return MyFatooraScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    }
    if (_selectedPaymentMethod == "cybersource") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return CybersourceScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethod == "bkash") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return BkashScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethod == "nagad") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return NagadScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethod == "sslcommerz") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return SslCommerzScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethod == "flutterwave") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return FlutterwaveScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethod == "paytm") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return PaytmScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethod == "khalti") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return KhaltiScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethod == "instamojo") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return OnlinePay(
              title: LangText(context).local.pay_with_instamojo,
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethod == "payfast") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return PayfastScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethod == "phonepe") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return PhonePeScreen(
              amount: _grandTotalValue,
              paymentType: paymentType,
              paymentMethodKey: _selectedPaymentMethodKey,
              packageId: widget.packageId.toString(),
              orderId: widget.orderId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    } else if (_selectedPaymentMethod == "wallet_system") {
      payByWallet();
    } else if (_selectedPaymentMethod == "cash_payment") {
      payByCod();
    } else if (_selectedPaymentMethod == "manual_payment" &&
        widget.paymentFor == PaymentFor.order) {
      payByManualPayment();
    } else if (_selectedPaymentMethod == "manual_payment" &&
        (widget.paymentFor == PaymentFor.manualPayment ||
            widget.paymentFor == PaymentFor.walletRecharge ||
            widget.paymentFor == PaymentFor.packagePay)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return OfflineScreen(
              orderId: widget.orderId,
              paymentInstruction:
                  _paymentTypeList[_selectedPaymentMethodIndex].details,
              offlinePaymentId: _paymentTypeList[_selectedPaymentMethodIndex]
                  .offlinePaymentId,
              rechargeAmount: widget.rechargeAmount,
              offLinePaymentFor: widget.paymentFor,
              paymentMethod: _paymentTypeList[_selectedPaymentMethodIndex].name,
              packageId: widget.packageId,
            );
          },
        ),
      ).then((value) {
        onPopped(value);
      });
    }
  }

  payByWallet() async {
    loading();
    var orderCreateResponse = await PaymentRepository()
        .getOrderCreateResponseFromWallet(
          _selectedPaymentMethodKey,
          _grandTotalValue,
        );
    if (!mounted) return;
    Navigator.of(loadingcontext).pop();

    if (orderCreateResponse.result == false) {
      ToastComponent.showDialog(orderCreateResponse.message);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return OrderList(fromCheckout: true);
        },
      ),
    );
  }

  payByCod() async {
    loading();
    var orderCreateResponse = await PaymentRepository()
        .getOrderCreateResponseFromCod(_selectedPaymentMethodKey);
    if (!mounted) return;
    Navigator.of(loadingcontext).pop();
    if (orderCreateResponse.result == false) {
      ToastComponent.showDialog(orderCreateResponse.message);
      Navigator.of(context).pop();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return OrderList(fromCheckout: true);
        },
      ),
    );
  }

  payByManualPayment() async {
    loading();
    var orderCreateResponse = await PaymentRepository()
        .getOrderCreateResponseFromManualPayment(_selectedPaymentMethodKey);
    if (!mounted) return;
    Navigator.pop(loadingcontext);
    if (orderCreateResponse.result == false) {
      ToastComponent.showDialog(orderCreateResponse.message);
      Navigator.of(context).pop();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return OrderList(fromCheckout: true);
        },
      ),
    );
  }

  onPaymentMethodItemTap(index) {
    if (_selectedPaymentMethodKey != _paymentTypeList[index].paymentTypeKey) {
      setState(() {
        _selectedPaymentMethodIndex = index;
        _selectedPaymentMethod = _paymentTypeList[index].paymentType;
        _selectedPaymentMethodKey = _paymentTypeList[index].paymentTypeKey;
      });
    }
  }

  onPressDetails() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MyTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.only(
          top: 16.0,
          left: 2.0,
          right: 2.0,
          bottom: 2.0,
        ),
        content: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        AppLocalizations.of(context)!.subtotal_all_capital,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: MyTheme.font_grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Spacer(),
                    Text(
                      SystemConfig.systemCurrency != null
                          ? _subTotalString!.replaceAll(
                              SystemConfig.systemCurrency!.code!,
                              SystemConfig.systemCurrency!.symbol!,
                            )
                          : _subTotalString!,
                      style: TextStyle(
                        color: MyTheme.font_grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              taxOrGstRow(
                title: gst_addon_installed.$
                    ? 'GST'
                    : AppLocalizations.of(context)!.tax_all_capital,
                value: gst_addon_installed.$ ? _gstString! : _taxString!,
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        AppLocalizations.of(context)!.shipping_cost_all_capital,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: MyTheme.font_grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Spacer(),
                    Text(
                      SystemConfig.systemCurrency != null
                          ? _shippingCostString.replaceAll(
                              SystemConfig.systemCurrency!.code!,
                              SystemConfig.systemCurrency!.symbol!,
                            )
                          : _shippingCostString,
                      style: TextStyle(
                        color: MyTheme.font_grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        AppLocalizations.of(context)!.discount_all_capital,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: MyTheme.font_grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Spacer(),
                    Text(
                      SystemConfig.systemCurrency != null
                          ? _discountString!.replaceAll(
                              SystemConfig.systemCurrency!.code!,
                              SystemConfig.systemCurrency!.symbol!,
                            )
                          : _discountString!,
                      style: TextStyle(
                        color: MyTheme.font_grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        AppLocalizations.of(context)!.grand_total_all_capital,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: MyTheme.font_grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Spacer(),
                    Text(
                      SystemConfig.systemCurrency != null
                          ? _totalString!.replaceAll(
                              SystemConfig.systemCurrency!.code!,
                              SystemConfig.systemCurrency!.symbol!,
                            )
                          : _totalString!,
                      style: TextStyle(
                        color: MyTheme.accent_color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Btn.basic(
            child: Text(
              AppLocalizations.of(context)!.close_all_lower,
              style: TextStyle(color: MyTheme.medium_grey),
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: MyTheme.mainColor,
        appBar: buildAppBar(context),
        bottomNavigationBar: buildBottomAppBar(context),
        body: Stack(
          children: [
            RefreshIndicator(
              color: MyTheme.accent_color,
              backgroundColor: Colors.white,
              onRefresh: _onRefresh,
              displacement: 0,
              child: CustomScrollView(
                controller: _mainScrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: buildPaymentMethodList(),
                      ),
                      Container(height: 140),
                    ]),
                  ),
                ],
              ),
            ),

            //Apply Coupon and order details container
            Align(
              alignment: Alignment.bottomCenter,
              child:
                  widget.paymentFor == PaymentFor.walletRecharge ||
                      widget.paymentFor == PaymentFor.packagePay
                  ? SizedBox.shrink()
                  : Container(
                      decoration: BoxDecoration(color: Colors.white),
                      height:
                          (widget.paymentFor == PaymentFor.manualPayment) ||
                              (widget.paymentFor == PaymentFor.orderRePayment)
                          ? 80
                          : 140,
                      //color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            widget.paymentFor == PaymentFor.order
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 16.0,
                                    ),
                                    child: buildApplyCouponRow(context),
                                  )
                                : SizedBox.shrink(),
                            grandTotalSection(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Row buildApplyCouponRow(BuildContext context) {
    return Row(
      children: [
        Form(
          key: _formKey,
          child: SizedBox(
            height: 42,
            width: (MediaQuery.of(context).size.width - 32) * (2 / 3),
            child: TextFormField(
              controller: _couponController,
              readOnly: _couponApplied!,
              autofocus: false,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enter_coupon_code,
                hintStyle: TextStyle(
                  fontSize: 14.0,
                  color: MyTheme.textfield_grey,
                ),
                enabledBorder: app_language_rtl.$!
                    ? OutlineInputBorder(
                        borderSide: BorderSide(
                          color: MyTheme.textfield_grey,
                          width: 0.5,
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8.0),
                          bottomRight: Radius.circular(8.0),
                        ),
                      )
                    : OutlineInputBorder(
                        borderSide: BorderSide(
                          color: MyTheme.textfield_grey,
                          width: 0.5,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8.0),
                          bottomLeft: Radius.circular(8.0),
                        ),
                      ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: MyTheme.medium_grey,
                    width: 0.5,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                  ),
                ),
                contentPadding: EdgeInsets.only(left: 16.0),
              ),
            ),
          ),
        ),
        !_couponApplied!
            ? SizedBox(
                width: (MediaQuery.of(context).size.width - 32) * (1 / 3),
                height: 42,
                child: Btn.basic(
                  minWidth: MediaQuery.of(context).size.width,
                  color: MyTheme.accent_color,
                  shape: app_language_rtl.$!
                      ? RoundedRectangleBorder(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8.0),
                            bottomLeft: Radius.circular(8.0),
                          ),
                        )
                      : RoundedRectangleBorder(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8.0),
                            bottomRight: Radius.circular(8.0),
                          ),
                        ),
                  child: Text(
                    AppLocalizations.of(context)!.apply_coupon_all_capital,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    onCouponApply();
                  },
                ),
              )
            : SizedBox(
                width: (MediaQuery.of(context).size.width - 32) * (1 / 3),
                height: 42,
                child: Btn.basic(
                  minWidth: MediaQuery.of(context).size.width,
                  color: MyTheme.accent_color,
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.remove_ucf,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    onCouponRemove();
                  },
                ),
              ),
      ],
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        widget.title!, // Use widget.title as it's passed in the constructor
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  buildPaymentMethodList() {
    if (_isInitial && _paymentTypeList.isEmpty) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildListShimmer(
          itemCount: 5,
          itemHeight: 100.0,
        ),
      );
    } else if (_paymentTypeList.isNotEmpty) {
      return SingleChildScrollView(
        child: ListView.separated(
          separatorBuilder: (context, index) {
            return SizedBox(height: 16);
          },
          itemCount: _paymentTypeList.length,
          scrollDirection: Axis.vertical,
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 0.0),
              child: buildPaymentMethodItemCard(index),
            );
          },
        ),
      );
    } else if (!_isInitial && _paymentTypeList.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_payment_method_is_added,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    }
  }

  GestureDetector buildPaymentMethodItemCard(index) {
    return GestureDetector(
      onTap: () {
        onPaymentMethodItemTap(index);
      },
      child: Stack(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 400),
            decoration:
                BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ).copyWith(
                  border: Border.all(
                    color:
                        _selectedPaymentMethodKey ==
                            _paymentTypeList[index].paymentTypeKey
                        ? MyTheme.accent_color
                        : MyTheme.light_grey,
                    width:
                        _selectedPaymentMethodKey ==
                            _paymentTypeList[index].paymentTypeKey
                        ? 2.0
                        : 0.0,
                  ),
                ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 100,
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/placeholder.png',
                      image:
                          _paymentTypeList[index].paymentType ==
                              "manual_payment"
                          ? _paymentTypeList[index].image
                          : _paymentTypeList[index].image,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text(
                          _paymentTypeList[index].title,
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 14,
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: buildPaymentMethodCheckContainer(
              _selectedPaymentMethodKey ==
                  _paymentTypeList[index].paymentTypeKey,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPaymentMethodCheckContainer(bool check) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 400),
      opacity: check ? 1 : 0,
      child: Container(
        height: 16,
        width: 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: Colors.green,
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(Icons.check, color: Colors.white, size: 10),
        ),
      ),
    );
  }

  BottomAppBar buildBottomAppBar(BuildContext context) {
    return BottomAppBar(
      child: Container(
        color: Colors.transparent,
        height: 50,
        child: Btn.minWidthFixHeight(
          minWidth: MediaQuery.of(context).size.width,
          height: 50,
          color: MyTheme.accent_color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            widget.paymentFor == PaymentFor.walletRecharge
                ? AppLocalizations.of(context)!.recharge_wallet_ucf
                : widget.paymentFor == PaymentFor.manualPayment
                ? AppLocalizations.of(context)!.proceed_all_caps
                : widget.paymentFor == PaymentFor.packagePay
                ? AppLocalizations.of(context)!.buy_package_ucf
                : AppLocalizations.of(context)!.place_my_order_all_capital,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () {
            onPressPlaceOrderOrProceed();
          },
        ),
      ),
    );
  }

  Widget grandTotalSection() {
    return Container(
      height: 40,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: MyTheme.soft_accent_color,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                AppLocalizations.of(context)!.total_amount_ucf,
                style: TextStyle(color: MyTheme.font_grey, fontSize: 14),
              ),
            ),
            Visibility(
              visible: widget.paymentFor != PaymentFor.manualPayment,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: InkWell(
                  onTap: () {
                    onPressDetails();
                  },
                  child: Text(
                    AppLocalizations.of(context)!.see_details_all_lower,
                    style: TextStyle(
                      color: MyTheme.font_grey,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                balance(),
                style: TextStyle(
                  color: MyTheme.accent_color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  loading() {
    showDialog(
      context: context,
      builder: (context) {
        loadingcontext = context;
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text(AppLocalizations.of(context)!.please_wait_ucf),
            ],
          ),
        );
      },
    );
  }

  Widget taxOrGstRow({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: MyTheme.font_grey,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Spacer(),
          Text(
            SystemConfig.systemCurrency != null
                ? value.replaceAll(
                    SystemConfig.systemCurrency!.code!,
                    SystemConfig.systemCurrency!.symbol!,
                  )
                : value,
            style: TextStyle(
              color: MyTheme.font_grey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
