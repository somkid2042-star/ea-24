
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_view/photo_view.dart';
import '../../../../my_theme.dart';

class ProductGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String price;
  final VoidCallback onPurchase;

  const ProductGalleryViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.price,
    required this.onPurchase,
  });

  @override
  State<ProductGalleryViewer> createState() => _ProductGalleryViewerState();
}

class _ProductGalleryViewerState extends State<ProductGalleryViewer> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [

            /// MAIN IMAGE VIEWER
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (_, index) {
                return PhotoView(
                  imageProvider: NetworkImage(widget.images[index]),
                  backgroundDecoration:
                  const BoxDecoration(color: Colors.black),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                );
              },
            ),

            /// TOP EMPTY AREA → TAP TO CLOSE
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.25, // top empty black area
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => Navigator.pop(context),
                child: const SizedBox(),
              ),
            ),

            /// TOP BAR (X + COUNTER)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_currentIndex + 1}/${widget.images.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  SizedBox(width: 8.w,)
                ],
              ),
            ),

            /// THUMBNAILS (CENTERED & SQUARE)
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 70,
                child: Center(
                  child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.images.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (_, index) {
                      final active = index == _currentIndex;

                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: active
                                  ? MyTheme.accent_color
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              widget.images[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            /// BOTTOM BAR (PRICE + PURCHASE)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:  0.92),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:  0.4),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),

              ),
            ),
          ],
        ),
      ),
    );
  }
}
