import 'package:active_ecommerce_cms_demo_app/screens/product/product_details/widget_for_product_details/product_gallery_viewer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../helpers/shimmer_helper.dart';
import '../../../../my_theme.dart';
import 'product_media.dart';

class ProductMediaSlider extends StatefulWidget {
  final List<ProductMedia> mediaList;
  final CarouselSliderController carouselController;
  final String price;
  final VoidCallback onPurchase;
  const ProductMediaSlider({
    super.key,
    required this.mediaList,
    required this.carouselController,
    required this.price,
    required this.onPurchase,
  });

  @override
  State<ProductMediaSlider> createState() => _ProductMediaSliderState();
}

class _ProductMediaSliderState extends State<ProductMediaSlider> {
  int _currentImage = 0;


  @override
  Widget build(BuildContext context) {
    if (widget.mediaList.isEmpty) {
      return ShimmerHelper().buildBasicShimmer(height: 355.0.h);
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          return CarouselSlider(
            carouselController: widget.carouselController,
            options: CarouselOptions(
              height: constraints.maxHeight,
              viewportFraction: 1,
              initialPage: 0,
              enableInfiniteScroll: widget.mediaList.length > 1,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 1000),
              autoPlayCurve: Curves.easeInExpo,
              enlargeCenterPage: false,
              scrollDirection: Axis.horizontal,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentImage = index;
                });
              },
            ),
            items: widget.mediaList.map((mediaItem) {
              return Builder(
                builder: (BuildContext context) {
                  Widget child;
                  if (mediaItem.type == 'image') {
                    child = InkWell(
                      onTap: () {
                        openProductGallery(context, _currentImage, widget.price,
                          widget.onPurchase,


                        );
                      },
                      child: SizedBox(
                        height: double.infinity,
                        width: double.infinity,
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/placeholder.png',
                          image: mediaItem.url,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  } else {
                    child = GestureDetector(
                      onTap: () {
                        if (mediaItem.type == 'hosted_video') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VideoScreen(videoUrl: mediaItem.url),
                            ),
                          );
                        } else if (mediaItem.type == 'youtube_video') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => YoutubePlayerScreen(
                                youtubeUrl: mediaItem.url,
                              ),
                            ),
                          );
                        }
                      },
                      child: _buildThumbnail(mediaItem),
                    );
                  }

                  return Stack(
                    children: <Widget>[
                      child,
                      Align(
                        alignment: const Alignment(0.0, 0.9),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.mediaList.length,
                                (index) => Container(
                              width: 8.0.w,
                              height: 8.0.h,
                              margin: EdgeInsets.symmetric(
                                vertical: 10.0.h,
                                horizontal: 4.0.w,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImage == index
                                    ? MyTheme.white
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }).toList(),
          );
        },
      );
    }
  }

  Widget _buildThumbnail(ProductMedia mediaItem) {
    return Container(
      color: MyTheme.light_grey,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          if (mediaItem.thumbnail != null && mediaItem.thumbnail!.isNotEmpty)
            FadeInImage.assetNetwork(
              placeholder: 'assets/placeholder.png',
              image: mediaItem.thumbnail!,
              fit: BoxFit.cover,
            )
          else if (mediaItem.type == 'hosted_video')
            Container(color: MyTheme.light_grey)
          else
            Container(color: MyTheme.light_grey),
          Center(
            child: Builder(
              builder: (context) {
                if (mediaItem.isShort) {
                  return Image.asset(
                    'assets/shorts_logo.png',
                    height: 50.h,
                    width: 50.w,
                  );
                } else if (mediaItem.type == 'youtube_video') {
                  return Image.asset(
                    'assets/youtube_logo.png',
                    height: 50.h,
                    width: 50.w,
                  );
                } else {
                  return Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 60.0.sp,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void openProductGallery(BuildContext context, int initialIndex,price,onPurchase) {
    final images = widget.mediaList
        .where((e) => e.type == 'image')
        .map((e) => e.url)
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ProductGalleryViewer(
          onPurchase: onPurchase,
          price: price,
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }



}

