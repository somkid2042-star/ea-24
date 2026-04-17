import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../helpers/shimmer_helper.dart';
import '../../../my_theme.dart';
import 'package:photo_view/photo_view.dart';

// ignore: must_be_immutable
class ProductSliderImageWidget extends StatefulWidget {
  final List? productImageList;
  final CarouselSliderController? carouselController;
  int? currentImage;
  ProductSliderImageWidget({
    super.key,
    this.productImageList,
    this.carouselController,
    this.currentImage,
  });

  @override
  State<ProductSliderImageWidget> createState() =>
      _ProductSliderImageWidgetState();
}

class _ProductSliderImageWidgetState extends State<ProductSliderImageWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.productImageList!.isEmpty) {
      return ShimmerHelper().buildBasicShimmer(height: 190.0);
    } else {
      return CarouselSlider(
        carouselController: widget.carouselController,
        options: CarouselOptions(
          aspectRatio: 355 / 375,
          viewportFraction: 1,
          initialPage: 0,
          autoPlay: true,
          autoPlayInterval: Duration(seconds: 5),
          autoPlayAnimationDuration: Duration(milliseconds: 1000),
          autoPlayCurve: Curves.easeInExpo,
          enlargeCenterPage: false,
          scrollDirection: Axis.horizontal,
          onPageChanged: (index, reason) {
            setState(() {
              widget.currentImage = index;
            });
          },
        ),
        items: widget.productImageList!.map((i) {
          return Builder(
            builder: (BuildContext context) {
              return Stack(
                children: <Widget>[
                  InkWell(
                    onTap: () {
                      openPhotoDialog(
                        context,
                        widget.productImageList![widget.currentImage!],
                      );
                    },
                    child: SizedBox(
                      height: double.infinity,
                      width: double.infinity,
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder_rectangle.png',
                        image: i,
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment(0.0, 0.9),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.productImageList!.length,
                        (index) => Container(
                          width: 8.0,
                          height: 8.0,
                          margin: EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 4.0,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.currentImage == index
                                ? Colors.black.withValues(alpha: 0.5)
                                : Color(0xff484848).withValues(alpha: 0.5),
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
    }
  }

  openPhotoDialog(BuildContext context, path) => showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: Stack(
          children: [
            PhotoView(
              enableRotation: true,
              heroAttributes: const PhotoViewHeroAttributes(tag: "someTag"),
              imageProvider: NetworkImage(path),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Container(
                decoration: ShapeDecoration(
                  color: MyTheme.medium_grey_50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                      topRight: Radius.circular(25),
                      topLeft: Radius.circular(25),
                    ),
                  ),
                ),
                width: 40,
                height: 40,
                child: IconButton(
                  icon: Icon(Icons.clear, color: MyTheme.white),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
