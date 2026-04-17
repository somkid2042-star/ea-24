import 'package:active_ecommerce_cms_demo_app/data_model/currency_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/currency_repository.dart';
import 'package:flutter/material.dart';

class CurrencyPresenter extends ChangeNotifier {
  List<CurrencyInfo> currencyList = [];

  fetchListData() async {
    currencyList.clear();
    var res = await CurrencyRepository().getListResponse();

    currencyList.addAll(res.data!);

    for (var element in currencyList) {
      if (element.isDefault!) {
        SystemConfig.defaultCurrency = element;
        SystemConfig.systemCurrency = element;
        system_currency.$ = element.id;
        system_currency.save();
      }
      if (system_currency.$ == 0 && element.isDefault!) {
        SystemConfig.systemCurrency = element;
        system_currency.$ = element.id;
        system_currency.save();
      }
      if (system_currency.$ != null && element.id == system_currency.$) {
        SystemConfig.systemCurrency = element;
        system_currency.$ = element.id;
        system_currency.save();
      }
    }
    notifyListeners();
  }
}
