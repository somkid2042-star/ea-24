import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../helpers/shimmer_helper.dart';
import '../my_theme.dart';
import '../presenter/home_presenter.dart';

class HomeBannerTwo extends StatelessWidget {
  final HomePresenter? homeData;
  final BuildContext? context;

  const HomeBannerTwo({super.key, this.homeData, this.context});

  @override
  Widget build(BuildContext context) {
    if (homeData!.isBannerTwoInitial && homeData!.bannerTwoImageList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(
          left: 18.0,
          right: 18,
          top: 10,
          bottom: 20,
        ),
        child: ShimmerHelper().buildBasicShimmer(height: 120),
      );
    } else if (homeData!.bannerTwoImageList.isNotEmpty) {
      return CarouselSlider(
        options: CarouselOptions(
          height: 196,
          aspectRatio: 1.1,
          viewportFraction: .43,
          initialPage: 0,
          padEnds: false,
          enableInfiniteScroll: true,
          autoPlay: true,
          onPageChanged: (index, reason) {},
        ),
        items: homeData!.bannerTwoImageList.map((i) {
          return Builder(
            builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 0,
                  top: 16,
                  bottom: 24,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xff000000).withValues(alpha: 0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () {
                        var url =
                            i.url?.split(AppConfig.DOMAIN_PATH).last ?? "";
                        GoRouter.of(context).go(url);
                      },

                      child: Image.asset('assets/placeholder.png'),
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      );
    } else if (!homeData!.isBannerTwoInitial &&
        homeData!.bannerTwoImageList.isEmpty) {
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
