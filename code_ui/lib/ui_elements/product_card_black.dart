import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/screens/auction/auction_products_details.dart';
import 'package:active_ecommerce_cms_demo_app/screens/product/product_details/product_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductCardBlack extends StatefulWidget {
  final dynamic identifier;
  final int? id;
  final String slug;
  final String? image;
  final String? name;
  final String? mainPrice;
  final String? strokedPrice;
  final bool hasDiscount;
  final bool? isWholesale;
  final String? discount;
  final double? rating;
  final int? ratingCount;
  final int? sales;

  const ProductCardBlack({
    super.key,
    this.identifier,
    required this.slug,
    this.id,
    this.image,
    this.name,
    this.mainPrice,
    this.strokedPrice,
    this.hasDiscount = false,
    this.isWholesale = false,
    this.discount,
    this.rating,
    this.ratingCount,
    this.sales,
  });

  @override
  State<ProductCardBlack> createState() => _ProductCardBlackState();
}

class _ProductCardBlackState extends State<ProductCardBlack> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return widget.identifier == 'auction'
                  ? AuctionProductsDetails(slug: widget.slug)
                  : ProductDetails(slug: widget.slug);
            },
          ),
        );
      },
      child: Stack(
        children: [
          Column(
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1,
                child: SizedBox(
                  width: double.infinity,
                  child: ClipRRect(
                    clipBehavior: Clip.hardEdge,
                    borderRadius: BorderRadius.circular(10.r),
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/placeholder.png',
                      image: widget.image ?? 'assets/placeholder.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 5.h, 16.w, 0),
                      child: Text(
                        widget.name ?? 'No Name',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: MyTheme.productNameStyle(),
                      ),
                    ),
                    if (widget.hasDiscount)
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 5.h, 16.w, 0),
                        child: Text(
                          SystemConfig.systemCurrency != null
                              ? widget.strokedPrice?.replaceAll(
                                      SystemConfig.systemCurrency!.code!,
                                      SystemConfig.systemCurrency!.symbol!,
                                    ) ??
                                    ''
                              : widget.strokedPrice ?? '',
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: MyTheme.medium_grey,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      )
                    else
                      SizedBox(height: 3.0.h),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 0.h),
                      child: Text(
                        SystemConfig.systemCurrency != null
                            ? widget.mainPrice?.replaceAll(
                                    SystemConfig.systemCurrency!.code!,
                                    SystemConfig.systemCurrency!.symbol!,
                                  ) ??
                                  ''
                            : widget.mainPrice ?? '',
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: MyTheme.priceText(color: MyTheme.price_color),
                      ),
                    ),
                    //ratting
                    if ((widget.rating ?? 0) > 0)
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 2.h),
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 14.sp, color: Colors.amber),
                            SizedBox(width: 4.w),
                            Text(
                              widget.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              "(${widget.ratingCount ?? 0})",
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey,
                              ),
                            ),
                            Spacer(),
                            //sold
                            Text(
                              " ${((widget.ratingCount ?? 0) > (widget.sales ?? 0) ? widget.ratingCount : widget.sales) ?? 0} Sold",
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.topRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.hasDiscount)
                    Container(
                      height: 20.h,
                      width: 48.w,
                      margin: EdgeInsets.only(
                        top: 8.h,
                        right: 8.w,
                        bottom: 15.h,
                      ),
                      decoration: BoxDecoration(
                        color: MyTheme.accent_color,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x14000000),
                            offset: Offset(-1, 1),
                            blurRadius: 1.r,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.discount ?? '',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          softWrap: false,
                        ),
                      ),
                    ),
                  if (whole_sale_addon_installed.$ && widget.isWholesale!)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(6.r),
                          bottomLeft: Radius.circular(6.r),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x14000000),
                            offset: Offset(-1, 1),
                            blurRadius: 1.r,
                          ),
                        ],
                      ),
                      child: Text(
                        "Wholesale",
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        softWrap: false,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
