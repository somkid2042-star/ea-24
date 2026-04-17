import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/screens/product/product_details/product_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MiniProductCard extends StatefulWidget {
  final int? id;
  final String slug;
  final String? image;
  final String? name;
  final String? mainPrice;
  final String? strokedPrice;
  final bool? hasDiscount;
  final bool? isWholesale;
  final dynamic discount;
  const MiniProductCard({
    super.key,
    this.id,
    required this.slug,
    this.image,
    this.name,
    this.mainPrice,
    this.strokedPrice,
    this.hasDiscount,
    this.isWholesale = false,
    this.discount,
  });

  @override
  State<MiniProductCard> createState() => _MiniProductCardState();
}

class _MiniProductCardState extends State<MiniProductCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return ProductDetails(slug: widget.slug);
            },
          ),
        );
      },
      child: SizedBox(
       // color: Colors.red,
        width: 135.w,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1,
                  child: SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: widget.image!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(8.w, 10.h, 8.w, 4.h),
                  child: Text(
                    widget.name!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: MyTheme.productNameStyle(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 0),
                  child: Text(
                    SystemConfig.systemCurrency != null
                        ? widget.mainPrice!.replaceAll(
                            SystemConfig.systemCurrency!.code!,
                            SystemConfig.systemCurrency!.symbol!,
                          )
                        : widget.mainPrice!,
                    maxLines: 1,
                    style: MyTheme.priceText(color: MyTheme.price_color),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
