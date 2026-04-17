import 'package:ea24_mobile/custom/box_decorations.dart';
import 'package:ea24_mobile/helpers/system_config.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/screens/product/product_details/product_details.dart';
import 'package:flutter/material.dart';

class ListProductCard extends StatefulWidget {
  final int? id;
  final String slug;
  final String? image;
  final String? name;
  final String? mainPrice;
  final String? strokedPrice;
  final bool? hasDiscount;

  const ListProductCard({
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
  State<ListProductCard> createState() => _ListProductCardState();
}

class _ListProductCardState extends State<ListProductCard> {
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
        decoration: BoxDecorations.buildBoxDecoration_1(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 100,
              height: 100,
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
                  top: 10,
                  left: 12,
                  right: 12,
                  bottom: 14,
                ),
                height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        color: MyTheme.font_grey,
                        fontSize: 14,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(
                      child: Wrap(
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
                              color: MyTheme.accent_color,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
                                    color: MyTheme.medium_grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                )
                              : Container(),
                        ],
                      ),
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
