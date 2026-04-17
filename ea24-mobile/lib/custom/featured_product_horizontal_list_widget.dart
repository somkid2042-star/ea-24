import 'package:flutter/material.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../helpers/shimmer_helper.dart';
import '../my_theme.dart';
import '../presenter/home_presenter.dart';
import '../ui_elements/mini_product_card.dart';

class FeaturedProductHorizontalListWidget extends StatelessWidget {
  final HomePresenter homeData;
  const FeaturedProductHorizontalListWidget({
    super.key,
    required this.homeData,
  });

  @override
  Widget build(BuildContext context) {
    if (homeData.isFeaturedProductInitial == true &&
        homeData.featuredProductList.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.0.r),
              child: ShimmerHelper().buildBasicShimmer(
                height: 120.0.h,
                width: (1.sw - 64.w) / 3,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.0.r),
              child: ShimmerHelper().buildBasicShimmer(
                height: 120.0.h,
                width: (1.sw - 64.w) / 3,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.0.r),
              child: ShimmerHelper().buildBasicShimmer(
                height: 120.0.h,
                width: (1.sw - 160.w) / 3,
              ),
            ),
          ),
        ],
      );
    } else if (homeData.featuredProductList.isNotEmpty) {
      return SingleChildScrollView(
        child: SizedBox(
          height: 210.h,
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                  scrollInfo.metrics.maxScrollExtent) {
                homeData.fetchFeaturedProducts();
              }
              return true;
            },
            child: ListView.separated(
              padding: EdgeInsets.zero,
              separatorBuilder: (context, index) => SizedBox(width: 12.w),
              itemCount:
                  homeData.totalFeaturedProductData! >
                      homeData.featuredProductList.length
                  ? homeData.featuredProductList.length + 1
                  : homeData.featuredProductList.length,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemBuilder: (context, index) {
                return (index == homeData.featuredProductList.length)
                    ? SpinKitFadingFour(
                        itemBuilder: (BuildContext context, int index) {
                          return const DecoratedBox(
                            decoration: BoxDecoration(color: Colors.white),
                          );
                        },
                      )
                    : MiniProductCard(
                        id: homeData.featuredProductList[index].id,
                        slug: homeData.featuredProductList[index].slug??homeData.featuredProductList[index].id.toString(),
                        image:
                            homeData.featuredProductList[index].thumbnailImage,
                        name: homeData.featuredProductList[index].name,
                        mainPrice:
                            homeData.featuredProductList[index].mainPrice,
                        strokedPrice:
                            homeData.featuredProductList[index].strokedPrice,
                        hasDiscount:
                            homeData.featuredProductList[index].hasDiscount,
                        isWholesale:
                            homeData.featuredProductList[index].isWholesale,
                        discount: homeData.featuredProductList[index].discount,
                      );
              },
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        height: 100.h,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_related_product,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    }
  }
}
