import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/helpers/shimmer_helper.dart';
import 'package:ea24_mobile/helpers/system_config.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/repositories/product_repository.dart';

import 'package:ea24_mobile/data_model/wholesale_model.dart';
import 'package:ea24_mobile/screens/auction/auction_products_details.dart';
import 'package:ea24_mobile/screens/product/product_details/product_details.dart';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';

class WholesalesScreen extends StatefulWidget {
  const WholesalesScreen({super.key});

  @override
  State<WholesalesScreen> createState() => _WholesalesScreenState();
}

class _WholesalesScreenState extends State<WholesalesScreen> {
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.mainColor,
      appBar: buildAppBar(context),
      body: buildProductList(context),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.wholesale_products_ucf,
        style: TextStyle(
          fontSize: 16,
          color: MyTheme.dark_font_grey,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  Widget buildProductList(context) {
    return FutureBuilder<WholesaleProductModel>(
      // future: ApiService().fetchWholesaleProducts(),
      future: ProductRepository().getWholesaleProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ShimmerHelper().buildProductGridShimmer(
            scontroller: _scrollController,
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading products'));
          }

          final productResponse = snapshot.data;
          if (productResponse == null || productResponse.products.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.no_data_is_available),
            );
          }

          final products = productResponse.products.data;
          return SingleChildScrollView(
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              itemCount: products.length,
              shrinkWrap: true,
              padding: EdgeInsets.only(
                top: 20.0,
                bottom: 10,
                left: 18,
                right: 18,
              ),
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                var product = products[index];
                return WholeSalesProductCard(
                  id: product.id,
                  slug: product.slug,
                  image: product.thumbnailImage,
                  name: product.name,
                  mainPrice: product.basePrice.toString(),
                  strokedPrice: product.baseDiscountedPrice.toString(),
                  hasDiscount: product.discount != 0.0,
                  discount: product.discountPercentage,
                  isWholesale: true,
                );
              },
            ),
          );
        }

        // Default: still loading
        return ShimmerHelper().buildProductGridShimmer(
          scontroller: _scrollController,
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }
}

class WholeSalesProductCard extends StatefulWidget {
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

  const WholeSalesProductCard({
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
  });

  @override
  State<WholeSalesProductCard> createState() => _WholeSalesProductCardState();
}

class _WholeSalesProductCardState extends State<WholeSalesProductCard> {
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
                    if (whole_sale_addon_installed.$ && widget.isWholesale!)
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
                              ? widget.mainPrice?.replaceAll(
                                      SystemConfig.systemCurrency!.code!,
                                      SystemConfig.systemCurrency!.symbol!,
                                    ) ??
                                    ''
                              : widget.mainPrice ?? '',
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
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                        style: MyTheme.priceText(color: MyTheme.price_color)
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
