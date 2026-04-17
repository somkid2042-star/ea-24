import 'dart:async';

import 'package:ea24_mobile/custom/aiz_route.dart';
import 'package:ea24_mobile/custom/box_decorations.dart';
import 'package:ea24_mobile/custom/device_info.dart';
import 'package:ea24_mobile/custom/lang_text.dart';
import 'package:ea24_mobile/custom/toast_component.dart';
import 'package:ea24_mobile/helpers/auth_helper.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/presenter/unRead_notification_counter.dart';
import 'package:ea24_mobile/repositories/profile_repository.dart';
import 'package:ea24_mobile/screens/address.dart';
import 'package:ea24_mobile/screens/auction/auction_products.dart';
import 'package:ea24_mobile/screens/blog_list_screen.dart';
import 'package:ea24_mobile/screens/classified_ads/classified_ads.dart';
import 'package:ea24_mobile/screens/classified_ads/my_classified_ads.dart';
import 'package:ea24_mobile/screens/coupon/coupons.dart';
import 'package:ea24_mobile/screens/digital_product/digital_products.dart';
import 'package:ea24_mobile/screens/filter.dart';
import 'package:ea24_mobile/screens/product/last_view_product.dart';
import 'package:ea24_mobile/screens/product/top_selling_products.dart';
import 'package:ea24_mobile/screens/refund_request.dart';
import 'package:ea24_mobile/screens/settings.dart';
import 'package:ea24_mobile/screens/wholesales_screen.dart';
import 'package:ea24_mobile/screens/wishlist/widgets/page_animation.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:one_context/one_context.dart';
import 'package:provider/provider.dart';
import 'package:route_transitions/route_transitions.dart';

import '../repositories/auth_repository.dart';
import 'auction/auction_bidded_products.dart';
import 'auction/auction_purchase_history.dart';
import 'change_language.dart';
import 'chat/messenger_list.dart';
import 'club_point.dart';
import 'currency_change.dart';
import 'digital_product/purchased_digital_produts.dart';

import 'followed_sellers.dart';
import 'notification/notification_list.dart';
import 'orders/order_list.dart';
import 'profile_edit.dart';
import 'uploads/upload_file.dart';
import 'wallet.dart';
import 'wishlist/wishlist.dart';

class Profile extends StatefulWidget {
  const Profile({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final ScrollController _mainScrollController = ScrollController();

  bool _auctionExpand = false;
  int? _cartCounter = 0;
  String _cartCounterString = "00";
  int? _wishlistCounter = 0;
  String _wishlistCounterString = "00";
  int? _orderCounter = 0;
  String _orderCounterString = "00";
  late BuildContext loadingcontext;

  @override
  void initState() {
    super.initState();

    if (is_logged_in.$ == true) {
      fetchAll();
    }
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  Future<bool> _showPermissionDialog(
    BuildContext context,
    String purpose,
  ) async {
    bool? userAgreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Permission Required"),
        content: Text(purpose, textAlign: TextAlign.center),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(context)!.deny_ucf),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text("Agree"),
          ),
        ],
      ),
    );
    return userAgreed ?? false;
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchAll();
  }

  onPopped(value) async {
    reset();
    fetchAll();
  }

  fetchAll() {
    fetchCounters();
    getNotificationCount();
  }

  getNotificationCount() async {
    Provider.of<UnReadNotificationCounter>(context, listen: false).getCount();
  }

  fetchCounters() async {
    var profileCountersResponse = await ProfileRepository()
        .getProfileCountersResponse();

    _cartCounter = profileCountersResponse.cartItemCount;
    _wishlistCounter = profileCountersResponse.wishlistItemCount;
    _orderCounter = profileCountersResponse.orderCount;

    _cartCounterString = counterText(_cartCounter.toString(), defaultLength: 2);
    _wishlistCounterString = counterText(
      _wishlistCounter.toString(),
      defaultLength: 2,
    );
    _orderCounterString = counterText(
      _orderCounter.toString(),
      defaultLength: 2,
    );

    setState(() {});
  }

  deleteAccountReq() async {
    loading();
    var response = await AuthRepository().getAccountDeleteResponse();
    if (!mounted) return;
    if (response.result) {
      AuthHelper().clearUserData();
      Navigator.pop(loadingcontext);
      context.go("/");
    }
    ToastComponent.showDialog(response.message);
  }

  String counterText(String txt, {int defaultLength = 3}) {
    var blankZeros = defaultLength == 3 ? "000" : "00";
    var leadingZeros = "";
    if (defaultLength == 3 && txt.length == 1) {
      leadingZeros = "00";
    } else if (defaultLength == 3 && txt.length == 2) {
      leadingZeros = "0";
    } else if (defaultLength == 2 && txt.length == 1) {
      leadingZeros = "0";
    }

    var newtxt = (txt == "" || txt == null.toString()) ? blankZeros : txt;

    if (defaultLength > txt.length) {
      newtxt = leadingZeros + newtxt;
    }

    return newtxt;
  }

  reset() {
    _cartCounter = 0;
    _cartCounterString = "00";
    _wishlistCounter = 0;
    _wishlistCounterString = "00";
    _orderCounter = 0;
    _orderCounterString = "00";
    setState(() {});
  }

  List<int> listItem = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  onTapLogout(BuildContext context) async {
    AuthHelper().clearUserData();
    context.go("/");
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: buildView(context),
    );
  }

  Widget buildView(context) {
    return Container(
      color: Colors.white,
      height: DeviceInfo(context).height,
      child: Stack(
        children: [
          Container(
            height: DeviceInfo(context).height! / 1.6,
            width: DeviceInfo(context).width,
            color: MyTheme.accent_color,
            alignment: Alignment.topRight,
            child: Image.asset("assets/background_1.png"),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: buildCustomAppBar(context),
            body: buildBody(),
          ),
        ],
      ),
    );
  }

  RefreshIndicator buildBody() {
    return RefreshIndicator(
      color: MyTheme.accent_color,
      backgroundColor: MyTheme.white,
      onRefresh: _onPageRefresh,
      displacement: 10,
      child: buildBodyChildren(),
    );
  }

  CustomScrollView buildBodyChildren() {
    return CustomScrollView(
      controller: _mainScrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: buildCountersRow(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: buildSettingAndAddonsHorizontalMenu(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: buildBottomVerticalCardList(),
            ),
          ]),
        ),
      ],
    );
  }

  PreferredSize buildCustomAppBar(context) {
    return PreferredSize(
      preferredSize: Size(DeviceInfo(context).width!, 80),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: EdgeInsets.only(right: 18),
                height: 30,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(Icons.close, color: MyTheme.white, size: 20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: buildAppbarSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomVerticalCardList() {
    return Container(
      margin: EdgeInsets.only(bottom: 120, top: 14),
      padding: EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecorations.buildBoxDecoration_1(),
      child: Column(
        children: [
          if (false)
            // ignore: dead_code
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildBottomVerticalCardListItem(
                  "assets/coupon.png",
                  LangText(context).local.coupons_ucf,
                  onPressed: () {},
                ),
                Divider(thickness: 1, color: MyTheme.light_grey),
                buildBottomVerticalCardListItem(
                  "assets/favoriteseller.png",
                  LangText(context).local.favorite_seller_ucf,
                  onPressed: () {},
                ),
                Divider(thickness: 1, color: MyTheme.light_grey),
              ],
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildBottomVerticalCardListItem(
                "assets/products.png",
                LangText(context).local.top_selling_products_ucf,
                onPressed: () {
                  AIZRoute.push(context, TopSellingProducts());
                },
              ),
              Divider(thickness: 1, color: MyTheme.light_grey),
            ],
          ),
          if (whole_sale_addon_installed.$)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildBottomVerticalCardListItem(
                  "assets/wholesale.png",
                  'Wholesale',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WholesalesScreen(),
                      ),
                    );
                  },
                ),
                Divider(thickness: 1, color: MyTheme.light_grey),
              ],
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildBottomVerticalCardListItem(
                "assets/blog.png",
                'Blog List',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BlogListScreen()),
                  );
                },
              ),
              Divider(thickness: 1, color: MyTheme.light_grey),
            ],
          ),
          buildBottomVerticalCardListItem(
            "assets/download.png",
            LangText(context).local.all_digital_products_ucf,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return DigitalProducts();
                  },
                ),
              );
            },
          ),

          Divider(thickness: 1, color: MyTheme.light_grey),
          if (is_logged_in.$)
          buildBottomVerticalCardListItem(
            "assets/coupon.png",
            LangText(context).local.coupons_ucf,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return Coupons();
                  },
                ),
              );
            },
          ),

          if (classified_product_status.$)
            Column(
              children: [
                buildBottomVerticalCardListItem(
                  "assets/my_clissified.png",
                  'My Classified Ads',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return MyClassifiedAds();
                        },
                      ),
                    );
                  },
                ),
                Divider(thickness: 1, color: MyTheme.light_grey),
              ],
            ),
          if (classified_product_status.$)
            Column(
              children: [
                buildBottomVerticalCardListItem(
                  "assets/classified_product.png",
                  'All Classified Ads',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return ClassifiedAds();
                        },
                      ),
                    );
                  },
                ),
                Divider(thickness: 1, color: MyTheme.light_grey),
              ],
            ),
          if (last_viewed_product_status.$ && is_logged_in.$)
            Column(
              children: [
                buildBottomVerticalCardListItem(
                  "assets/last_view_product.png",
                  LangText(context).local.last_view_product_ucf,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return LastViewProduct();
                        },
                      ),
                    );
                  },
                ),
                Divider(thickness: 1, color: MyTheme.light_grey),
              ],
            ),

          if (auction_addon_installed.$)
            Column(
              children: [
                Container(
                  height: _auctionExpand
                      ? is_logged_in.$
                            ? 140
                            : 77
                      : 40,
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 10.0),
                  child: InkWell(
                    onTap: () {
                      _auctionExpand = !_auctionExpand;
                      setState(() {});
                    },
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 24.0),
                                  child: Image.asset(
                                    "assets/auction.png",
                                    height: 16,
                                    width: 16,
                                    color: MyTheme.dark_font_grey,
                                  ),
                                ),
                                Text(
                                  LangText(context).local.auction_ucf,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: MyTheme.dark_font_grey,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _auctionExpand
                                  ? Icons.keyboard_arrow_down
                                  : Icons.navigate_next_rounded,
                              size: 20,
                              color: MyTheme.dark_font_grey,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Visibility(
                          visible: _auctionExpand,
                          child: Container(
                            padding: const EdgeInsets.only(left: 40),
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => OneContext().push(
                                    MaterialPageRoute(
                                      builder: (_) => AuctionProducts(),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '-',
                                        style: TextStyle(
                                          color: MyTheme.dark_font_grey,
                                        ),
                                      ),
                                      Text(
                                        " ${LangText(context).local.on_auction_products_ucf}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: MyTheme.dark_font_grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (is_logged_in.$)
                                  Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () => OneContext().push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AuctionBiddedProducts(),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              '-',
                                              style: TextStyle(
                                                color: MyTheme.dark_font_grey,
                                              ),
                                            ),
                                            Text(
                                              " ${LangText(context).local.bidded_products_ucf}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: MyTheme.dark_font_grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      GestureDetector(
                                        onTap: () => OneContext().push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AuctionPurchaseHistory(),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              '-',
                                              style: TextStyle(
                                                color: MyTheme.dark_font_grey,
                                              ),
                                            ),
                                            Text(
                                              " ${LangText(context).local.purchase_history_ucf}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: MyTheme.dark_font_grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(thickness: 1, color: MyTheme.light_grey),
              ],
            ),
          if (vendor_system.$)
            Column(
              children: [
                buildBottomVerticalCardListItem(
                  "assets/shop.png",
                  LangText(context).local.browse_all_sellers_ucf,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return Filter(selectedFilter: "sellers");
                        },
                      ),
                    );
                  },
                ),
                Divider(thickness: 1, color: MyTheme.light_grey),
              ],
            ),
          if (is_logged_in.$ && (vendor_system.$))
            Column(
              children: [
                buildBottomVerticalCardListItem(
                  "assets/follow_seller.png",
                  LangText(context).local.followed_sellers_ucf,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return FollowedSellers();
                        },
                      ),
                    );
                  },
                ),
                Divider(thickness: 1, color: MyTheme.light_grey),
              ],
            ),
        ],
      ),
    );
  }

  SizedBox buildBottomVerticalCardListItem(
    String img,
    String label, {
    Function()? onPressed,
    bool isDisable = false,
  }) {
    return SizedBox(
      height: 40,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: Image.asset(
                img,
                height: 16,
                width: 16,
                color: isDisable ? MyTheme.grey_153 : MyTheme.dark_font_grey,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDisable ? MyTheme.grey_153 : MyTheme.dark_font_grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHorizontalSettings() {
    return Container(
      margin: EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildHorizontalSettingItem(
            true,
            "assets/language.png",
            AppLocalizations.of(context)!.language_ucf,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return ChangeLanguage();
                  },
                ),
              );
            },
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return CurrencyChange();
                  },
                ),
              );
            },
            child: Column(
              children: [
                Image.asset(
                  "assets/currency.png",
                  height: 16,
                  width: 16,
                  color: MyTheme.white,
                ),
                SizedBox(height: 5),
                Text(
                  AppLocalizations.of(context)!.currency_ucf,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: MyTheme.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          buildHorizontalSettingItem(
            is_logged_in.$,
            "assets/edit.png",
            AppLocalizations.of(context)!.edit_profile_ucf,
            is_logged_in.$
                ? () {
                    AIZRoute.push(context, ProfileEdit()).then((value) {
                      //onPopped(value);
                    });
                  }
                : () => showLoginWarning(),
          ),
          buildHorizontalSettingItem(
            is_logged_in.$,
            "assets/location.png",
            AppLocalizations.of(context)!.address_ucf,
            is_logged_in.$
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return Address();
                        },
                      ),
                    );
                  }
                : () => showLoginWarning(),
          ),
        ],
      ),
    );
  }

  InkWell buildHorizontalSettingItem(
    bool isLogin,
    String img,
    String text,
    Function() onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Image.asset(
            img,
            height: 16,
            width: 16,
            color: isLogin ? MyTheme.white : MyTheme.blue_grey,
          ),
          SizedBox(height: 5),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isLogin ? MyTheme.white : MyTheme.blue_grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  showLoginWarning() {
    return ToastComponent.showDialog(
      AppLocalizations.of(context)!.you_need_to_log_in,
    );
  }

  deleteWarningDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          LangText(context).local.delete_account_warning_title,
          style: TextStyle(fontSize: 15, color: MyTheme.dark_font_grey),
        ),
        content: Text(
          LangText(context).local.delete_account_warning_description,
          style: TextStyle(fontSize: 13, color: MyTheme.dark_font_grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              pop(context);
            },
            child: Text(LangText(context).local.no_ucf),
          ),
          TextButton(
            onPressed: () {
              pop(context);
              deleteAccountReq();
            },
            child: Text(LangText(context).local.yes_ucf),
          ),
        ],
      ),
    );
  }

  Widget buildSettingAndAddonsHorizontalMenu() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      margin: EdgeInsets.only(top: 14),
      width: DeviceInfo(context).width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),

      child: LayoutBuilder(
        builder: (context, constraints) {
          const int crossAxisCount = 3;
          const double mainAxisSpacing = 0.0;
          const double crossAxisSpacing = 0.0;

          const double childAspectRatio = 1.4;

          double itemWidth =
              (constraints.maxWidth -
                  (crossAxisSpacing * (crossAxisCount - 1))) /
              crossAxisCount;

          double itemHeight = itemWidth / childAspectRatio;

          final List<Widget> children = [
            if (wallet_system_status.$)
              Container(
                child: buildSettingAndAddonsHorizontalMenuItem(
                  "assets/wallet.png",
                  AppLocalizations.of(context)!.my_wallet_ucf,
                  () {
                    Navigator.push(context, PageAnimation.fadeRoute(Wallet()));
                  },
                ),
              ),
            Container(
              child: buildSettingAndAddonsHorizontalMenuItem(
                "assets/orders.png",
                AppLocalizations.of(context)!.orders_ucf,
                is_logged_in.$
                    ? () {
                        Navigator.push(
                          context,
                          PageAnimation.fadeRoute(OrderList()),
                        );
                      }
                    : () => null,
              ),
            ),
            Container(
              child: buildSettingAndAddonsHorizontalMenuItem(
                "assets/heart.png",
                AppLocalizations.of(context)!.my_wishlist_ucf,
                is_logged_in.$
                    ? () {
                        Navigator.push(
                          context,
                          PageAnimation.fadeRoute(Wishlist()),
                        );
                      }
                    : () => null,
              ),
            ),
            if (club_point_addon_installed.$)
              Container(
                child: buildSettingAndAddonsHorizontalMenuItem(
                  "assets/points.png",
                  AppLocalizations.of(context)!.club_point_ucf,
                  is_logged_in.$
                      ? () {
                          Navigator.push(
                            context,
                            PageAnimation.fadeRoute(Clubpoint()),
                          );
                        }
                      : () => null,
                ),
              ),
            badges.Badge(
              position: badges.BadgePosition.topEnd(top: 8, end: 20),
              badgeStyle: badges.BadgeStyle(
                shape: badges.BadgeShape.circle,
                badgeColor: MyTheme.accent_color,
                borderRadius: BorderRadius.circular(10),
                padding: EdgeInsets.all(5),
              ),
              badgeContent: Consumer<UnReadNotificationCounter>(
                builder: (context, notification, child) {
                  return Text(
                    "${notification.unReadNotificationCounter}",
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  );
                },
              ),
              child: buildSettingAndAddonsHorizontalMenuItem(
                "assets/notification.png",
                "Notifications",
                is_logged_in.$
                    ? () {
                        Navigator.push(
                          context,
                          PageAnimation.fadeRoute(NotificationList()),
                        ).then((value) {
                          onPopped(value);
                        });
                      }
                    : () => null,
              ),
            ),
            if (refund_addon_installed.$)
              Container(
                child: buildSettingAndAddonsHorizontalMenuItem(
                  "assets/refund.png",
                  AppLocalizations.of(context)!.refund_requests_ucf,
                  is_logged_in.$
                      ? () {
                          Navigator.push(
                            context,
                            PageAnimation.fadeRoute(RefundRequest()),
                          );
                        }
                      : () => null,
                ),
              ),
            if (conversation_system_status.$)
              Container(
                child: buildSettingAndAddonsHorizontalMenuItem(
                  "assets/messages.png",
                  AppLocalizations.of(context)!.messages_ucf,
                  is_logged_in.$
                      ? () {
                          Navigator.push(
                            context,
                            PageAnimation.fadeRoute(MessengerList()),
                          );
                        }
                      : () => null,
                ),
              ),

            Container(
              child: buildSettingAndAddonsHorizontalMenuItem(
                "assets/download.png",
                AppLocalizations.of(context)!.downloads_ucf,
                is_logged_in.$
                    ? () {
                        Navigator.push(
                          context,
                          PageAnimation.fadeRoute(PurchasedDigitalProducts()),
                        );
                      }
                    : () => null,
              ),
            ),
            Container(
              child: buildSettingAndAddonsHorizontalMenuItem(
                "assets/upload.png",
                "Upload file",
                is_logged_in.$
                    ? () async {
                        String purpose =
                            "To upload files, the app needs access to your device's storage.";
                        bool userAgreed = await _showPermissionDialog(
                          context,
                          purpose,
                        );
                        if (!context.mounted) return;
                        if (userAgreed) {
                          Navigator.push(
                            context,
                            PageAnimation.fadeRoute(UploadFile()),
                          );
                        } else {
                          ToastComponent.showDialog(
                            "Permission is required to upload files.",
                          );
                        }
                      }
                    : () => null,
              ),
            ),
          ];

          return Wrap(
            spacing: crossAxisSpacing,
            runSpacing: mainAxisSpacing,
            children: children.map((item) {
              return SizedBox(
                width: itemWidth,
                height: itemHeight,

                child: Center(child: item),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Container buildSettingAndAddonsHorizontalMenuItem(
    String img,
    String text,
    Function() onTap,
  ) {
    return Container(
      alignment: Alignment.center,
      child: InkWell(
        onTap: is_logged_in.$
            ? onTap
            : () {
                showLoginWarning();
              },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              img,
              width: 16,
              height: 16,
              color: is_logged_in.$
                  ? MyTheme.dark_font_grey
                  : MyTheme.medium_grey_50,
            ),
            SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: is_logged_in.$
                    ? MyTheme.dark_font_grey
                    : MyTheme.medium_grey_50,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCountersRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buildCountersRowItem(
          _cartCounterString,
          AppLocalizations.of(context)!.in_your_cart_all_lower,
        ),
        buildCountersRowItem(
          _wishlistCounterString,
          AppLocalizations.of(context)!.in_your_wishlist_all_lower,
        ),
        buildCountersRowItem(
          _orderCounterString,
          AppLocalizations.of(context)!.your_ordered_all_lower,
        ),
      ],
    );
  }

  Widget buildCountersRowItem(String counter, String title) {
    return Container(
      margin: EdgeInsets.only(top: 20),
      padding: EdgeInsets.symmetric(vertical: 14),
      width: DeviceInfo(context).width! / 3.5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: MyTheme.white,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            counter,
            maxLines: 2,
            style: TextStyle(
              fontSize: 18,
              color: MyTheme.dark_font_grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(title, maxLines: 2, style: TextStyle(color: Color(0xff3E4447))),
        ],
      ),
    );
  }

  Widget buildAppbarSection() {
    return Container(
      alignment: Alignment.center,
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: MyTheme.white, width: 1),
              ),
              child: is_logged_in.$
                  ? ClipRRect(
                      clipBehavior: Clip.hardEdge,
                      borderRadius: BorderRadius.all(Radius.circular(100.0)),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: "${avatar_original.$}",
                        fit: BoxFit.fill,
                      ),
                    )
                  : Image.asset(
                      'assets/profile_placeholder.png',
                      height: 48,
                      width: 48,
                      fit: BoxFit.fitHeight,
                    ),
            ),
          ),
          buildUserInfo(),
          Spacer(),
          GestureDetector(
            child: Icon(
              is_logged_in.$ ? Icons.logout : Icons.login,
              color: Colors.white,
              size: 25,
            ),
            onTap: () {
              final BuildContext profileContext = context;

              if (is_logged_in.$) {
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      title: Text("Logout"),
                      content: Text("Are you sure you want to logout?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            AuthHelper().clearUserData();
                            Navigator.of(dialogContext).pop();

                            profileContext.go("/");
                          },
                          child: Text("OK"),
                        ),
                      ],
                    );
                  },
                );
              } else {
                profileContext.push("/users/login");
              }
            },
          ),
          is_logged_in.$
              ? IconButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (context) => Settings()));
                  },
                  icon: Icon(Icons.settings, color: Colors.white),
                )
              : SizedBox(),
        ],
      ),
    );
  }

  Widget buildUserInfo() {
    return is_logged_in.$
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${user_name.$}",
                style: TextStyle(
                  fontSize: 14,
                  color: MyTheme.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  user_email.$ != ""
                      ? user_email.$
                      : user_phone.$ != ""
                      ? user_phone.$
                      : '',
                  style: TextStyle(color: MyTheme.light_grey),
                ),
              ),
            ],
          )
        : Text(
            LangText(context).local.login_or_reg,
            style: TextStyle(
              fontSize: 14,
              color: MyTheme.white,
              fontWeight: FontWeight.bold,
            ),
          );
  }

  loading() {
    showDialog(
      context: context,
      builder: (context) {
        loadingcontext = context;
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text(AppLocalizations.of(context)!.please_wait_ucf),
            ],
          ),
        );
      },
    );
  }
}
