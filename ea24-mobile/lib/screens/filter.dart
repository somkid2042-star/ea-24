import 'package:ea24_mobile/custom/btn.dart';
import 'package:ea24_mobile/custom/toast_component.dart';
import 'package:ea24_mobile/custom/useful_elements.dart';
import 'package:ea24_mobile/helpers/reg_ex_inpur_formatter.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/helpers/shimmer_helper.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/repositories/brand_repository.dart';
import 'package:ea24_mobile/repositories/category_repository.dart';
import 'package:ea24_mobile/repositories/product_repository.dart';
import 'package:ea24_mobile/repositories/shop_repository.dart';
import 'package:ea24_mobile/ui_elements/brand_square_card.dart';
import 'package:ea24_mobile/ui_elements/product_card.dart';
import 'package:ea24_mobile/ui_elements/shop_square_card.dart';

import 'package:flutter/material.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:one_context/one_context.dart';

import '../repositories/search_repository.dart';

class WhichFilter {
  final String optionKey;
  final String name;

  WhichFilter(this.optionKey, this.name);

  static List<WhichFilter> getWhichFilterList() {
    return <WhichFilter>[
      WhichFilter(
        'product',
        AppLocalizations.of(OneContext().context!)!.product_ucf,
      ),
      WhichFilter(
        'sellers',
        AppLocalizations.of(OneContext().context!)!.sellers_ucf,
      ),
      WhichFilter(
        'brands',
        AppLocalizations.of(OneContext().context!)!.brands_ucf,
      ),
    ];
  }
}

class Filter extends StatefulWidget {
  const Filter({super.key, this.selectedFilter = "product"});

  final String selectedFilter;

  @override
  State<Filter> createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  final _amountValidator = RegExInputFormatter.withRegex(
    '^\$|^(0|([1-9][0-9]{0,}))(\\.[0-9]{0,})?\$',
  );

  final ScrollController _productScrollController = ScrollController();
  final ScrollController _brandScrollController = ScrollController();
  final ScrollController _shopScrollController = ScrollController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ScrollController? _scrollController;
  WhichFilter? _selectedFilter;
  String? _givenSelectedFilterOptionKey;
  String? _selectedSort = "";

  final List<WhichFilter> _whichFilterList = WhichFilter.getWhichFilterList();
  List<DropdownMenuItem<WhichFilter>>? _dropdownWhichFilterItems;
  final List<dynamic> _selectedCategories = [];
  final List<dynamic> _selectedBrands = [];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  final List<dynamic> _filterBrandList = [];
  final List<dynamic> _filterCategoryList = [];

  final List<dynamic> _searchSuggestionList = [];
  String? _searchKey = "";

  final List<dynamic> _productList = [];
  bool _isProductInitial = true;
  int _productPage = 1;
  int? _totalProductData = 0;
  bool _showProductLoadingContainer = false;

  final List<dynamic> _brandList = [];
  bool _isBrandInitial = true;
  int _brandPage = 1;
  int? _totalBrandData = 0;
  bool _showBrandLoadingContainer = false;

  final List<dynamic> _shopList = [];
  bool _isShopInitial = true;
  int _shopPage = 1;
  int? _totalShopData = 0;
  bool _showShopLoadingContainer = false;
  fetchFilteredBrands() async {
    var filteredBrandResponse = await BrandRepository().getFilterPageBrands();
    _filterBrandList.addAll(filteredBrandResponse.brands!);
    setState(() {});
  }

  fetchFilteredCategories() async {
    var filteredCategoriesResponse = await CategoryRepository()
        .getFilterPageCategories();
    _filterCategoryList.addAll(filteredCategoriesResponse.categories!);
    setState(() {});
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    _productScrollController.dispose();
    _brandScrollController.dispose();
    _shopScrollController.dispose();
    super.dispose();
  }

  init() {
    _givenSelectedFilterOptionKey = widget.selectedFilter;

    _dropdownWhichFilterItems = buildDropdownWhichFilterItems(_whichFilterList);
    _selectedFilter = _dropdownWhichFilterItems![0].value;

    for (int x = 0; x < _dropdownWhichFilterItems!.length; x++) {
      if (_dropdownWhichFilterItems![x].value!.optionKey ==
          _givenSelectedFilterOptionKey) {
        _selectedFilter = _dropdownWhichFilterItems![x].value;
      }
    }

    fetchFilteredCategories();
    fetchFilteredBrands();

    if (_selectedFilter!.optionKey == "sellers") {
      fetchShopData();
    } else if (_selectedFilter!.optionKey == "brands") {
      fetchBrandData();
    } else {
      fetchProductData();
    }

    //set scroll listeners

    _productScrollController.addListener(() {
      if (_productScrollController.position.pixels ==
          _productScrollController.position.maxScrollExtent) {
        setState(() {
          _productPage++;
        });
        _showProductLoadingContainer = true;
        fetchProductData();
      }
    });

    _brandScrollController.addListener(() {
      if (_brandScrollController.position.pixels ==
          _brandScrollController.position.maxScrollExtent) {
        setState(() {
          _brandPage++;
        });
        _showBrandLoadingContainer = true;
        fetchBrandData();
      }
    });

    _shopScrollController.addListener(() {
      if (_shopScrollController.position.pixels ==
          _shopScrollController.position.maxScrollExtent) {
        setState(() {
          _shopPage++;
        });
        _showShopLoadingContainer = true;
        fetchShopData();
      }
    });
  }

  fetchProductData() async {
    var productResponse = await ProductRepository().getFilteredProducts(
      page: _productPage,
      name: _searchKey,
      sortKey: _selectedSort,
      brands: _selectedBrands.join(",").toString(),
      categories: _selectedCategories.join(",").toString(),
      max: _maxPriceController.text.toString(),
      min: _minPriceController.text.toString(),
    );

    _productList.addAll(productResponse.products!);
    _isProductInitial = false;
    _totalProductData = productResponse.meta!.total;
    _showProductLoadingContainer = false;
    setState(() {});
  }

  resetProductList() {
    _productList.clear();
    _isProductInitial = true;
    _totalProductData = 0;
    _productPage = 1;
    _showProductLoadingContainer = false;
    setState(() {});
  }

  fetchBrandData() async {
    var brandResponse = await BrandRepository().getBrands(
      page: _brandPage,
      name: _searchKey,
    );
    _brandList.addAll(brandResponse.brands!);
    _isBrandInitial = false;
    _totalBrandData = brandResponse.meta!.total;
    _showBrandLoadingContainer = false;
    setState(() {});
  }

  resetBrandList() {
    _brandList.clear();
    _isBrandInitial = true;
    _totalBrandData = 0;
    _brandPage = 1;
    _showBrandLoadingContainer = false;
    setState(() {});
  }

  fetchShopData() async {
    var shopResponse = await ShopRepository().getShops(
      page: _shopPage,
      name: _searchKey,
    );
    _shopList.addAll(shopResponse.shops);
    _isShopInitial = false;
    _totalShopData = shopResponse.meta.total;
    _showShopLoadingContainer = false;
    setState(() {});
  }

  reset() {
    _searchSuggestionList.clear();
    setState(() {});
  }

  resetShopList() {
    _shopList.clear();
    _isShopInitial = true;
    _totalShopData = 0;
    _shopPage = 1;
    _showShopLoadingContainer = false;
    setState(() {});
  }

  Future<void> _onProductListRefresh() async {
    reset();
    resetProductList();
    fetchProductData();
  }

  Future<void> _onBrandListRefresh() async {
    reset();
    resetBrandList();
    fetchBrandData();
  }

  Future<void> _onShopListRefresh() async {
    reset();
    resetShopList();
    fetchShopData();
  }

  _applyProductFilter() {
    reset();
    resetProductList();
    fetchProductData();
  }

  _onSearchSubmit() {
    reset();
    if (_selectedFilter!.optionKey == "sellers") {
      resetShopList();
      fetchShopData();
    } else if (_selectedFilter!.optionKey == "brands") {
      resetBrandList();
      fetchBrandData();
    } else {
      resetProductList();
      fetchProductData();
    }
  }

  _onSortChange() {
    reset();
    resetProductList();
    fetchProductData();
  }

  _onWhichFilterChange() {
    if (_selectedFilter!.optionKey == "sellers") {
      resetShopList();
      fetchShopData();
    } else if (_selectedFilter!.optionKey == "brands") {
      resetBrandList();
      fetchBrandData();
    } else {
      resetProductList();
      fetchProductData();
    }
  }

  List<DropdownMenuItem<WhichFilter>> buildDropdownWhichFilterItems(
    List whichFilterList,
  ) {
    List<DropdownMenuItem<WhichFilter>> items = [];
    for (WhichFilter whichFilterItem
        in whichFilterList as Iterable<WhichFilter>) {
      items.add(
        DropdownMenuItem(
          value: whichFilterItem,
          child: Text(whichFilterItem.name),
        ),
      );
    }
    return items;
  }

  Container buildProductLoadingContainer() {
    return Container(
      height: _showProductLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(
          _totalProductData == _productList.length
              ? AppLocalizations.of(context)!.no_more_products_ucf
              : AppLocalizations.of(context)!.loading_more_products_ucf,
        ),
      ),
    );
  }

  Container buildBrandLoadingContainer() {
    return Container(
      height: _showBrandLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(
          _totalBrandData == _brandList.length
              ? AppLocalizations.of(context)!.no_more_brands_ucf
              : AppLocalizations.of(context)!.loading_more_brands_ucf,
        ),
      ),
    );
  }

  Container buildShopLoadingContainer() {
    return Container(
      height: _showShopLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(
          _totalShopData == _shopList.length
              ? AppLocalizations.of(context)!.no_more_shops_ucf
              : AppLocalizations.of(context)!.loading_more_shops_ucf,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        endDrawer: buildFilterDrawer(),
        key: _scaffoldKey,
        backgroundColor: MyTheme.mainColor,
        body: Stack(
          fit: StackFit.loose,
          children: [
            _selectedFilter!.optionKey == 'product'
                ? buildProductList()
                : (_selectedFilter!.optionKey == 'brands'
                      ? buildBrandList()
                      : buildShopList()),
            Positioned(
              top: 10.0,
              left: 0.0,
              right: 0.0,
              child: buildAppBar(context),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _selectedFilter!.optionKey == 'product'
                  ? buildProductLoadingContainer()
                  : (_selectedFilter!.optionKey == 'brands'
                        ? buildBrandLoadingContainer()
                        : buildShopLoadingContainer()),
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor.withValues(alpha: .95),
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0.0,
      actions: [Container()],
      centerTitle: false,
      flexibleSpace: Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 14.0, 0.0, 0.0),
        child: Column(
          children: [buildTopAppbar(context), buildBottomAppBar(context)],
        ),
      ),
    );
  }

  Row buildBottomAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.symmetric(
              vertical: BorderSide(color: MyTheme.light_grey, width: .5),
              horizontal: BorderSide(color: MyTheme.light_grey, width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          height: MediaQuery.of(context).size.height * .04,
          width: MediaQuery.of(context).size.width * .33,
          child: DropdownButton<WhichFilter>(
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(5),
            icon: Padding(
              padding: app_language_rtl.$!
                  ? const EdgeInsets.only(right: 18.0)
                  : const EdgeInsets.only(left: 18.0),
              child: Icon(Icons.expand_more, color: Colors.black54),
            ),
            hint: Text(
              AppLocalizations.of(context)!.products_ucf,
              style: TextStyle(color: Colors.black, fontSize: 13),
            ),
            style: TextStyle(color: Colors.black, fontSize: 13),
            iconSize: 13,
            underline: SizedBox(),
            value: _selectedFilter,
            items: _dropdownWhichFilterItems,
            isExpanded: true,
            onChanged: (WhichFilter? selectedFilter) {
              setState(() {
                _selectedFilter = selectedFilter;
              });

              _onWhichFilterChange();
            },
          ),
        ),
        GestureDetector(
          onTap: () {
            _selectedFilter!.optionKey == "product"
                ? _scaffoldKey.currentState!.openEndDrawer()
                : ToastComponent.showDialog(
                    AppLocalizations.of(
                      context,
                    )!.you_can_use_sorting_while_searching_for_products,
                  );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.symmetric(
                vertical: BorderSide(color: MyTheme.light_grey, width: .5),
                horizontal: BorderSide(color: MyTheme.light_grey, width: 1),
              ),
            ),
            height: MediaQuery.of(context).size.height * .04,
            width: MediaQuery.of(context).size.width * .33,
            child: Center(
              child: SizedBox(
                width: 55,
                child: Row(
                  children: [
                    Icon(Icons.filter_alt_outlined, size: 13),
                    SizedBox(width: 2),
                    Text(
                      AppLocalizations.of(context)!.filter_ucf,
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            _selectedFilter!.optionKey == "product"
                ? showDialog(
                    context: context,
                    builder: (_) => Directionality(
                      textDirection: app_language_rtl.$!
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: AlertDialog(
                        contentPadding: EdgeInsets.only(
                          top: 16.0,
                          left: 2.0,
                          right: 2.0,
                          bottom: 2.0,
                        ),
                        content: StatefulBuilder(
                          builder:
                              (BuildContext context, StateSetter setState) {
                                return RadioGroup<String>(
                                  groupValue: _selectedSort,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSort = value!;
                                    });
                                    _onSortChange();
                                    Navigator.pop(context);
                                  },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24.0,
                                        ),
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.sort_products_by_ucf,
                                        ),
                                      ),

                                      _radioItem(
                                        context,
                                        value: "",
                                        text: AppLocalizations.of(
                                          context,
                                        )!.def_ault_ucf,
                                      ),

                                      _radioItem(
                                        context,
                                        value: "price_high_to_low",
                                        text: AppLocalizations.of(
                                          context,
                                        )!.price_high_to_low,
                                      ),

                                      _radioItem(
                                        context,
                                        value: "price_low_to_high",
                                        text: AppLocalizations.of(
                                          context,
                                        )!.price_low_to_high,
                                      ),

                                      _radioItem(
                                        context,
                                        value: "new_arrival",
                                        text: AppLocalizations.of(
                                          context,
                                        )!.new_arrival_ucf,
                                      ),

                                      _radioItem(
                                        context,
                                        value: "popularity",
                                        text: AppLocalizations.of(
                                          context,
                                        )!.popularity_ucf,
                                      ),

                                      _radioItem(
                                        context,
                                        value: "top_rated",
                                        text: AppLocalizations.of(
                                          context,
                                        )!.top_rated_ucf,
                                      ),
                                    ],
                                  ),
                                );
                              },
                        ),
                        actions: [
                          Btn.basic(
                            child: Text(
                              AppLocalizations.of(context)!.close_all_capital,
                              style: TextStyle(color: MyTheme.medium_grey),
                            ),
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : ToastComponent.showDialog(
                    AppLocalizations.of(
                      context,
                    )!.you_can_use_filters_while_searching_for_products,
                  );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.symmetric(
                vertical: BorderSide(color: MyTheme.light_grey, width: .5),
                horizontal: BorderSide(color: MyTheme.light_grey, width: 1),
              ),
            ),
            height: 36,
            width: MediaQuery.of(context).size.width * .33,
            child: Center(
              child: SizedBox(
                width: 50,
                child: Row(
                  children: [
                    Icon(Icons.swap_vert, size: 13),
                    SizedBox(width: 2),
                    Text(
                      AppLocalizations.of(context)!.sort_ucf,
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _radioItem(
    BuildContext context, {
    required String value,
    required String text,
  }) {
    return RadioListTile<String>(
      dense: true,
      value: value,
      activeColor: MyTheme.font_grey,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(text),
    );
  }

  Row buildTopAppbar(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: 16),
        Padding(
          padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.93,
            height: 70,
            child: Padding(
              padding: MediaQuery.of(context).viewPadding.top > 30
                  ? const EdgeInsets.symmetric(vertical: 15.0, horizontal: 0.0)
                  : const EdgeInsets.symmetric(vertical: 5.0, horizontal: 0.0),
              child: TypeAheadField(
                suggestionsCallback: (pattern) async {
                  var suggestions = await SearchRepository()
                      .getSearchSuggestionListResponse(
                        queryKey: pattern,
                        type: _selectedFilter!.optionKey,
                      );

                  return suggestions;
                },
                loadingBuilder: (context) {
                  return Container(
                    height: 40,
                    color: Colors.white,
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.loading_suggestions,
                        style: TextStyle(color: MyTheme.medium_grey),
                      ),
                    ),
                  );
                },
                itemBuilder: (context, dynamic suggestion) {
                  var subtitle =
                      "${AppLocalizations.of(context)!.searched_for_all_lower} ${suggestion.count} ${AppLocalizations.of(context)!.times_all_lower}";
                  if (suggestion.type != "search") {
                    subtitle =
                        "${suggestion.type_string} ${AppLocalizations.of(context)!.found_all_lower}";
                  }
                  return ListTile(
                    tileColor: Colors.white,
                    dense: true,
                    title: Text(
                      suggestion.query,
                      style: TextStyle(
                        color: suggestion.type != "search"
                            ? MyTheme.accent_color
                            : MyTheme.font_grey,
                      ),
                    ),
                    subtitle: Text(
                      subtitle,
                      style: TextStyle(
                        color: suggestion.type != "search"
                            ? MyTheme.font_grey
                            : MyTheme.medium_grey,
                      ),
                    ),
                  );
                },
                onSelected: (dynamic suggestion) {
                  _searchController.text = suggestion.query;
                  _searchKey = suggestion.query;
                  setState(() {});
                  _onSearchSubmit();
                },
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    obscureText: false,
                    decoration: InputDecoration(
                      prefixIcon: IconButton(
                        padding: EdgeInsets.zero,
                        icon: UsefulElements.backButton(context),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      filled: true,
                      fillColor: MyTheme.white,
                      suffixIcon: Icon(
                        Icons.search,
                        color: MyTheme.medium_grey,
                      ),
                      hintText: AppLocalizations.of(context)!.search_here_ucf,
                      hintStyle: TextStyle(
                        fontSize: 12.0,
                        color: MyTheme.textfield_grey,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: MyTheme.noColor,
                          width: 0.5,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: MyTheme.noColor,
                          width: 1.0,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                      ),
                      contentPadding: EdgeInsets.only(
                        left: 8.0,
                        top: 5.0,
                        bottom: 5.0,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  buildFilterDrawer() {
    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Drawer(
        backgroundColor: Colors.white,
        child: Container(
          padding: EdgeInsets.only(top: 50),
          child: Column(
            children: [
              SizedBox(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          AppLocalizations.of(context)!.price_range_ucf,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: SizedBox(
                              height: 30,
                              width: 100,
                              child: TextField(
                                controller: _minPriceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [_amountValidator],
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(
                                    context,
                                  )!.minimum_ucf,
                                  hintStyle: TextStyle(
                                    fontSize: 12.0,
                                    color: MyTheme.textfield_grey,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: MyTheme.textfield_grey,
                                      width: 1.0,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(4.0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: MyTheme.textfield_grey,
                                      width: 2.0,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(4.0),
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.all(4.0),
                                ),
                              ),
                            ),
                          ),
                          Text(" - "),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: SizedBox(
                              height: 30,
                              width: 100,
                              child: TextField(
                                controller: _maxPriceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [_amountValidator],
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(
                                    context,
                                  )!.maximum_ucf,
                                  hintStyle: TextStyle(
                                    fontSize: 12.0,
                                    color: MyTheme.textfield_grey,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: MyTheme.textfield_grey,
                                      width: 1.0,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(4.0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: MyTheme.textfield_grey,
                                      width: 2.0,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(4.0),
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.all(4.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverList(
                      delegate: SliverChildListDelegate([
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            AppLocalizations.of(context)!.categories_ucf,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _filterCategoryList.isEmpty
                            ? SizedBox(
                                height: 100,
                                child: Center(
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.no_category_is_available,
                                    style: TextStyle(color: MyTheme.font_grey),
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                child: buildFilterCategoryList(),
                              ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Text(
                            AppLocalizations.of(context)!.brands_ucf,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _filterBrandList.isEmpty
                            ? SizedBox(
                                height: 100,
                                child: Center(
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.no_brand_is_available,
                                    style: TextStyle(color: MyTheme.font_grey),
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                child: buildFilterBrandsList(),
                              ),
                      ]),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () {
                        _minPriceController.clear();
                        _maxPriceController.clear();
                        setState(() {
                          _selectedCategories.clear();
                          _selectedBrands.clear();
                        });
                      },
                      child: Text(
                        AppLocalizations.of(context)!.clear_all_capital,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        var min = _minPriceController.text.toString();
                        var max = _maxPriceController.text.toString();
                        bool apply = true;
                        if (min != "" && max != "") {
                          if (max.compareTo(min) < 0) {
                            ToastComponent.showDialog(
                              AppLocalizations.of(
                                context,
                              )!.filter_screen_min_max_warning,
                            );
                            apply = false;
                          }
                        }

                        if (apply) {
                          _applyProductFilter();
                        }
                      },
                      child: Text(
                        AppLocalizations.of(context)!.apply_all_capital,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ListView buildFilterBrandsList() {
    return ListView(
      padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: <Widget>[
        ..._filterBrandList.map(
          (brand) => CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            title: Text(brand.name),
            value: _selectedBrands.contains(brand.id),
            onChanged: (bool? value) {
              if (value!) {
                setState(() {
                  _selectedBrands.add(brand.id);
                });
              } else {
                setState(() {
                  _selectedBrands.remove(brand.id);
                });
              }
            },
          ),
        ),
      ],
    );
  }

  ListView buildFilterCategoryList() {
    return ListView(
      padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: <Widget>[
        ..._filterCategoryList.map(
          (category) => CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            title: Text(category.name),
            value: _selectedCategories.contains(category.id),
            onChanged: (bool? value) {
              if (value!) {
                setState(() {
                  _selectedCategories.clear();
                  _selectedCategories.add(category.id);
                });
              } else {
                setState(() {
                  _selectedCategories.remove(category.id);
                });
              }
            },
          ),
        ),
      ],
    );
  }

  SizedBox buildProductList() {
    return SizedBox(
      child: Column(children: [Expanded(child: buildProductScrollableList())]),
    );
  }

  buildProductScrollableList() {
    if (_isProductInitial && _productList.isEmpty) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildProductGridShimmer(
          scontroller: _scrollController,
        ),
      );
    } else if (_productList.isNotEmpty) {
      return RefreshIndicator(
        color: Colors.white,
        backgroundColor: MyTheme.accent_color,
        onRefresh: _onProductListRefresh,
        child: SingleChildScrollView(
          controller: _productScrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).viewPadding.top > 40 ? 150 : 135,
              ),
              MasonryGridView.count(
                itemCount: _productList.length,
                controller: _scrollController,
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                padding: EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                  left: 18,
                  right: 18,
                ),
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  // 3
                  return ProductCard(
                    id: _productList[index].id,
                    slug: _productList[index].slug,
                    image: _productList[index].thumbnailImage,
                    name: _productList[index].name,
                    mainPrice: _productList[index].mainPrice,
                    strokedPrice: _productList[index].strokedPrice,
                    hasDiscount: _productList[index].hasDiscount,
                    discount: _productList[index].discount,
                    isWholesale: _productList[index].isWholesale,
                  );
                },
              ),
            ],
          ),
        ),
      );
    } else if (_totalProductData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_product_is_available),
      );
    } else {
      return Container();
    }
  }

  SizedBox buildBrandList() {
    return SizedBox(
      child: Column(children: [Expanded(child: buildBrandScrollableList())]),
    );
  }

  buildBrandScrollableList() {
    if (_isBrandInitial && _brandList.isEmpty) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildSquareGridShimmer(
          scontroller: _scrollController,
        ),
      );
    } else if (_brandList.isNotEmpty) {
      return RefreshIndicator(
        color: Colors.white,
        backgroundColor: MyTheme.accent_color,
        onRefresh: _onBrandListRefresh,
        child: SingleChildScrollView(
          controller: _brandScrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).viewPadding.top > 40 ? 140 : 135,
              ),
              GridView.builder(
                itemCount: _brandList.length,
                controller: _scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1,
                ),
                padding: EdgeInsets.only(
                  top: 20,
                  bottom: 10,
                  left: 18,
                  right: 18,
                ),
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  // 3
                  return BrandSquareCard(
                    id: _brandList[index].id,
                    slug: _brandList[index].slug,
                    image: _brandList[index].logo,
                    name: _brandList[index].name,
                  );
                },
              ),
            ],
          ),
        ),
      );
    } else if (_totalBrandData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_brand_is_available),
      );
    } else {
      return Container();
    }
  }

  SizedBox buildShopList() {
    return SizedBox(
      child: Column(children: [Expanded(child: buildShopScrollableList())]),
    );
  }

  buildShopScrollableList() {
    if (_isShopInitial && _shopList.isEmpty) {
      return SingleChildScrollView(
        controller: _scrollController,
        child: ShimmerHelper().buildSquareGridShimmer(
          scontroller: _scrollController,
        ),
      );
    } else if (_shopList.isNotEmpty) {
      return RefreshIndicator(
        color: Colors.white,
        backgroundColor: MyTheme.accent_color,
        onRefresh: _onShopListRefresh,
        child: SingleChildScrollView(
          controller: _shopScrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).viewPadding.top > 40 ? 140 : 135,
              ),
              GridView.builder(
                itemCount: _shopList.length,
                controller: _scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.7,
                ),
                padding: EdgeInsets.only(
                  top: 20,
                  bottom: 10,
                  left: 18,
                  right: 18,
                ),
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return ShopSquareCard(
                    id: _shopList[index].id,
                    shopSlug: _shopList[index].slug,
                    image: _shopList[index].logo,
                    name: _shopList[index].name,
                    stars: double.parse(_shopList[index].rating.toString()),
                  );
                },
              ),
            ],
          ),
        ),
      );
    } else if (_totalShopData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_shop_is_available),
      );
    } else {
      return Container();
    }
  }
}
