import 'package:ea24_mobile/data_model/product_mini_response.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/helpers/shimmer_helper.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/repositories/product_repository.dart';
import 'package:ea24_mobile/ui_elements/product_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class TopSellingProducts extends StatefulWidget {
  const TopSellingProducts({super.key});

  @override
  State<TopSellingProducts> createState() => _TopSellingProductsState();
}

class _TopSellingProductsState extends State<TopSellingProducts> {
  late Future<ProductMiniResponse> _productsFuture;
  bool _isInitialLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _productsFuture = ProductRepository().getBestSellingProducts();
    _productsFuture.whenComplete(() {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _isRefreshing = true;
    });

    final newFuture = ProductRepository().getBestSellingProducts();

    await newFuture;

    if (mounted) {
      setState(() {
        _productsFuture = newFuture;
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.mainColor,
        appBar: buildAppBar(context),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: _isInitialLoading || _isRefreshing
              ? SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ShimmerHelper().buildProductGridShimmer(),
          )
              : FutureBuilder<ProductMiniResponse>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ShimmerHelper().buildProductGridShimmer(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                       'Something went wrong.',
                        style: TextStyle(color: MyTheme.dark_font_grey),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.products!.isEmpty) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)!.no_product_is_available,
                    style: TextStyle(color: MyTheme.dark_font_grey),
                  ),
                );
              }

              var productResponse = snapshot.data!;

              return MasonryGridView.count(
                physics: const AlwaysScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                itemCount: productResponse.products!.length,
                padding: const EdgeInsets.only(
                  top: 20.0,
                  bottom: 10,
                  left: 18,
                  right: 18,
                ),
                itemBuilder: (context, index) {
                  return ProductCard(
                    id: productResponse.products![index].id,
                    slug: productResponse.products![index].slug!,
                    image: productResponse.products![index].thumbnailImage,
                    name: productResponse.products![index].name,
                    mainPrice: productResponse.products![index].mainPrice,
                    strokedPrice:
                    productResponse.products![index].strokedPrice,
                    hasDiscount:
                    productResponse.products![index].hasDiscount!,
                    discount: productResponse.products![index].discount,
                    isWholesale:
                    productResponse.products![index].isWholesale,
                    rating: productResponse.products![index].rating,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.top_selling_products_ucf,
        style: TextStyle(
          fontSize: 16,
          color: MyTheme.dark_font_grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}