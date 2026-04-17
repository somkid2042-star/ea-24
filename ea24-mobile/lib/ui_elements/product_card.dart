import 'package:ea24_mobile/helpers/system_config.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/screens/product/product_details/product_details.dart';
import 'package:flutter/material.dart';

import '../helpers/shared_value_helper.dart';
import '../screens/auction/auction_products_details.dart';

class ProductCard extends StatefulWidget {
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

  const ProductCard({
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
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
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
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ClipRRect(
                        clipBehavior: Clip.hardEdge,
                        borderRadius: BorderRadius.circular(10),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/placeholder.png',
                          image: widget.image ?? 'assets/placeholder.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    if ((whole_sale_addon_installed.$) &&
                        (widget.isWholesale ?? false))
                      Positioned(
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(6),
                              bottomLeft: Radius.circular(6),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0x14000000),
                                offset: Offset(-1, 1),
                                blurRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            "Wholesale",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.8,
                            ),
                            textHeightBehavior: TextHeightBehavior(
                              applyHeightToFirstAscent: false,
                            ),
                            softWrap: false,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        widget.name ?? 'No Name',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          color: MyTheme.font_grey,
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    if (widget.hasDiscount)
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      )
                    else
                      SizedBox(height: 8.0),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 2),
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

                    if (widget.rating != null && widget.rating! > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            SizedBox(width: 6),
                            Text(
                              widget.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: 8),
                            if (widget.ratingCount != null)
                              Text(
                                '(${widget.ratingCount})',
                                style: TextStyle(
                                  fontSize: 12,
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
                      height: 20,
                      width: 48,
                      margin: EdgeInsets.only(top: 8, right: 8, bottom: 15),
                      decoration: BoxDecoration(
                        color: MyTheme.accent_color,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x14000000),
                            offset: Offset(-1, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.discount ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.8,
                          ),
                          textHeightBehavior: TextHeightBehavior(
                            applyHeightToFirstAscent: false,
                          ),
                          softWrap: false,
                        ),
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
