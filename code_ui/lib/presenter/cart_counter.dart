
import 'dart:async';

import 'package:active_ecommerce_cms_demo_app/repositories/cart_repository.dart';
import 'package:flutter/material.dart';

class CartCounter extends ChangeNotifier {
  int cartCounter = 0;

  Future<void> getCount() async {
    var res = await CartRepository().getCartCount();
    cartCounter = res.count ?? 0;
    notifyListeners();
  }
}
