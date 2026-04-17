import 'package:ea24_mobile/helpers/shimmer_helper.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/repositories/product_repository.dart';
import 'package:ea24_mobile/ui_elements/product_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class BrandProducts extends StatefulWidget {
  final String slug;
  const BrandProducts({super.key, required this.slug});
  @override
  State<BrandProducts> createState() => _BrandProductsState();
}

class _BrandProductsState extends State<BrandProducts> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _xcrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<dynamic> _productList = [];
  bool _isInitial = true;
  int _page = 1;
  String _searchKey = "";
  int? _totalData = 0;
  bool _showLoadingContainer = false;

  @override
  void initState() {
    super.initState();

    fetchData();

    _xcrollController.addListener(() {
      if (_xcrollController.position.pixels ==
          _xcrollController.position.maxScrollExtent) {
        setState(() {
          _page++;
        });
        _showLoadingContainer = true;
        fetchData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _xcrollController.dispose();
    super.dispose();
  }

  fetchData() async {
    var productResponse = await ProductRepository().getBrandProducts(
      slug: widget.slug,
      page: _page,
      name: _searchKey,
    );
    _productList.addAll(productResponse.products!);
    _isInitial = false;
    _totalData = productResponse.meta!.total;
    _showLoadingContainer = false;
    setState(() {});
  }

  reset() {
    _productList.clear();
    _isInitial = true;
    _totalData = 0;
    _page = 1;
    _showLoadingContainer = false;
    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.mainColor,
      appBar: buildAppBar(context),
      body: Stack(
        children: [
          buildProductList(),
          Align(
            alignment: Alignment.bottomCenter,
            child: buildLoadingContainer(),
          ),
        ],
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
          _totalData == _productList.length
              ? AppLocalizations.of(context)!.no_more_products_ucf
              : AppLocalizations.of(context)!.loading_more_products_ucf,
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: SizedBox(
        width: 250,
        child: TextField(
          controller: _searchController,
          onTap: () {},
          onChanged: (txt) {
            /*_searchKey = txt;
              reset();
              fetchData();*/
          },
          onSubmitted: (txt) {
            _searchKey = txt;
            reset();
            fetchData();
          },
          autofocus: true,
          decoration: InputDecoration(
            hintText: "${AppLocalizations.of(context)!.search_product_here} : ",
            hintStyle: TextStyle(fontSize: 14.0, color: MyTheme.textfield_grey),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: MyTheme.white, width: 0.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: MyTheme.white, width: 0.0),
            ),
            contentPadding: EdgeInsets.all(0.0),
          ),
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          child: IconButton(
            icon: Icon(Icons.search, color: MyTheme.dark_grey),
            onPressed: () {
              _searchKey = _searchController.text.toString();
              setState(() {});
              reset();
              fetchData();
            },
          ),
        ),
      ],
    );
  }

  buildProductList() {
    if (_isInitial && _productList.isEmpty) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildProductGridShimmer(
          scontroller: _scrollController,
        ),
      );
    } else if (_productList.isNotEmpty) {
      return RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        displacement: 0,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          controller: _xcrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            itemCount: _productList.length,
            shrinkWrap: true,
            padding: EdgeInsets.only(
              top: 10.0,
              bottom: 10,
              left: 18,
              right: 18,
            ),
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              // 3
              return ProductCard(
                id: _productList[index].id,
                slug: _productList[index].slug,
                image: _productList[index].thumbnailImage,
                name: _productList[index].name,
                mainPrice: _productList[index].mainPrice,
                strokedPrice: _productList[index].strokedPrice,
                hasDiscount: _productList[index].hasDiscount ?? false,
                discount: _productList[index].discount,
                isWholesale: _productList[index].isWholesale,
              );
            },
          ),
        ),
      );
    } else if (_totalData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_data_is_available),
      );
    } else {
      return Container();
    }
  }
}
