import 'dart:io';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:active_ecommerce_cms_demo_app/main.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/presenter/bottom_appbar_index.dart';
import 'package:active_ecommerce_cms_demo_app/presenter/cart_counter.dart';
import 'package:active_ecommerce_cms_demo_app/screens/auth/login.dart';
import 'package:active_ecommerce_cms_demo_app/screens/category_list_n_product/category_list.dart';
import 'package:active_ecommerce_cms_demo_app/screens/checkout/cart.dart';
import 'package:active_ecommerce_cms_demo_app/screens/home.dart';
import 'package:active_ecommerce_cms_demo_app/screens/profile.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class Main extends StatefulWidget {
  final bool goBack;
  const Main({super.key, this.goBack = true});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  int _currentIndex = 0;
  late final List<Widget> _children;
  final CartCounter counter = CartCounter();
  final BottomAppbarIndex bottomAppbarIndex = BottomAppbarIndex();

  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();

    _children = [
      const Home(),
      CategoryList(slug: "", isBaseCategory: true),
      Cart(hasBottomnav: true, fromNavigation: true, counter: counter),
      const Profile(),
    ];

    _fetchAll();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }

  void _fetchAll() {
    Provider.of<CartCounter>(context, listen: false).getCount();
  }

  void _onTapped(int index) {
    _fetchAll();
    if (!guest_checkout_status.$ && index == 2 && !is_logged_in.$) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
      return;
    }
    if (index == 3) {
      routes.push("/dashboard");
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop) return;

    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      _fetchAll();
      return;
    }

    if (_dialogShowing) return;

    _dialogShowing = true;

    final shouldExit =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => Directionality(
            textDirection: app_language_rtl.$!
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: AlertDialog(
              content: Text(
                AppLocalizations.of(context)!.do_you_want_close_the_app,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context)!.yes_ucf),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)!.no_ucf),
                ),
              ],
            ),
          ),
        ) ??
        false;

    _dialogShowing = false;

    if (shouldExit) {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else {
        exit(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Directionality(
        textDirection: app_language_rtl.$!
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Scaffold(
          extendBody: true,
          body: _children[_currentIndex],
          // --- FIX START: Wrapped in Container & SafeArea ---
          bottomNavigationBar: Container(
            // Background color for the safe area/chin
            color: Colors.white.withValues(alpha: 0.95),
            child: SafeArea(
              child: SizedBox(
                height: 70.h,
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: _currentIndex,
                  onTap: _onTapped,
                  // Transparent because container handles the background
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  unselectedItemColor: const Color.fromRGBO(168, 175, 179, 1),
                  selectedItemColor: MyTheme.accent_color,
                  selectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: MyTheme.accent_color,
                    fontSize: 12.sp,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: const Color.fromRGBO(168, 175, 179, 1),
                    fontSize: 12.sp,
                  ),
                  items: [
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Image.asset(
                          "assets/home.png",
                          height: 16.h,
                          color: _currentIndex == 0
                              ? MyTheme.accent_color
                              : const Color.fromRGBO(153, 153, 153, 1),
                        ),
                      ),
                      label: AppLocalizations.of(context)!.home_ucf,
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Image.asset(
                          "assets/categories.png",
                          height: 16.h,
                          color: _currentIndex == 1
                              ? MyTheme.accent_color
                              : const Color.fromRGBO(153, 153, 153, 1),
                        ),
                      ),
                      label: AppLocalizations.of(context)!.categories_ucf,
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: badges.Badge(
                          badgeStyle: badges.BadgeStyle(
                            shape: badges.BadgeShape.circle,
                            badgeColor: MyTheme.accent_color,
                            borderRadius: BorderRadius.circular(10.r),
                            padding: EdgeInsets.all(5.r),
                          ),
                          badgeAnimation: const badges.BadgeAnimation.slide(
                            toAnimate: false,
                          ),
                          badgeContent: Consumer<CartCounter>(
                            builder: (context, cart, child) {
                              return Text(
                                "${cart.cartCounter}",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                          child: Image.asset(
                            "assets/cart.png",
                            height: 16.h,
                            color: _currentIndex == 2
                                ? MyTheme.accent_color
                                : const Color.fromRGBO(153, 153, 153, 1),
                          ),
                        ),
                      ),
                      label: AppLocalizations.of(context)!.cart_ucf,
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Image.asset(
                          "assets/profile.png",
                          height: 16.h,
                          color: _currentIndex == 3
                              ? MyTheme.accent_color
                              : const Color.fromRGBO(153, 153, 153, 1),
                        ),
                      ),
                      label: AppLocalizations.of(context)!.profile_ucf,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // --- FIX END ---
        ),
      ),
    );
  }
}
