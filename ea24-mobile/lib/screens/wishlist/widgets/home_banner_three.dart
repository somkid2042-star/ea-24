import 'package:ea24_mobile/custom/aiz_image.dart';
import 'package:ea24_mobile/presenter/home_presenter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../app_config.dart';
import '../../../helpers/shimmer_helper.dart';
import '../../../my_theme.dart';

class HomeBannerThree extends StatelessWidget {
  final HomePresenter? homeData;
  final BuildContext? context;

  const HomeBannerThree({super.key, this.homeData, this.context});

  @override
  Widget build(BuildContext context) {
    if (homeData!.isBannerOneInitial && homeData!.bannerOneImageList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(
          left: 18.0,
          right: 18,
          top: 10,
          bottom: 20,
        ),
        child: ShimmerHelper().buildBasicShimmer(height: 120),
      );
    } else if (homeData!.bannerOneImageList.isNotEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              spreadRadius: 0.5,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: CarouselSlider(
          options: CarouselOptions(
            height: 156,
            aspectRatio: 1.1,
            viewportFraction: 0.43,
            initialPage: 0,
            padEnds: false,
            enableInfiniteScroll: true,
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 2),
            autoPlayAnimationDuration: Duration(milliseconds: 300),
            onPageChanged: (index, reason) {},
          ),
          items: homeData!.bannerOneImageList.map((i) {
            return Builder(
              builder: (BuildContext context) {
                return SizedBox(
                  width: 156,
                  height: 156,
                  child: InkWell(
                    onTap: () {
                      var url = i.url?.split(AppConfig.DOMAIN_PATH).last ?? "";
                      GoRouter.of(context).go(url);
                    },
                    child: AIZImage.radiusImage(i.photo, 6),
                  ),
                );
              },
            );
          }).toList(),
        ),
      );
    } else if (!homeData!.isBannerOneInitial &&
        homeData!.bannerOneImageList.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_carousel_image_found,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    } else {
      return Container(height: 100);
    }
  }
}
