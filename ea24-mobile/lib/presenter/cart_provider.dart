import 'package:ea24_mobile/custom/toast_component.dart';
import 'package:ea24_mobile/data_model/cart_response.dart';
import 'package:ea24_mobile/helpers/system_config.dart';
import 'package:ea24_mobile/presenter/cart_counter.dart';
import 'package:ea24_mobile/repositories/cart_repository.dart';
import 'package:flutter/material.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../custom/aiz_route.dart';
import '../custom/btn.dart';
import '../helpers/shared_value_helper.dart';
import '../my_theme.dart';
import '../screens/checkout/single_page_checkout.dart';

class CartProvider extends ChangeNotifier {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _mainScrollController = ScrollController();
  List _shopList = [];
  CartResponse? _shopResponse;
  bool _isInitial = true;
  double _cartTotal = 0.00;
  String _cartTotalString = ". . .";

  GlobalKey<ScaffoldState> get scaffoldKey => _scaffoldKey;
  ScrollController get mainScrollController => _mainScrollController;
  List get shopList => _shopList;
  CartResponse? get shopResponse => _shopResponse;
  bool get isInitial => _isInitial;
  double get cartTotal => _cartTotal;
  String get cartTotalString => _cartTotalString;

  void initState(BuildContext context) {
    fetchData(context);
  }

  @override
  void dispose() {
    super.dispose();
    _mainScrollController.dispose();
  }

  bool get isAnyItemOutOfStock {
    if (shopList.isEmpty) {
      return false;
    }
    return shopList.any(
      (seller) => seller.cartItems.any(
        (item) => (item.digital ?? 0) == 0 && item.stock == 0,
      ),
    );
  }

  void fetchData(BuildContext context) async {
    getCartCount(context);
    CartResponse cartResponseList = await CartRepository().getCartResponseList(
      user_id.$,
    );

    if (cartResponseList.data != null && cartResponseList.data!.isNotEmpty) {
      _shopList = cartResponseList.data!;
      _shopResponse = cartResponseList;
      getSetCartTotal();
    }
    _isInitial = false;

    notifyListeners();
  }

  void getCartCount(BuildContext context) {
    Provider.of<CartCounter>(context, listen: false).getCount();
  }

  void getSetCartTotal() {
    _cartTotalString = _shopResponse!.grandTotal!.replaceAll(
      SystemConfig.systemCurrency!.code!,
      SystemConfig.systemCurrency!.symbol!,
    );

    notifyListeners();
  }

  void onQuantityIncrease(
    BuildContext context,
    int sellerIndex,
    int itemIndex,
  ) {
    if (_shopList[sellerIndex].cartItems[itemIndex].quantity <
        _shopList[sellerIndex].cartItems[itemIndex].upperLimit) {
      _shopList[sellerIndex].cartItems[itemIndex].quantity++;
      notifyListeners();
      process(context, mode: "update");
    } else {
      ToastComponent.showDialog(
        "${AppLocalizations.of(context)!.cannot_order_more_than} ${_shopList[sellerIndex].cartItems[itemIndex].upperLimit} ${AppLocalizations.of(context)!.items_of_this_all_lower}",
        gravity: ToastGravity.CENTER,
        duration: Toast.LENGTH_LONG,
      );
    }
  }

  void onQuantityDecrease(
    BuildContext context,
    int sellerIndex,
    int itemIndex,
  ) {
    if (_shopList[sellerIndex].cartItems[itemIndex].quantity >
        _shopList[sellerIndex].cartItems[itemIndex].lowerLimit) {
      _shopList[sellerIndex].cartItems[itemIndex].quantity--;
      notifyListeners();
      process(context, mode: "update");
    } else {
      ToastComponent.showDialog(
        "${AppLocalizations.of(context)!.cannot_order_more_than} ${_shopList[sellerIndex].cartItems[itemIndex].lowerLimit} ${AppLocalizations.of(context)!.items_of_this_all_lower}",
      );
    }
  }

  void onPressDelete(BuildContext context, String cartId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.only(
          top: 30.0,
          left: 2.0,
          right: 2.0,
          bottom: 20.0,
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            AppLocalizations.of(context)!.are_you_sure_to_remove_this_item,
            maxLines: 3,
            style: TextStyle(color: MyTheme.font_grey, fontSize: 14),
          ),
        ),
        actions: [
          Btn.basic(
            child: Text(
              AppLocalizations.of(context)!.cancel_ucf,
              style: TextStyle(color: MyTheme.medium_grey),
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
          ),
          Btn.basic(
            color: MyTheme.soft_accent_color,
            child: Text(
              AppLocalizations.of(context)!.confirm_ucf,
              style: TextStyle(color: MyTheme.dark_grey),
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              confirmDelete(context, cartId);
            },
          ),
        ],
      ),
    );
  }

  void confirmDelete(BuildContext context, String cartId) async {
    var cartDeleteResponse = await CartRepository().getCartDeleteResponse(
      int.parse(cartId),
    );
    if (!context.mounted) return;

    if (cartDeleteResponse.result == true) {
      ToastComponent.showDialog(cartDeleteResponse.message);

      reset();
      fetchData(context);
    } else {
      ToastComponent.showDialog(cartDeleteResponse.message);
    }
  }

  void onPressUpdate(BuildContext context) {
    process(context, mode: "update");
  }

  void onPressProceedToShipping(BuildContext context) {
    process(context, mode: "proceed_to_shipping");
  }

  void process(BuildContext context, {required String mode}) async {
    var cartIds = [];
    var cartQuantities = [];
    if (_shopList.isNotEmpty) {
      for (var shop in _shopList) {
        if (shop.cartItems.length > 0) {
          shop.cartItems.forEach((cartItem) {
            cartIds.add(cartItem.id);
            cartQuantities.add(cartItem.quantity);
          });
        }
      }
    }

    if (cartIds.isEmpty) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.cart_is_empty);
      return;
    }

    var cartIdsString = cartIds.join(',').toString();
    var cartQuantitiesString = cartQuantities.join(',').toString();

    var cartProcessResponse = await CartRepository().getCartProcessResponse(
      cartIdsString,
      cartQuantitiesString,
    );
    if (!context.mounted) return;

    if (cartProcessResponse.result == false) {
      ToastComponent.showDialog(cartProcessResponse.message);
    } else {
      if (mode == "update") {
        fetchData(context);
      } else if (mode == "proceed_to_shipping") {
        // এখন লগ-ইন করা ইউজার বা গেস্ট—সবাই সরাসরি সিঙ্গেল পেজ চেকআউটে যাবে
        AIZRoute.push(context, const CheckoutPage()).then((value) {
          if (!context.mounted) return;
          onPopped(context, value);
        });
      }
    }
  }

  void reset() {
    _shopList.clear();
    _isInitial = true;
    _cartTotal = 0.00;
    _cartTotalString = ". . .";
    notifyListeners();
  }

  Future<void> onRefresh(BuildContext context) async {
    reset();
    fetchData(context);
  }

  void onPopped(BuildContext context, dynamic value) {
    reset();
    fetchData(context);
  }
}
