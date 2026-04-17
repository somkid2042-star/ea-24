import 'package:ea24_mobile/custom/box_decorations.dart';
import 'package:ea24_mobile/custom/useful_elements.dart';
import 'package:ea24_mobile/helpers/main_helpers.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/repositories/order_repository.dart';
import 'package:ea24_mobile/screens/main.dart';
import 'package:ea24_mobile/screens/orders/order_details.dart';
import 'package:flutter/material.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:shimmer/shimmer.dart';

class PaymentStatus {
  final String optionKey;
  final String name;

  PaymentStatus(this.optionKey, this.name);

  static List<PaymentStatus> getPaymentStatusList() {
    return <PaymentStatus>[
      PaymentStatus('', AppLocalizations.of(OneContext().context!)!.all_ucf),
      PaymentStatus(
        'paid',
        AppLocalizations.of(OneContext().context!)!.paid_ucf,
      ),
      PaymentStatus(
        'unpaid',
        AppLocalizations.of(OneContext().context!)!.unpaid_ucf,
      ),
    ];
  }
}

class DeliveryStatus {
  String optionKey;
  String name;

  DeliveryStatus(this.optionKey, this.name);

  static List<DeliveryStatus> getDeliveryStatusList() {
    return <DeliveryStatus>[
      DeliveryStatus('', AppLocalizations.of(OneContext().context!)!.all_ucf),
      DeliveryStatus(
        'confirmed',
        AppLocalizations.of(OneContext().context!)!.confirmed_ucf,
      ),
      DeliveryStatus(
        'on_the_way',
        AppLocalizations.of(OneContext().context!)!.on_the_way_ucf,
      ),
      DeliveryStatus(
        'delivered',
        AppLocalizations.of(OneContext().context!)!.delivered_ucf,
      ),
    ];
  }
}

class OrderList extends StatefulWidget {
  const OrderList({super.key, this.fromCheckout = false});
  final bool fromCheckout;

  @override
  State<OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _xcrollController = ScrollController();

  final List<PaymentStatus> _paymentStatusList =
      PaymentStatus.getPaymentStatusList();
  final List<DeliveryStatus> _deliveryStatusList =
      DeliveryStatus.getDeliveryStatusList();

  PaymentStatus? _selectedPaymentStatus;
  DeliveryStatus? _selectedDeliveryStatus;

  List<DropdownMenuItem<PaymentStatus>>? _dropdownPaymentStatusItems;
  List<DropdownMenuItem<DeliveryStatus>>? _dropdownDeliveryStatusItems;

  //------------------------------------
  final List<dynamic> _orderList = [];
  bool _isInitial = true;
  int _page = 1;
  int? _totalData = 0;
  bool _showLoadingContainer = false;
  String _defaultPaymentStatusKey = '';
  String _defaultDeliveryStatusKey = '';

  @override
  void initState() {
    init();
    super.initState();

    fetchData();

    _xcrollController.addListener(() {
      if (_xcrollController.position.pixels ==
          _xcrollController.position.maxScrollExtent) {
        setState(() {
          _page++;
        });
        _showLoadingContainer = true;
        fetchData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _xcrollController.dispose();
    super.dispose();
  }

  init() {
    _dropdownPaymentStatusItems = buildDropdownPaymentStatusItems(
      _paymentStatusList,
    );

    _dropdownDeliveryStatusItems = buildDropdownDeliveryStatusItems(
      _deliveryStatusList,
    );

    for (int x = 0; x < _dropdownPaymentStatusItems!.length; x++) {
      if (_dropdownPaymentStatusItems![x].value!.optionKey ==
          _defaultPaymentStatusKey) {
        _selectedPaymentStatus = _dropdownPaymentStatusItems![x].value;
      }
    }

    for (int x = 0; x < _dropdownDeliveryStatusItems!.length; x++) {
      if (_dropdownDeliveryStatusItems![x].value!.optionKey ==
          _defaultDeliveryStatusKey) {
        _selectedDeliveryStatus = _dropdownDeliveryStatusItems![x].value;
      }
    }
  }

  reset() {
    _orderList.clear();
    _isInitial = true;
    _page = 1;
    _totalData = 0;
    _showLoadingContainer = false;
  }

  resetFilterKeys() {
    _defaultPaymentStatusKey = '';
    _defaultDeliveryStatusKey = '';

    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    resetFilterKeys();
    for (int x = 0; x < _dropdownPaymentStatusItems!.length; x++) {
      if (_dropdownPaymentStatusItems![x].value!.optionKey ==
          _defaultPaymentStatusKey) {
        _selectedPaymentStatus = _dropdownPaymentStatusItems![x].value;
      }
    }

    for (int x = 0; x < _dropdownDeliveryStatusItems!.length; x++) {
      if (_dropdownDeliveryStatusItems![x].value!.optionKey ==
          _defaultDeliveryStatusKey) {
        _selectedDeliveryStatus = _dropdownDeliveryStatusItems![x].value;
      }
    }
    setState(() {});
    fetchData();
  }

  fetchData() async {
    var orderResponse = await OrderRepository().getOrderList(
      page: _page,
      paymentStatus: _selectedPaymentStatus!.optionKey,
      deliveryStatus: _selectedDeliveryStatus!.optionKey,
    );
    _orderList.addAll(orderResponse.orders);
    _isInitial = false;
    _totalData = orderResponse.meta.total;
    _showLoadingContainer = false;
    setState(() {});
  }

  List<DropdownMenuItem<PaymentStatus>> buildDropdownPaymentStatusItems(
    List paymentStatusList,
  ) {
    List<DropdownMenuItem<PaymentStatus>> items = [];
    for (PaymentStatus item in paymentStatusList as Iterable<PaymentStatus>) {
      items.add(DropdownMenuItem(value: item, child: Text(item.name)));
    }
    return items;
  }

  List<DropdownMenuItem<DeliveryStatus>> buildDropdownDeliveryStatusItems(
    List deliveryStatusList,
  ) {
    List<DropdownMenuItem<DeliveryStatus>> items = [];
    for (DeliveryStatus item
        in deliveryStatusList as Iterable<DeliveryStatus>) {
      items.add(DropdownMenuItem(value: item, child: Text(item.name)));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.fromCheckout,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.fromCheckout) {
          context.go("/");
        }
      },
      child: Directionality(
        textDirection: app_language_rtl.$!
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: MyTheme.mainColor,
          appBar: buildAppBar(context),
          body: Stack(
            children: [
              buildOrderListList(),
              Align(
                alignment: Alignment.bottomCenter,
                child: buildLoadingContainer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container buildLoadingContainer() {
    return Container(
      height: _showLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(
          _totalData == _orderList.length
              ? AppLocalizations.of(context)!.no_more_orders_ucf
              : AppLocalizations.of(context)!.loading_more_orders_ucf,
        ),
      ),
    );
  }

  buildBottomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecorations.buildBoxDecoration_1(),
            padding: EdgeInsets.symmetric(horizontal: 14),
            height: 36,
            width: MediaQuery.of(context).size.width * .4,
            child: DropdownButton<PaymentStatus>(
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(6),
              icon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.expand_more, color: Colors.black54),
              ),
              hint: Text(
                AppLocalizations.of(context)!.all_payments_ucf,
                style: TextStyle(color: MyTheme.font_grey, fontSize: 12),
              ),
              iconSize: 14,
              underline: SizedBox(),
              value: _selectedPaymentStatus,
              items: _dropdownPaymentStatusItems,
              onChanged: (PaymentStatus? selectedFilter) {
                setState(() {
                  _selectedPaymentStatus = selectedFilter;
                });
                reset();
                fetchData();
              },
            ),
          ),
          Container(
            decoration: BoxDecorations.buildBoxDecoration_1(),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            height: 36,
            width: MediaQuery.of(context).size.width * .4,
            child: DropdownButton<DeliveryStatus>(
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(6),
              icon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.expand_more, color: Colors.black54),
              ),
              hint: Text(
                AppLocalizations.of(context)!.all_deliveries_ucf,
                style: TextStyle(color: MyTheme.font_grey, fontSize: 12),
              ),
              iconSize: 14,
              underline: SizedBox(),
              value: _selectedDeliveryStatus,
              items: _dropdownDeliveryStatusItems,
              onChanged: (DeliveryStatus? selectedFilter) {
                setState(() {
                  _selectedDeliveryStatus = selectedFilter;
                });
                reset();
                fetchData();
              },
            ),
          ),
        ],
      ),
    );
  }

  buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(104.0),
      child: AppBar(
        centerTitle: false,
        backgroundColor: MyTheme.mainColor,
        scrolledUnderElevation: 0.0,
        automaticallyImplyLeading: false,
        actions: [Container()],
        elevation: 0.0,
        titleSpacing: 0,
        flexibleSpace: Padding(
          padding: const EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 0.0),
          child: Column(
            children: [
              Padding(
                padding: MediaQuery.of(context).viewPadding.top > 30
                    ? const EdgeInsets.only(top: 36.0)
                    : const EdgeInsets.only(top: 14.0),
                child: buildTopAppBarContainer(),
              ),
              buildBottomAppBar(context),
            ],
          ),
        ),
      ),
    );
  }

  SizedBox buildTopAppBarContainer() {
    return SizedBox(
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              padding: EdgeInsets.zero,
              icon: UsefulElements.backIcon(context),
              onPressed: () {
                if (widget.fromCheckout) {
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
          Text(
            AppLocalizations.of(context)!.purchase_history_ucf,
            style: TextStyle(
              fontSize: 16,
              color: MyTheme.dark_font_grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  buildOrderListList() {
    if (_isInitial && _orderList.isEmpty) {
      return SingleChildScrollView(
        child: ListView.builder(
          controller: _scrollController,
          itemCount: 10,
          scrollDirection: Axis.vertical,
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 14.0,
              ),
              child: Shimmer.fromColors(
                baseColor: MyTheme.shimmer_base,
                highlightColor: MyTheme.shimmer_highlighted,
                child: Container(
                  height: 75,
                  width: double.infinity,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      );
    } else if (_orderList.isNotEmpty) {
      return RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        displacement: 0,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          controller: _xcrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: ListView.separated(
            separatorBuilder: (context, index) => SizedBox(height: 14),
            padding: const EdgeInsets.only(
              left: 18,
              right: 18,
              top: 10,
              bottom: 0,
            ),
            itemCount: _orderList.length,
            scrollDirection: Axis.vertical,
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return OrderDetails(id: _orderList[index].id);
                      },
                    ),
                  );
                },
                child: buildOrderListItemCard(index),
              );
            },
          ),
        ),
      );
    } else if (_totalData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_data_is_available),
      );
    } else {
      return Container();
    }
  }

  buildOrderListItemCard(int index) {
    return Container(
      decoration: BoxDecorations.buildBoxDecoration_1(),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                _orderList[index].code,
                style: TextStyle(
                  color: MyTheme.accent_color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                children: [
                  Text(
                    _orderList[index].date,
                    style: TextStyle(
                      color: MyTheme.dark_font_grey,
                      fontSize: 12,
                    ),
                  ),
                  Spacer(),
                  Text(
                    convertPrice(_orderList[index].grandTotal),
                    style: TextStyle(
                      color: MyTheme.accent_color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                children: [
                  Text(
                    "${AppLocalizations.of(context)!.payment_status_ucf} - ",
                    style: TextStyle(
                      color: MyTheme.dark_font_grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _orderList[index].paymentStatusString,
                    style: TextStyle(
                      color: _orderList[index].paymentStatus == "paid"
                          ? Colors.green
                          : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  "${AppLocalizations.of(context)!.delivery_status_ucf} -",
                  style: TextStyle(color: MyTheme.dark_font_grey, fontSize: 12),
                ),
                Text(
                  _orderList[index].deliveryStatusString,
                  style: TextStyle(
                    color: MyTheme.dark_font_grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Container buildPaymentStatusCheckContainer(String paymentStatus) {
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
}
