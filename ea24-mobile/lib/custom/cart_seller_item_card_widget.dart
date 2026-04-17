import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../helpers/system_config.dart';
import '../my_theme.dart';
import '../presenter/cart_provider.dart';
import 'box_decorations.dart';
import 'device_info.dart';

class CartSellerItemCardWidget extends StatelessWidget {
  final int sellerIndex;
  final int itemIndex;
  final CartProvider cartProvider;
  const CartSellerItemCardWidget({
    super.key,
    required this.cartProvider,
    required this.sellerIndex,
    required this.itemIndex,
  });

  @override
  Widget build(BuildContext context) {
    final cartItem = cartProvider.shopList[sellerIndex].cartItems[itemIndex];
    final bool isOutOfStock =
        (cartItem.digital ?? 0) == 0 && cartItem.stock == 0;
    final bool showQuantityControls =
        !isOutOfStock && (cartItem.digital ?? 0) != 1;

    return Container(
      height: 105.h,
      decoration: BoxDecoration(
        color: isOutOfStock ? Colors.grey.shade300 : Colors.white,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // 1. Image Section
          Padding(
            padding: .only(left: 1.5.w),
            child: SizedBox(
              width: DeviceInfo(context).width! / 4,
              height: 92.h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 4.w),
                    child: ClipRRect(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(6.r),
                        right: Radius.zero,
                      ),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: cartItem.productThumbnailImage!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  if (isOutOfStock)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(6.r),
                          right: Radius.zero,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Product Info Section
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cartItem.productName!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                      color: MyTheme.font_grey,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Row(
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${AppLocalizations.of(context)!.price_ucf}: ',
                                style: TextStyle(
                                  color: MyTheme.font_grey,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: SystemConfig.systemCurrency != null
                                    ? cartItem.price!.replaceAll(
                                        SystemConfig.systemCurrency!.code!,
                                        SystemConfig.systemCurrency!.symbol!,
                                      )
                                    : cartItem.price!,
                                style: TextStyle(
                                  color: MyTheme.accent_color,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // Tax/GST Info
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: gst_addon_installed.$ ? 'GST: ' : 'TAX: ',
                          style: TextStyle(
                            color: MyTheme.dark_grey,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: SystemConfig.systemCurrency != null
                              ? (gst_addon_installed.$
                                        ? cartItem.gst!
                                        : cartItem.tax!)
                                    .replaceAll(
                                      SystemConfig.systemCurrency!.code!,
                                      SystemConfig.systemCurrency!.symbol!,
                                    )
                              : (gst_addon_installed.$
                                    ? cartItem.gst!
                                    : cartItem.tax!),
                          style: TextStyle(
                            color: MyTheme.accent_color,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Delete Button Section
          Container(
            width: 32.w,
            margin: showQuantityControls ? null : EdgeInsets.only(right: 8.w),
            child: Column(
              mainAxisAlignment: showQuantityControls
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    cartProvider.onPressDelete(context, cartItem.id.toString());
                  },
                  child: Padding(
                    padding: showQuantityControls
                        ? EdgeInsets.only(bottom: 14.h)
                        : EdgeInsets.zero,
                    child: Image.asset(
                      'assets/trash.png',
                      height: 16.h,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Quantity Controls Section
          if (showQuantityControls)
            Padding(
              padding: EdgeInsets.all(14.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (cartItem.auctionProduct == 0) {
                        cartProvider.onQuantityIncrease(
                          context,
                          sellerIndex,
                          itemIndex,
                        );
                      }
                    },
                    child: Container(
                      width: 24.w,
                      height: 24.h,
                      decoration:
                          BoxDecorations.buildCartCircularButtonDecoration(),
                      child: Icon(
                        Icons.add,
                        color: cartItem.auctionProduct == 0
                            ? MyTheme.accent_color
                            : MyTheme.grey_153,
                        size: 12.sp,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
                    child: Text(
                      cartItem.quantity.toString(),
                      style: TextStyle(
                        color: MyTheme.accent_color,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (cartItem.auctionProduct == 0) {
                        cartProvider.onQuantityDecrease(
                          context,
                          sellerIndex,
                          itemIndex,
                        );
                      }
                    },
                    child: Container(
                      width: 24.w,
                      height: 24.h,
                      decoration:
                          BoxDecorations.buildCartCircularButtonDecoration(),
                      child: Icon(
                        Icons.remove,
                        color: cartItem.auctionProduct == 0
                            ? MyTheme.accent_color
                            : MyTheme.grey_153,
                        size: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
