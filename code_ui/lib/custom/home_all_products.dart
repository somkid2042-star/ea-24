import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';

import '../helpers/shimmer_helper.dart';
import '../presenter/home_presenter.dart';
import '../ui_elements/product_card.dart';

class HomeAllProducts extends StatelessWidget {
  final BuildContext? context;
  final HomePresenter? homeData;
  const HomeAllProducts({super.key, this.context, this.homeData});

  @override
  Widget build(BuildContext context) {
    if (homeData!.isAllProductInitial && homeData!.allProductList.isEmpty) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildProductGridShimmer(
          scontroller: homeData!.allProductScrollController,
        ),
      );
    } else if (homeData!.allProductList.isNotEmpty) {
      return GridView.builder(
        itemCount: homeData!.allProductList.length,
        controller: homeData!.allProductScrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.618,
        ),
        padding: EdgeInsets.all(16.0),
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return ProductCard(
            id: homeData!.allProductList[index].id,
            slug: homeData!.allProductList[index].slug.toString(),
            image: homeData!.allProductList[index].thumbnailImage,
            name: homeData!.allProductList[index].name,
            mainPrice: homeData!.allProductList[index].mainPrice,
            strokedPrice: homeData!.allProductList[index].strokedPrice,
            hasDiscount: homeData!.allProductList[index].hasDiscount??false,
            discount: homeData!.allProductList[index].discount,
            isWholesale: null,
          );
        },
      );
    } else if (homeData!.totalAllProductData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_product_is_available),
      );
    } else {
      return Container();
    }
  }
}
