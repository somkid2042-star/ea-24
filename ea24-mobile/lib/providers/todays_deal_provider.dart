import 'package:flutter/material.dart';
import '../data_model/product_mini_response.dart';
import '../repositories/product_repository.dart';

class TodaysDealProvider extends ChangeNotifier {
  ProductMiniResponse? _productMiniResponse;
  bool _isLoading = false;
  bool _hasError = false;

  ProductMiniResponse? get productMiniResponse => _productMiniResponse;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  Future<void> fetchTodaysDealProducts() async {
    if (_isLoading) return;

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _productMiniResponse =
      await ProductRepository().getTodaysDealProducts();
    } catch (e) {
      _hasError = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  bool get hasData =>
      _productMiniResponse != null &&
          _productMiniResponse!.products!.isNotEmpty;
}
