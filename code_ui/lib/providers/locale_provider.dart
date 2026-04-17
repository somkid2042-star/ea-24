import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';

class LocaleProvider with ChangeNotifier {
  Locale? _locale;
  Locale get locale {
    if (_locale != null) {
      return _locale!;
    }
    return Locale(
      app_mobile_language.$ == '' ? "en" : app_mobile_language.$!,
      '',
    );
  }

  void setLocale(String code) {
    _locale = Locale(code, '');
    notifyListeners();
  }
}
