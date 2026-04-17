import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../app_config.dart';
import '../helpers/shimmer_helper.dart';
import '../my_theme.dart';
import '../presenter/home_presenter.dart';
import 'aiz_image.dart';

class HomeCarouselSlider extends StatelessWidget {
  final HomePresenter? homeData;
  final BuildContext? context;
  const HomeCarouselSlider({super.key, this.homeData, this.context});

  @override
  Widget build(BuildContext context) {
    if (homeData!.isCarouselInitial && homeData!.carouselImageList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: ShimmerHelper().buildBasicShimmer(height: 120),
      );
    } else if (homeData!.carouselImageList.isNotEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 0.5,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: CarouselSlider(
          options: CarouselOptions(
            aspectRatio: 338 / 140,
            viewportFraction: 1,
            initialPage: 0,
            enableInfiniteScroll: true,
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 5),
            autoPlayAnimationDuration: Duration(milliseconds: 1000),
            autoPlayCurve: Curves.easeInExpo,
            enlargeCenterPage: false,
            scrollDirection: Axis.horizontal,
            onPageChanged: (index, reason) {
              homeData!.incrementCurrentSlider(index);
            },
          ),
          items: homeData!.carouselImageList.map((i) {
            return Builder(
              builder: (BuildContext context) {
                return SizedBox(
                  width: double.infinity,
                  child: InkWell(
                    onTap: () {
                      var url = i.url?.split(AppConfig.DOMAIN_PATH).last ?? "";

                      GoRouter.of(context).go(url);
                    },
                    child: AIZImage.radiusImage(i.photo, 0),
                  ),
                );
              },
            );
          }).toList(),
        ),
      );
    } else if (!homeData!.isCarouselInitial &&
        homeData!.carouselImageList.isEmpty) {
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
