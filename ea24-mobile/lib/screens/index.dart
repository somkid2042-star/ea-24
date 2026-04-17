import 'package:ea24_mobile/helpers/addons_helper.dart';
import 'package:ea24_mobile/helpers/auth_helper.dart';
import 'package:ea24_mobile/helpers/business_setting_helper.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/helpers/system_config.dart';
import 'package:ea24_mobile/presenter/currency_presenter.dart';
import 'package:ea24_mobile/providers/locale_provider.dart';
import 'package:ea24_mobile/screens/main.dart';
import 'package:ea24_mobile/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Index extends StatefulWidget {
  final bool? goBack;
  const Index({super.key, this.goBack = true});
  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  Future<String?> getSharedValueHelperData(BuildContext context) async {
    access_token.load().whenComplete(() {
      AuthHelper().fetchAndSet();
    });
    AddonsHelper().setAddonsData();
    BusinessSettingHelper().setBusinessSettingData();
    await app_language.load();
    await app_mobile_language.load();
    await app_language_rtl.load();
    await system_currency.load();
    if (!context.mounted) return app_mobile_language.$;
    Provider.of<CurrencyPresenter>(context, listen: false).fetchListData();

    return app_mobile_language.$;
  }

  @override
  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await getSharedValueHelperData(context);
    if (!mounted) return;
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    SystemConfig.isShownSplashScreed = true;

    Provider.of<LocaleProvider>(
      context,
      listen: false,
    ).setLocale(app_mobile_language.$!);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    SystemConfig.context ??= context;
    return Scaffold(
      body: SystemConfig.isShownSplashScreed
          ? Main(goBack: widget.goBack ?? true)
          : SplashScreen(),
    );
  }
}
