import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../custom/lang_text.dart';
import '../../custom/toast_component.dart';
import '../../data_model/product_mini_response.dart';
import '../../helpers/shared_value_helper.dart';
import '../../helpers/shimmer_helper.dart';
import '../../my_theme.dart';
import '../../repositories/coupon_repository.dart';
import '../../ui_elements/product_card.dart';

class CouponProducts extends StatefulWidget {
  final String? code;
  final int? id;

  const CouponProducts({super.key, this.code, this.id});

  @override
  State<CouponProducts> createState() => _CouponProductsState();
}

class _CouponProductsState extends State<CouponProducts> {
  ScrollController? _scrollController;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: (app_language_rtl.$ ?? false)
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.mainColor,
        appBar: buildAppBar(context, widget.code),
        body: buildCouponProductList(context),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context, String? code) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(right: 18.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              code ?? 'No Code',
              style: TextStyle(
                fontSize: 16,
                color: MyTheme.dark_font_grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              onPressed: () {
                if (code != null) {
                  Clipboard.setData(ClipboardData(text: code)).then((_) {
                    if (!context.mounted) return;
                    ToastComponent.showDialog(
                      LangText(context).local.copied_ucf,
                    );
                  });
                }
              },
              icon: Icon(color: Colors.black, Icons.copy, size: 18.0),
            ),
          ],
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  buildCouponProductList(context) {
    return FutureBuilder(
      future: CouponRepository().getCouponProductList(id: widget.id),
      builder: (context, AsyncSnapshot<ProductMiniResponse> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("An error occurred"));
        } else if (snapshot.hasData) {
          var productResponse = snapshot.data;
          if (productResponse?.products == null ||
              productResponse!.products!.isEmpty) {
            return Center(child: Text("No products found"));
          }
          return SingleChildScrollView(
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              itemCount: productResponse.products!.length,
              shrinkWrap: true,
              padding: EdgeInsets.only(
                top: 20.0,
                bottom: 10,
                left: 18,
                right: 18,
              ),
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                var product = productResponse.products![index];
                return ProductCard(
                  id: product.id,
                  slug: product.slug ?? 'no-slug',
                  image: product.thumbnailImage,
                  name: product.name ?? 'Unnamed Product',
                  mainPrice: product.mainPrice ?? '0',
                  strokedPrice: product.strokedPrice,
                  hasDiscount: product.hasDiscount ?? false,
                  discount: product.discount,
                  isWholesale: product.isWholesale ?? false,
                );
              },
            ),
          );
        } else {
          return ShimmerHelper().buildProductGridShimmer(
            scontroller: _scrollController,
          );
        }
      },
    );
  }
}
