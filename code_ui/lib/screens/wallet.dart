import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/device_info.dart';
import 'package:active_ecommerce_cms_demo_app/custom/enum_classes.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/custom/useful_elements.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/reg_ex_inpur_formatter.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/wallet_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/checkout/checkout.dart';
import 'package:active_ecommerce_cms_demo_app/screens/main.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';

import '../helpers/main_helpers.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key, this.fromRecharge = false});
  final bool fromRecharge;

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  final _amountValidator = RegExInputFormatter.withRegex(
    '^\$|^(0|([1-9][0-9]{0,}))(\\.[0-9]{0,})?\$',
  );
  final ScrollController _mainScrollController = ScrollController();
  final TextEditingController _amountController = TextEditingController();

  GlobalKey appBarKey = GlobalKey();

  dynamic _balanceDetails;

  final List<dynamic> _rechargeList = [];
  bool _rechargeListInit = true;
  int _rechargePage = 1;
  int? _totalRechargeData = 0;
  bool _showRechageLoadingContainer = false;

  @override
  void initState() {
    super.initState();
    fetchAll();
    _mainScrollController.addListener(() {
      if (_mainScrollController.position.pixels ==
          _mainScrollController.position.maxScrollExtent) {
        setState(() {
          _rechargePage++;
        });
        _showRechageLoadingContainer = true;
        fetchRechargeList();
      }
    });
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  fetchAll() {
    fetchBalanceDetails();
    fetchRechargeList();
  }

  fetchBalanceDetails() async {
    var balanceDetailsResponse = await WalletRepository().getBalance();

    _balanceDetails = balanceDetailsResponse;

    setState(() {});
  }

  fetchRechargeList() async {
    var rechageListResponse = await WalletRepository().getRechargeList(
      page: _rechargePage,
    );

    if (rechageListResponse.result) {
      _rechargeList.addAll(rechageListResponse.recharges);
      _totalRechargeData = rechageListResponse.meta.total;
    } else {}
    _rechargeListInit = false;
    _showRechageLoadingContainer = false;

    setState(() {});
  }

  reset() {
    _balanceDetails = null;
    _rechargeList.clear();
    _rechargeListInit = true;
    _rechargePage = 1;
    _totalRechargeData = 0;
    _showRechageLoadingContainer = false;
    setState(() {});
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchAll();
  }

  onPressProceed() {
    var amountString = _amountController.text.toString();

    if (amountString == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.amount_cannot_be_empty,
      );
      return;
    }

    var amount = double.parse(amountString);

    Navigator.of(context, rootNavigator: true).pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Checkout(
            paymentFor: PaymentFor.walletRecharge,
            rechargeAmount: amount,
            title: AppLocalizations.of(context)!.recharge_wallet_ucf,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (widget.fromRecharge) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => Main()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Directionality(
        textDirection: app_language_rtl.$!
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Color(0xffF2F1F6),
          appBar: buildAppBar(context),
          body: RefreshIndicator(
            color: MyTheme.accent_color,
            backgroundColor: Color(0xffF2F1F6),
            onRefresh: _onPageRefresh,
            displacement: 10,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: Color(0xffF2F1F6),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      bottom: 0.0,
                      left: 16.0,
                      right: 16.0,
                    ),
                    child: _balanceDetails != null
                        ? buildTopSection(context)
                        : ShimmerHelper().buildBasicShimmer(height: 150),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 100.0, bottom: 0.0),
                  child: buildRechargeList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Container buildLoadingContainer() {
    return Container(
      height: _showRechageLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(
          _totalRechargeData == _rechargeList.length
              ? AppLocalizations.of(context)!.no_more_histories_ucf
              : AppLocalizations.of(context)!.loading_more_histories_ucf,
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      scrolledUnderElevation: 0.0,
      key: appBarKey,
      backgroundColor: Color(0xffF2F1F6),
      centerTitle: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: UsefulElements.backButton(context),
          onPressed: () {
            if (widget.fromRecharge) {
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
        AppLocalizations.of(context)!.my_wallet_ucf,
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

  buildRechargeList() {
    if (_rechargeListInit && _rechargeList.isEmpty) {
      return SingleChildScrollView(child: buildRechargeListShimmer());
    } else if (_rechargeList.isNotEmpty) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 16.0,
                bottom: 16.0,
                left: 16.0,
              ),
              child: Text(
                AppLocalizations.of(context)!.wallet_recharge_history_ucf,
                style: TextStyle(
                  color: MyTheme.dark_font_grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _rechargeList.length,
              scrollDirection: Axis.vertical,
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: buildRechargeListItemCard(index),
                );
              },
            ),
          ],
        ),
      );
    } else if (_totalRechargeData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_recharges_yet),
      );
    } else {
      return Container();
    }
  }

  buildRechargeListShimmer() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ShimmerHelper().buildBasicShimmer(height: 75.0),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ShimmerHelper().buildBasicShimmer(height: 75.0),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ShimmerHelper().buildBasicShimmer(height: 75.0),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ShimmerHelper().buildBasicShimmer(height: 75.0),
        ),
      ],
    );
  }

  //main Container
  Widget buildRechargeListItemCard(int index) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Text(
                getFormattedRechargeListIndex(index),
                style: TextStyle(
                  color: MyTheme.dark_font_grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _rechargeList[index].date,
                    style: TextStyle(
                      color: MyTheme.dark_font_grey,
                      fontSize: 12,
                    ),
                  ),

                  Text(
                    AppLocalizations.of(context)!.payment_method_ucf,
                    style: TextStyle(
                      color: MyTheme.dark_font_grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _rechargeList[index].paymentMethod,
                    style: TextStyle(
                      color: MyTheme.dark_font_grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    convertPrice(_rechargeList[index].amount),
                    style: TextStyle(
                      color: MyTheme.accent_color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _rechargeList[index].approvalString,
                    style: TextStyle(color: MyTheme.dark_grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  getFormattedRechargeListIndex(int index) {
    int num = index + 1;
    var txt = num.toString().length == 1 ? "# 0$num" : "#$num";
    return txt;
  }

  // Top Part Container
  Widget buildTopSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: DeviceInfo(context).width! / 2.3,
          height: 90,
          decoration: BoxDecoration(
            color: MyTheme.accent_color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  AppLocalizations.of(context)!.wallet_balance_ucf,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  convertPrice(_balanceDetails.balance),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Spacer(),
              Text(
                "${AppLocalizations.of(context)!.last_recharged} : ${_balanceDetails.lastRecharged}",
                style: TextStyle(color: MyTheme.light_grey, fontSize: 10),
                textAlign: TextAlign.center,
              ),
              Spacer(),
            ],
          ),
        ),
        Container(
          width: DeviceInfo(context).width! / 2.3,
          height: 90,
          decoration: BoxDecoration(
            color: Color(0xffFEF0D7),
            border: Border.all(color: MyTheme.accent_color, width: 1),
            borderRadius: BorderRadius.circular(10), // Set border radius here
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Btn.basic(
              minWidth: MediaQuery.of(context).size.width,
              color: MyTheme.accent_color.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(5.0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.recharge_wallet_ucf,
                    style: TextStyle(
                      color: MyTheme.accent_color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 14),
                  Icon(Icons.add, size: 25, color: MyTheme.accent_color),
                ],
              ),
              onPressed: () {
                buildShowAddFormDialog(context);
              },
            ),
          ),
        ),
      ],
    );
  }

  //   AlartDialog
  Future buildShowAddFormDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: app_language_rtl.$!
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: 10),
          contentPadding: EdgeInsets.only(
            top: 36.0,
            left: 20.0,
            right: 22.0,
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
                    child: Text(
                      AppLocalizations.of(context)!.amount_ucf,
                      style: TextStyle(
                        color: MyTheme.dark_font_grey,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _amountController,
                        autofocus: false,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [_amountValidator],
                        decoration: InputDecoration(
                          fillColor: MyTheme.light_grey,
                          filled: true,
                          hintText: AppLocalizations.of(
                            context,
                          )!.enter_amount_ucf,
                          hintStyle: TextStyle(
                            fontSize: 12.0,
                            color: MyTheme.textfield_grey,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: MyTheme.noColor,
                              width: 0.0,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: MyTheme.noColor,
                              width: 0.0,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                //  Expanded(child: SizedBox()),
                Btn.minWidthFixHeight(
                  minWidth: 75,
                  height: 30,
                  color: Color.fromRGBO(253, 253, 253, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                    side: BorderSide(color: MyTheme.accent_color, width: 1.0),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.close_ucf,
                    style: TextStyle(fontSize: 10, color: MyTheme.accent_color),
                  ),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
                SizedBox(width: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.0),
                  child: Btn.minWidthFixHeight(
                    minWidth: 75,
                    height: 30,
                    color: MyTheme.accent_color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.proceed_ucf,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    onPressed: () {
                      onPressProceed();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
