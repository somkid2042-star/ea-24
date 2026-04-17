import 'package:active_ecommerce_cms_demo_app/custom/lang_text.dart';
import 'package:active_ecommerce_cms_demo_app/custom/useful_elements.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/string_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/order_repository.dart';
import 'package:active_ecommerce_cms_demo_app/ui_elements/purchased_digital_product_card.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class PurchasedDigitalProducts extends StatefulWidget {
  const PurchasedDigitalProducts({super.key});

  @override
  State<PurchasedDigitalProducts> createState() =>
      _PurchasedDigitalProductsState();
}

class _PurchasedDigitalProductsState extends State<PurchasedDigitalProducts> {
  final ScrollController _mainScrollController = ScrollController();

  //init
  bool _dataFetch = false;
  final List<dynamic> _digitalProducts = [];
  int page = 1;

  @override
  void initState() {
    fetchData();
    super.initState();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  reset() {
    _dataFetch = false;
    _digitalProducts.clear();
    setState(() {});
  }

  fetchData() async {
    var digitalProductRes = await OrderRepository().getPurchasedDigitalProducts(
      page: page,
    );

    _digitalProducts.addAll(digitalProductRes.data);
    _dataFetch = true;
    setState(() {});
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.mainColor,
        appBar: buildAppBar(context),
        body: body(),
      ),
    );
  }

  bool? shouldProductBoxBeVisible(productName, searchKey) {
    if (searchKey == "") {
      return true;
    }
    return StringHelper().stringContains(productName, searchKey);
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      leading: UsefulElements.backButton(context),
      actions: [
        GestureDetector(
          onTap: () {},
          child: Image.asset(
            'assets/search.png',
            height: 16,
            color: Color(0xff121423),
          ),
        ),
        SizedBox(width: 37),
      ],
      title: Text(
        AppLocalizations.of(context)!.digital_product_ucf,
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Public Sans',
          color: MyTheme.dark_font_grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  Widget body() {
    if (!_dataFetch) {
      return ShimmerHelper().buildProductGridShimmer(
        scontroller: _mainScrollController,
      );
    }

    if (_digitalProducts.isEmpty) {
      return Center(child: Text(LangText(context).local.no_data_is_available));
    }
    return RefreshIndicator(
      onRefresh: _onPageRefresh,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          itemCount: _digitalProducts.length,
          shrinkWrap: true,
          padding: EdgeInsets.only(top: 0.0, bottom: 10, left: 20, right: 20),
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return PurchasedDigitalProductCard(
              id: _digitalProducts[index].id,
              image: _digitalProducts[index].thumbnailImage,
              name: _digitalProducts[index].name,
            );
          },
        ),
      ),
    );
  }
}
