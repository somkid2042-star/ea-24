import 'package:active_ecommerce_cms_demo_app/custom/box_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerHelper {
  Widget buildBasicShimmer({
    double height = double.infinity,
    double width = double.infinity,
    double radius = 6,
  }) {
    return Shimmer.fromColors(
      baseColor: MyTheme.shimmer_base,
      highlightColor: MyTheme.shimmer_highlighted,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecorations.buildBoxDecoration_1(radius: radius),
      ),
    );
  }

  Widget buildCircleShimmer({
    double height = double.infinity,
    double? width = double.infinity,
    BorderRadius radius = BorderRadius.zero,
    Color color = const Color.fromARGB(255, 224, 223, 223),
  }) {
    return Shimmer.fromColors(
      baseColor: color,
      highlightColor: MyTheme.shimmer_highlighted,
      child: SizedBox(
        width: height,
        height: width,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(MyTheme.shimmer_base),
          strokeWidth: 4.0,
          strokeCap: StrokeCap.round,
        ),
      ),
    );
  }

  Widget buildBasicShimmerCustomRadius({
    double height = double.infinity,
    double? width = double.infinity,
    BorderRadius radius = BorderRadius.zero,
    Color color = Colors.grey,
  }) {
    return Shimmer.fromColors(
      baseColor: color,
      highlightColor: MyTheme.shimmer_highlighted,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: MyTheme.shimmer_base,
        ),
      ),
    );
  }

  buildListShimmer({itemCount = 10, itemHeight = 100.0}) {
    return ListView.builder(
      itemCount: itemCount,
      scrollDirection: Axis.vertical,
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(
            top: 0.0,
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
          ),
          child: ShimmerHelper().buildBasicShimmer(height: itemHeight),
        );
      },
    );
  }

  buildProductGridShimmer({scontroller, itemCount = 10}) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      itemCount: itemCount,
      shrinkWrap: true,
      padding: EdgeInsets.only(top: 20.0, bottom: 10, left: 18, right: 18),
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: MyTheme.shimmer_base,
          highlightColor: MyTheme.shimmer_highlighted,
          child: Container(
            height: (index + 1) % 2 != 0 ? 250 : 300,
            width: double.infinity,
            decoration: BoxDecorations.buildBoxDecoration_1(),
          ),
        );
      },
    );
  }

  buildCategoryCardShimmer({isBaseCategory}) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1,
        crossAxisCount: 3,
      ),
      itemCount: 18,
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        bottom: isBaseCategory ? 30 : 0,
      ),
      scrollDirection: Axis.vertical,
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecorations.buildBoxDecoration_1(),
          child: ShimmerHelper().buildBasicShimmer(),
        );
      },
    );
  }

  buildSquareGridShimmer({scontroller, itemCount = 10}) {
    return GridView.builder(
      itemCount: itemCount,
      controller: scontroller,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      padding: EdgeInsets.all(8),
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Shimmer.fromColors(
            baseColor: MyTheme.shimmer_base,
            highlightColor: MyTheme.shimmer_highlighted,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecorations.buildBoxDecoration_1(),
            ),
          ),
        );
      },
    );
  }

  buildHorizontalGridShimmerWithAxisCount({
    itemCount = 10,
    int crossAxisCount = 2,
    crossAxisSpacing = 10.0,
    mainAxisSpacing = 10.0,
    mainAxisExtent = 100.0,
    controller,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      controller: controller,
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: 10,
        mainAxisExtent: mainAxisExtent,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: MyTheme.shimmer_base,
          highlightColor: MyTheme.shimmer_highlighted,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecorations.buildBoxDecoration_1(),
          ),
        );
      },
    );
  }

  buildSeparatedHorizontalListShimmer({
    double separationWidth = 16.0,
    int itemCount = 10,
    double itemHeight = 120,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      separatorBuilder: (context, index) => SizedBox(width: separationWidth),
      itemCount: itemCount,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: MyTheme.shimmer_base,
          highlightColor: MyTheme.shimmer_highlighted,
          child: Container(
            height: itemHeight,
            width: double.infinity,
            decoration: BoxDecorations.buildBoxDecoration_1(),
          ),
        );
      },
    );
  }
}
