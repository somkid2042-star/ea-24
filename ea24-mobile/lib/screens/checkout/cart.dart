import 'package:ea24_mobile/custom/btn.dart';
import 'package:ea24_mobile/custom/text_styles.dart';
import 'package:ea24_mobile/custom/useful_elements.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/helpers/shimmer_helper.dart';
import 'package:ea24_mobile/helpers/system_config.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/presenter/cart_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../custom/cart_seller_item_list_widget.dart';
import '../../presenter/cart_provider.dart';

class Cart extends StatefulWidget {
  const Cart({
    super.key,
    this.hasBottomnav,
    this.fromNavigation = false,
    this.counter,
  });

  final bool? hasBottomnav;
  final bool fromNavigation;
  final CartCounter? counter;

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.reset();
      cartProvider.initState(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        return Directionality(
          textDirection: app_language_rtl.$!
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: const Color(0xffF2F1F6),
            appBar: buildAppBar(context),
            body: Stack(
              children: [
                RefreshIndicator(
                  color: MyTheme.accent_color,
                  backgroundColor: Colors.white,
                  onRefresh: () => cartProvider.onRefresh(context),
                  displacement: 0,
                  child: CustomScrollView(
                    controller: cartProvider.mainScrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      buildCartSellerList(cartProvider, context),

                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: widget.hasBottomnav! ? 200.h : 150.h,
                        ),
                      ),
                    ],
                  ),
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: buildBottomContainer(cartProvider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildBottomContainer(CartProvider cartProvider) {
    final bool canProceed =
        cartProvider.shopList.isNotEmpty && !cartProvider.isAnyItemOutOfStock;

    return Container(
      decoration: const BoxDecoration(color: Color(0xffF2F1F6)),

      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 40.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6.0.r),
                  color: MyTheme.soft_accent_color,
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Text(
                        AppLocalizations.of(context)!.total_amount_ucf,
                        style: TextStyle(
                          color: MyTheme.dark_font_grey,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        cartProvider.cartTotalString,
                        style: TextStyle(
                          color: MyTheme.accent_color,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              SizedBox(
                height: 50.h,
                width: double.infinity,
                child: Btn.basic(
                  color: canProceed ? MyTheme.accent_color : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0.r),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.proceed_to_shipping_ucf,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: canProceed
                      ? () => cartProvider.onPressProceedToShipping(context)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xffF2F1F6),
      leading: Builder(
        builder: (context) => widget.fromNavigation
            ? UsefulElements.backToMain(context, goBack: false)
            : UsefulElements.backButton(context),
      ),
      title: Text(
        AppLocalizations.of(context)!.shopping_cart_ucf,
        style: TextStyles.buildAppBarTexStyle(),
      ),
      elevation: 0.0,
    );
  }

  Widget buildCartSellerList(CartProvider cartProvider, BuildContext context) {
    if (cartProvider.isInitial && cartProvider.shopList.isEmpty) {
      // Show loading shimmer
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: ShimmerHelper().buildListShimmer(
            itemCount: 5,
            itemHeight: 100.0.h,
          ),
        ),
      );
    } else if (cartProvider.shopList.isNotEmpty) {
      // Show cart item list
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            var shopItem = cartProvider.shopList[index];

            // ignore: unnecessary_null_comparison
            if (shopItem == null || shopItem.cartItems.isEmpty) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: EdgeInsets.only(bottom: 10.0.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0.h),
                    child: Row(
                      children: [
                        Text(
                          shopItem.name,
                          style: TextStyle(
                            color: MyTheme.dark_font_grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          shopItem.subTotal.replaceAll(
                                SystemConfig.systemCurrency!.code,
                                SystemConfig.systemCurrency!.symbol,
                              ) ??
                              '',
                          style: TextStyle(
                            color: MyTheme.accent_color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Inner List Widget
                  MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    removeBottom: true,
                    child: CartSellerItemListWidget(
                      sellerIndex: index,
                      cartProvider: cartProvider,
                      context: context,
                    ),
                  ),
                ],
              ),
            );
          }, childCount: cartProvider.shopList.length),
        ),
      );
    } else if (!cartProvider.isInitial && cartProvider.shopList.isEmpty) {
      // Centralized empty cart message
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.cart_is_empty,
              style: TextStyle(color: MyTheme.font_grey, fontSize: 14.sp),
            ),
            SizedBox(height: 200.h),
          ],
        ),
      );
    } else {
      // Default loader
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }
  }
}
