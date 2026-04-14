import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifier/navigation_notifier.dart';
import '../notifier/theme_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/cookie_fetcher_screen.dart';
import '../screens/dummy_screens.dart';
import '../utils/app_style.dart';
import '../utils/color_utils.dart';
import '../utils/app_images.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;

  final tab = [
    const DashboardScreen(), // Use EA24 Dashboard as Home
    const CookieFetcherScreen(),
    const ProductScreen(),
    const CommunityScreen(),
    const ScheduleScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Consumer<NavigationNotifier>(
          builder: (context, provider, child) {
            return Scaffold(
              body: Stack(
                children: [
                  AnimatedContainer(
                    color: ColorUtils.getCardColor(context),
                    duration: const Duration(seconds: 1),
                    child: tab[provider.index],
                  ),
                  if (provider.index == 0) ...[
                    Positioned(
                      bottom: 30,
                      right: 25,
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, 23 * _animation.value),
                                child: Visibility(
                                  visible: _isExpanded,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    alignment: Alignment.center,
                                    child: _CircularButton(
                                      height: 53,
                                      width: 53,
                                      color: Styles.primaryColor,
                                      onClick: _isExpanded ? () => _toggleExpand() : null,
                                      image: ic_mental,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, 10 * _animation.value),
                                child: Visibility(
                                  visible: _isExpanded,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    alignment: Alignment.center,
                                    child: _CircularButton(
                                      height: 53,
                                      width: 53,
                                      color: Styles.primaryColor,
                                      onClick: _isExpanded ? () => _toggleExpand() : null,
                                      image: ic_support,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, -5 * _animation.value),
                                child: Visibility(
                                  visible: _isExpanded,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    alignment: Alignment.center,
                                    child: _CircularButton(
                                      height: 53,
                                      width: 53,
                                      color: Styles.primaryColor,
                                      onClick: _isExpanded ? () => _toggleExpand() : null,
                                      image: ic_bot, // Using mightyfitness icon
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          _CircularButton(
                            height: 60,
                            width: 60,
                            onClick: _toggleExpand,
                            color: Styles.primaryColor,
                            icon: Icon(_isExpanded ? Icons.close : Icons.menu, color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  ],
                ],
              ),
              bottomNavigationBar: SafeArea(
                bottom: Platform.isAndroid ? true : false,
                left: false,
                right: false,
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  showUnselectedLabels: true,
                  showSelectedLabels: true,
                  enableFeedback: false,
                  selectedLabelStyle: Styles.textStyle.copyWith(fontSize: 12),
                  unselectedLabelStyle: Styles.textStyle.copyWith(fontSize: 11),
                  backgroundColor: ColorUtils.getCardColor(context),
                  currentIndex: provider.index,
                  unselectedItemColor: Colors.grey,
                  selectedItemColor: Styles.primaryColor,
                  onTap: (index) {
                    if (_isExpanded) {
                      _isExpanded = false;
                    }
                    provider.setIndex(index);
                  },
                  items: [
                    BottomNavigationBarItem(
                      tooltip: 'Home',
                      icon: Image.asset(ic_home_outline, color: Colors.grey, height: 24),
                      activeIcon: Image.asset(ic_home_fill, color: Styles.primaryColor, height: 24),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      tooltip: 'เครื่องมือ',
                      icon: const Icon(Icons.apps_rounded, color: Colors.grey, size: 24),
                      activeIcon: Icon(Icons.apps_rounded, color: Styles.primaryColor, size: 24),
                      label: 'เครื่องมือ',
                    ),
                    BottomNavigationBarItem(
                      tooltip: 'Shop',
                      icon: Image.asset(ic_store_outline, color: Colors.grey, height: 24),
                      activeIcon: Image.asset(ic_store_fill, color: Styles.primaryColor, height: 24),
                      label: 'Shop',
                    ),
                    BottomNavigationBarItem(
                      tooltip: 'Community',
                      icon: Image.asset(ic_community2, color: Colors.grey, height: 22),
                      activeIcon: Image.asset(ic_community_filled, color: Styles.primaryColor, height: 24),
                      label: 'Community',
                    ),
                    BottomNavigationBarItem(
                      tooltip: 'Schedule',
                      icon: Image.asset(ic_schedule, color: Colors.grey, height: 22),
                      activeIcon: Image.asset(ic_fill_schedule, color: Styles.primaryColor, height: 24),
                      label: 'Schedule',
                    ),
                    BottomNavigationBarItem(
                      tooltip: 'Profile',
                      icon: Image.asset(ic_user, color: Colors.grey, height: 24),
                      activeIcon: Image.asset(ic_user_fill_icon, color: Styles.primaryColor, height: 24),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CircularButton extends StatelessWidget {
  final double height;
  final double width;
  final Color color;
  final Widget? icon;
  final String? image;
  final VoidCallback? onClick;

  const _CircularButton({
    required this.height,
    required this.width,
    required this.color,
    this.icon,
    this.image,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: image != null
            ? Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(image!, color: Colors.white),
              )
            : (icon ?? const SizedBox.shrink()),
      ),
    );
  }
}
