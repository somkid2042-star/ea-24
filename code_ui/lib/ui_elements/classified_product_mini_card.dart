import 'package:active_ecommerce_cms_demo_app/custom/box_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/system_config.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/screens/classified_ads/classified_product_details.dart';
import 'package:flutter/material.dart';

class ClassifiedMiniProductCard extends StatefulWidget {
  final int? id;
  final String? image;
  final String slug;
  final String? name;
  final String? unitPrice;
  final dynamic condition;

  const ClassifiedMiniProductCard({
    super.key,
    this.id,
    required this.slug,
    this.image,
    this.name,
    this.unitPrice,
    this.condition,
  });

  @override
  State<ClassifiedMiniProductCard> createState() => _MiniProductCardState();
}

class _MiniProductCardState extends State<ClassifiedMiniProductCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return ClassifiedAdsDetails(slug: widget.slug);
            },
          ),
        );
      },
      child: Container(
        width: 135,
        decoration: BoxDecorations.buildBoxDecoration_1(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1.2,
                  child: SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      clipBehavior: Clip.hardEdge,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(6),
                        bottom: Radius.zero,
                      ),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: widget.image!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          widget.name!,
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
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          SystemConfig.systemCurrency!.code != null
                              ? widget.unitPrice!.replaceAll(
                                  SystemConfig.systemCurrency!.code!,
                                  SystemConfig.systemCurrency!.symbol!,
                                )
                              : widget.unitPrice!,
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: MyTheme.accent_color,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Visibility(
              visible: true,
              child: Positioned.fill(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.condition == "new"
                          ? Colors.green
                          : Colors.red,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(6.0),
                        bottomLeft: Radius.circular(6.0),
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
                      widget.condition ?? "",
                      style: TextStyle(
                        fontSize: 10,
                        color: const Color(0xffffffff),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
