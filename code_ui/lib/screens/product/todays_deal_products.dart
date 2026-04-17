
import 'package:active_ecommerce_cms_demo_app/providers/todays_deal_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../../helpers/shimmer_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../my_theme.dart';
import '../../ui_elements/product_card.dart';

class TodaysDealProducts extends StatefulWidget {
  const TodaysDealProducts({super.key});

  @override
  State<TodaysDealProducts> createState() => _TodaysDealProductsState();
}

class _TodaysDealProductsState extends State<TodaysDealProducts> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<TodaysDealProvider>()
          .fetchTodaysDealProducts();
    });
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: MyTheme.mainColor,
      body: Consumer<TodaysDealProvider>(
        builder: (context, provider, child) {
          ///  Loading
          if (provider.isLoading) {
            return ShimmerHelper().buildProductGridShimmer(
              scontroller: _scrollController,
            );
          }

          ///  Error
          if (provider.hasError) {
            return Center(
              child: Text(
                "Something went wrong",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          /// Empty
          if (!provider.hasData) {
            return Center(
              child: Text("No products available"),
            );
          }

          final products = provider.productMiniResponse!.products!;

          /// Data + Pull To Refresh
          return RefreshIndicator(
            backgroundColor: MyTheme.white,
            color: MyTheme.accent_color,
            onRefresh: () async {
              await context
                  .read<TodaysDealProvider>()
                  .fetchTodaysDealProducts();
            },
            child: MasonryGridView.count(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              itemCount: products.length,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  id: product.id,
                  slug: product.slug ?? '',
                  image: product.thumbnailImage ?? '',
                  name: product.name ?? '',
                  mainPrice: product.mainPrice ?? '',
                  strokedPrice: product.strokedPrice ?? '',
                  hasDiscount: product.hasDiscount ?? false,
                  discount: product.discount ?? '',
                  isWholesale: product.isWholesale ?? false,
                );
              },
            ),
          );
        },
      ),
    );
  }
  AppBar _buildAppBar(BuildContext context) {
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
        AppLocalizations.of(context)!.todays_deal_ucf,
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
