import 'package:active_ecommerce_cms_demo_app/custom/lang_text.dart';
import 'package:active_ecommerce_cms_demo_app/custom/useful_elements.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../product/widgets/digital_porduct_card.dart';

class DigitalProducts extends StatefulWidget {
  const DigitalProducts({super.key});

  @override
  State<DigitalProducts> createState() => _DigitalProductsState();
}

class _DigitalProductsState extends State<DigitalProducts> {
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _xcrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _dataFetch = false;
  final List<dynamic> _digitalProducts = [];
  int _page = 1;
  int? _totalData = 0;
  bool _showLoadingContainer = false;
  String _searchKey = "";
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    fetchData();

    _xcrollController.addListener(() {
      if (_xcrollController.position.pixels ==
          _xcrollController.position.maxScrollExtent) {
        if (_totalData! > _digitalProducts.length) {
          setState(() {
            _page++;
            _showLoadingContainer = true;
          });
          fetchData();
        }
      }
    });
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _xcrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void reset() {
    _dataFetch = false;
    _digitalProducts.clear();
    _totalData = 0;
    _page = 1;
    _showLoadingContainer = false;
    setState(() {});
  }

  fetchData() async {
    var digitalProductRes = await ProductRepository().getDigitalProducts(
      page: _page,
      name: _searchKey,
    );

    _digitalProducts.addAll(digitalProductRes.products!);
    _totalData = digitalProductRes.meta!.total;
    _dataFetch = true;
    _showLoadingContainer = false;
    setState(() {});
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchData();
  }

  void onSearchClear() {
    setState(() {
      _showSearchBar = false;
      _searchKey = "";
      _searchController.clear();
    });
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
        body: Stack(
          children: [
            body(),
            Align(
              alignment: Alignment.bottomCenter,
              child: buildLoadingContainer(),
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      toolbarHeight: 60,
      automaticallyImplyLeading: false,
      title: buildAppBarTitle(context),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  Widget buildAppBarTitle(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: buildAppBarTitleOption(),
      secondChild: buildAppBarSearchOption(),
      firstCurve: Curves.easeIn,
      secondCurve: Curves.easeIn,
      crossFadeState: _showSearchBar
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget buildAppBarTitleOption() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          UsefulElements.backButton(context, color: MyTheme.dark_font_grey),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: Text(
              AppLocalizations.of(context)!.digital_product_ucf,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: MyTheme.dark_font_grey,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Image.asset('assets/search.png', height: 20),
            onPressed: () {
              setState(() {
                _showSearchBar = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget buildAppBarSearchOption() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      width: MediaQuery.of(context).size.width,
      height: 40,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (txt) {
          _searchKey = txt;
          reset();
          fetchData();
        },
        onSubmitted: (txt) {
          _searchKey = txt;
          reset();
          fetchData();
        },
        decoration: InputDecoration(
          hintText: "Search Digital Products...",
          hintStyle: const TextStyle(
            fontSize: 14.0,
            color: MyTheme.textfield_grey,
          ),
          suffixIcon: IconButton(
            onPressed: onSearchClear,
            icon: Icon(Icons.clear, color: MyTheme.grey_153),
          ),
          filled: true,
          fillColor: MyTheme.white,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MyTheme.noColor, width: 0.0),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MyTheme.noColor, width: 0.0),
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.all(8.0),
        ),
      ),
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
        controller: _xcrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 14,
          itemCount: _digitalProducts.length,
          shrinkWrap: true,
          padding: const EdgeInsets.only(
            top: 10.0,
            bottom: 10,
            left: 18,
            right: 18,
          ),
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return DigitalProductCard(
              id: _digitalProducts[index].id,
              slug: _digitalProducts[index].slug,
              image: _digitalProducts[index].thumbnailImage,
              name: _digitalProducts[index].name,
              mainPrice: _digitalProducts[index].mainPrice,
              strokedPrice: _digitalProducts[index].strokedPrice,
              hasDiscount: _digitalProducts[index].hasDiscount ?? false,
              discount: _digitalProducts[index].discount,
              isWholesale: _digitalProducts[index].isWholesale,
            );
          },
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
          _totalData == _digitalProducts.length
              ? AppLocalizations.of(context)!.no_more_products_ucf
              : AppLocalizations.of(context)!.loading_more_products_ucf,
        ),
      ),
    );
  }
}
