import 'package:active_ecommerce_cms_demo_app/custom/useful_elements.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/wishlist_repository.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';

import 'widgets/wishlist_grid_view.dart';

class Wishlist extends StatefulWidget {
  const Wishlist({super.key});

  @override
  State<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  final ScrollController _mainScrollController = ScrollController();
  bool _wishlistInit = true;
  final List<dynamic> _wishlistItems = [];

  //init
  @override
  void initState() {
    if (is_logged_in.$ == true) {
      fetchWishlistItems();
    }
    super.initState();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  fetchWishlistItems() async {
    var wishlistResponse = await WishListRepository().getUserWishlist();
    _wishlistItems.addAll(wishlistResponse.wishlistItems);
    _wishlistInit = false;
    setState(() {});
  }

  reset() {
    _wishlistInit = true;
    _wishlistItems.clear();
    setState(() {});
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchWishlistItems();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.mainColor,
        appBar: buildAppBar(context),
        body: RefreshIndicator(
          color: MyTheme.accent_color,
          backgroundColor: Colors.white,
          onRefresh: _onPageRefresh,
          child: CustomScrollView(
            controller: _mainScrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverList(delegate: SliverChildListDelegate([buildWishlist()])),
            ],
          ),
        ),
      ),
    );
  }

  buildWishlist() {
    if (is_logged_in.$ == false) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.you_need_to_log_in,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    } else if (_wishlistInit == true && _wishlistItems.isEmpty) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildListShimmer(itemCount: 10),
      );
    } else if (_wishlistItems.isNotEmpty) {
      return WishListGridView(wishlistItems: _wishlistItems);
    } else {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_item_is_available,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    }
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: UsefulElements.backButton(context),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.my_wishlist_ucf,
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
}
