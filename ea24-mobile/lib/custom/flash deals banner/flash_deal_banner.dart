import 'package:ea24_mobile/custom/aiz_image.dart';
import 'package:ea24_mobile/helpers/shimmer_helper.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/presenter/home_presenter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:ea24_mobile/repositories/product_repository.dart';
import 'package:ea24_mobile/data_model/product_mini_response.dart'
    // ignore: library_prefixes
    as productMini;

import '../../screens/product/product_details/product_details.dart';

class FlashDealBanner extends StatefulWidget {
  final HomePresenter? homeData;

  const FlashDealBanner({super.key, this.homeData});

  @override
  State<FlashDealBanner> createState() => _FlashDealBannerState();
}

class _FlashDealBannerState extends State<FlashDealBanner> {
  Future<productMini.ProductMiniResponse>? _productFuture;

  @override
  void initState() {
    super.initState();
    var featuredDeal = widget.homeData?.getFeaturedFlashDeal();
    if (featuredDeal != null && featuredDeal.slug != null) {
      _productFuture = ProductRepository().getFlashDealProducts(
        featuredDeal.slug,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.homeData == null) {
      return SizedBox(
        height: 100.h,
        child: const Center(child: Text('No data available')),
      );
    }

    var featuredDeal = widget.homeData!.getFeaturedFlashDeal();
    if (featuredDeal == null && !widget.homeData!.isFlashDealInitial) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 5.h, 16.w, 15.h),
        child: SizedBox(
          height: 160.h,
          child: Row(
            children: [
              /// LEFT BANNER
              AspectRatio(
                aspectRatio: 1,
                child: GestureDetector(
                  onTap: () {
                    if (featuredDeal.slug != null) {
                      GoRouter.of(
                        context,
                      ).push("/flash-deal/${featuredDeal.slug}");
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: AIZImage.flashdeal(
                      featuredDeal!.banner,
                      6.r,
                      widget.homeData!,
                      context,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 10.w),
              Expanded(
                child: FutureBuilder<productMini.ProductMiniResponse>(
                  future: _productFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _flashDealLoadingShimmer();
                    }

                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        (snapshot.data?.products?.isEmpty ?? true)) {
                      return Center(
                        child: Text(
                          "No Items",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: MyTheme.font_grey,
                          ),
                        ),
                      );
                    }

                    var productList = snapshot.data!.products!;

                    return CarouselSlider(
                      options: CarouselOptions(
                        height: double.infinity,
                        viewportFraction: 0.5,
                        enableInfiniteScroll: productList.length > 1,
                        autoPlay: productList.length > 1,
                        padEnds: false,
                      ),
                      items: productList.map((product) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: GestureDetector(
                            onTap: () {
                              if (product.slug != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetails(slug: product.slug!),
                                  ),
                                );
                              }
                            },
                            child: _productContainer(product),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _flashDealLoadingShimmer() {
    return Row(
      children: [
        Expanded(child: _singleProductShimmer()),
        SizedBox(width: 8.w),
        Expanded(child: _singleProductShimmer()),
      ],
    );
  }

  Widget _singleProductShimmer() {
    return Container(
      height: 160.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(5.w),
              child: ShimmerHelper().buildBasicShimmer(radius: 5.r),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerHelper().buildBasicShimmer(
                    height: 12.h,
                    width: double.infinity,
                    radius: 4.r,
                  ),
                  SizedBox(height: 6.h),
                  ShimmerHelper().buildBasicShimmer(
                    height: 10.h,
                    width: 60.w,
                    radius: 4.r,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productContainer(productMini.Product product) {
    bool hasDiscount =
        product.discount != null &&
        product.discount!.isNotEmpty &&
        product.discount != "0";

    return Stack(
      children: [
        Container(
          height: 160.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 3,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 95.h,
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.all(5.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.r),
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/placeholder.png',
                      image: product.thumbnailImage ?? "",
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      imageErrorBuilder: (_, __, ___) {
                        return Image.asset(
                          'assets/placeholder.png',
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: MyTheme.font_grey,
                        fontSize: 9.sp,
                      ),
                    ),
                    Text(
                      product.mainPrice ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: MyTheme.accent_color,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (product.hasDiscount ?? false) ...[
                      SizedBox(height: 0.h),
                      Text(
                        product.strokedPrice ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.grey,
                          color: Colors.grey,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (hasDiscount)
          Positioned(
            top: 10.h,
            right: 5.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: MyTheme.accent_color,
                borderRadius: BorderRadius.circular(3.r),
              ),
              child: Text(
                product.discount ?? "",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
