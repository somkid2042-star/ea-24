import 'package:flutter/material.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';

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
