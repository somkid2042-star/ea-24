import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/presenter/home_presenter.dart';
import 'package:active_ecommerce_cms_demo_app/screens/category_list_n_product/category_products.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../my_theme.dart';

class FeaturedCategoriesWidget extends StatelessWidget {
  final HomePresenter homeData;
  const FeaturedCategoriesWidget({super.key, required this.homeData});

  @override
  Widget build(BuildContext context) {
    if (homeData.isCategoryInitial && homeData.featuredCategoryList.isEmpty) {
      return ShimmerHelper().buildHorizontalGridShimmerWithAxisCount(
        crossAxisSpacing: 12.h,
        mainAxisSpacing: 12.w,
        itemCount: 10,
        mainAxisExtent: 160.w,
        controller: homeData.featuredCategoryScrollController,
      );
    } else if (homeData.featuredCategoryList.isNotEmpty) {
      return GridView.builder(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 11.h,
          bottom: 24.h,
        ),
        scrollDirection: Axis.horizontal,
        controller: homeData.featuredCategoryScrollController,
        itemCount: homeData.featuredCategoryList.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 12.h,
          mainAxisSpacing: 12.w,

          mainAxisExtent: 160.w,
        ),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return CategoryProducts(
                      slug: homeData.featuredCategoryList[index].slug??homeData.featuredCategoryList[index].id.toString(),
                    );
                  },
                ),
              );
            },
            child: Container(
              color: Colors.transparent,
              child: Row(
                children: [
                  // Image Section
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xff000000,
                            ).withValues(alpha: 0.1),
                            spreadRadius: 1,
                            blurRadius: 15,
                            offset: Offset(0, 6.h),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/placeholder.png',
                          image:
                              homeData.featuredCategoryList[index].coverImage!,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/placeholder.png',
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 10.w),

                  // Text Section
                  Expanded(
                    child: Text(
                      homeData.featuredCategoryList[index].name??'',
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: MyTheme.font_grey,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else if (!homeData.isCategoryInitial &&
        homeData.featuredCategoryList.isEmpty) {
      return SizedBox(
        height: 100.h,
        child: Center(
          child: Text(
            "No category found",
            style: TextStyle(color: MyTheme.font_grey, fontSize: 12.sp),
          ),
        ),
      );
    } else {
      return SizedBox(height: 100.h);
    }
  }
}
