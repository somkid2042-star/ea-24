import 'package:ea24_mobile/helpers/system_config.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/screens/product/product_details/product_details.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class TopSellingProductsCard extends StatefulWidget {
  int? id;
  String slug;
  String? image;
  String? name;
  String? mainPrice;
  String? strokedPrice;
  bool? hasDiscount;

  TopSellingProductsCard({
    super.key,
    this.id,
    required this.slug,
    this.image,
    this.name,
    this.mainPrice,
    this.strokedPrice,
    this.hasDiscount,
  });

  @override
  State<TopSellingProductsCard> createState() => _TopSellingProductsCardState();
}

class _TopSellingProductsCardState extends State<TopSellingProductsCard> {
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
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 90,
              height: 90,
              child: ClipRRect(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(6),
                  right: Radius.zero,
                ),
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/placeholder.png',
                  image: widget.image!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Flexible(
              child: Container(
                padding: EdgeInsets.only(
                  top: 14,
                  left: 14,
                  right: 34,
                  bottom: 14,
                ),
                //width: 240,
                height: 90,
                //color: Colors.red,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        color: Color(0xff6B7377),
                        fontFamily: 'Public Sans',
                        fontSize: 12,
                        height: 1.6,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Text(
                          SystemConfig.systemCurrency!.code != null
                              ? widget.mainPrice!.replaceAll(
                                  SystemConfig.systemCurrency!.code!,
                                  SystemConfig.systemCurrency!.symbol!,
                                )
                              : widget.mainPrice!,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          style: TextStyle(
                            color: MyTheme.price_color,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 18),
                        widget.hasDiscount!
                            ? Text(
                                SystemConfig.systemCurrency!.code != null
                                    ? widget.strokedPrice!.replaceAll(
                                        SystemConfig.systemCurrency!.code!,
                                        SystemConfig.systemCurrency!.symbol!,
                                      )
                                    : widget.strokedPrice!,
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  fontFamily: 'Public Sans',
                                  color: Color(0xffA8AFB3),
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              )
                            : Container(),
                      ],
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
