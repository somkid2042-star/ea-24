import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../helpers/shimmer_helper.dart';
import '../presenter/home_presenter.dart';
import '../ui_elements/product_card_black.dart';

class HomeAllProducts2 extends StatelessWidget {
  final HomePresenter homeData;

  const HomeAllProducts2({super.key, required this.homeData});

  @override
  Widget build(BuildContext context) {
    if (homeData.isAllProductInitial) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildProductGridShimmer(
          scontroller: homeData.allProductScrollController,
        ),
      );
    } else if (homeData.allProductList.isNotEmpty) {
      return MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 14.h,
        crossAxisSpacing: 14.w,
        itemCount: homeData.allProductList.length,
        shrinkWrap: true,
        cacheExtent: 500,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final product = homeData.allProductList[index];
          return ProductCardBlack(
            id: product.id,
            slug: product.slug ?? product.id.toString(),
            image: product.thumbnailImage,
            name: product.name,
            mainPrice: product.mainPrice,
            strokedPrice: product.strokedPrice,
            hasDiscount: product.hasDiscount??false,
            discount: product.discount,
            isWholesale: product.isWholesale,
          );
        },
      );
    } else if (homeData.totalAllProductData == 0) {
      return Center(
        child: Text(AppLocalizations.of(context)!.no_product_is_available),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
