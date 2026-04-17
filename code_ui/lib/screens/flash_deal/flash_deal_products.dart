import 'package:active_ecommerce_cms_demo_app/custom/box_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/custom/device_info.dart';
import 'package:active_ecommerce_cms_demo_app/custom/useful_elements.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/flash_deal_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/product_mini_response.dart'
    // ignore: library_prefixes
    as productMini;
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/string_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/flash_deal_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/product_repository.dart';

import 'package:active_ecommerce_cms_demo_app/ui_elements/product_card_black.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class FlashDealProducts extends StatefulWidget {
  final String? slug;
  const FlashDealProducts({super.key, required this.slug});
  @override
  State<FlashDealProducts> createState() => _FlashDealProductsState();
}

class _FlashDealProductsState extends State<FlashDealProducts> {
  CountdownTimerController? countdownTimerController;
  Future<productMini.ProductMiniResponse>? _future;

  late List<productMini.Product> _searchList;
  late List<productMini.Product> _fullList;
  ScrollController? _scrollController;

  FlashDealResponseDatum? flashDealInfo;

  String timeText(String txt, {defaultLength = 3}) {
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

  getInfo() async {
    var res = await FlashDealRepository().getFlashDealInfo(widget.slug);

    if (res.flashDeals?.isNotEmpty ?? false) {
      flashDealInfo = res.flashDeals?.first;

      DateTime end = convertTimeStampToDateTime(
        flashDealInfo!.date!,
      ); // YYYY-mm-dd
      DateTime now = DateTime.now();
      int diff = end.difference(now).inMilliseconds;
      int endTime = diff + now.millisecondsSinceEpoch;

      void onEnd() {}

      countdownTimerController = CountdownTimerController(
        endTime: endTime,
        onEnd: onEnd,
      );
    }
    setState(() {});
  }

  DateTime convertTimeStampToDateTime(int timeStamp) {
    var dateToTimeStamp = DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000);
    return dateToTimeStamp;
  }

  @override
  void initState() {
    getInfo();
    _future = ProductRepository().getFlashDealProducts(widget.slug);
    _searchList = [];
    _fullList = [];
    super.initState();
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
        body: buildProductList(context),
      ),
    );
  }

  bool? shouldProductBoxBeVisible(productName, searchKey) {
    if (searchKey == "") {
      return true;
    }
    return StringHelper().stringContains(productName, searchKey);
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      toolbarHeight: 50,
      leading: Builder(
        builder: (context) => IconButton(
          icon: UsefulElements.backButton(context),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: flashDealInfo != null
          ? Text(
              '${flashDealInfo!.title}',
              style: TextStyle(
                color: Color(0xff3E4447),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )
          : Text('Loading.....'),
      elevation: 0.0,
      titleSpacing: 0,
      scrolledUnderElevation: 0.0,
    );
  }

  buildProductList(context) {
    return FutureBuilder(
      future: _future,
      builder:
          (context, AsyncSnapshot<productMini.ProductMiniResponse> snapshot) {
            if (snapshot.hasError) {
              return Container();
            } else if (snapshot.hasData) {
              var productResponse = snapshot.data;
              if (_fullList.isEmpty) {
                _fullList.addAll(productResponse!.products!);
                _searchList.addAll(productResponse.products!);
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    buildFlashDealsBanner(context),
                    MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      itemCount: _searchList.length,
                      shrinkWrap: true,
                      padding: EdgeInsets.only(
                        top: 16.0,
                        bottom: 10,
                        left: 18,
                        right: 18,
                      ),
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        // 3
                        return ProductCardBlack(
                          id: _searchList[index].id,
                          slug: _searchList[index].slug!,
                          image: _searchList[index].thumbnailImage,
                          name: _searchList[index].name,
                          mainPrice: _searchList[index].mainPrice,
                          strokedPrice: _searchList[index].strokedPrice,
                          hasDiscount: _searchList[index].hasDiscount!,
                          discount: _searchList[index].discount,
                          isWholesale: _searchList[index].isWholesale,
                        );
                      },
                    ),
                  ],
                ),
              );
            } else {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    headerShimmer(),
                    ShimmerHelper().buildProductGridShimmer(
                      scontroller: _scrollController,
                    ),
                  ],
                ),
              );
            }
          },
    );
  }

  SizedBox buildFlashDealsBanner(BuildContext context) {
    return SizedBox(
      height: 215,
      child: CountdownTimer(
        controller: countdownTimerController,
        widgetBuilder: (_, CurrentRemainingTime? time) {
          return Stack(
            children: [
              buildFlashDealBanner(),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  width: DeviceInfo(context).width,
                  margin: EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: time == null
                            ? Text(
                                AppLocalizations.of(context)!.ended_ucf,
                                style: TextStyle(
                                  color: MyTheme.accent_color,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : buildTimerRow(time),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  headerShimmer() {
    return SizedBox(
      // color: MyTheme.amber,
      height: 215,
      child: Stack(
        children: [
          buildFlashDealBannerShimmer(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              width: DeviceInfo(context).width,
              margin: EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecorations.buildBoxDecoration_1(),
              child: Container(child: buildTimerRowRowShimmer()),
            ),
          ),
        ],
      ),
    );
  }

  SizedBox buildFlashDealBanner() {
    return SizedBox(
      child: FadeInImage.assetNetwork(
        placeholder: 'assets/placeholder_rectangle.png',
        image: flashDealInfo?.banner ?? "",
        fit: BoxFit.cover,
        width: DeviceInfo(context).width,
        height: 180,
      ),
    );
  }

  Widget buildFlashDealBannerShimmer() {
    return ShimmerHelper().buildBasicShimmerCustomRadius(
      width: DeviceInfo(context).width,
      height: 180,
      color: MyTheme.medium_grey_50,
    );
  }

  Widget buildTimerRow(CurrentRemainingTime time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 5),
          Column(
            children: [
              timerCircularContainer(
                time.days ?? 0,
                365,
                timeText((time.days ?? 0).toString(), defaultLength: 3),
              ),
              SizedBox(height: 5),
              Text('Days', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          SizedBox(width: 10),
          Column(
            children: [
              timerCircularContainer(
                time.hours ?? 0,
                24,
                timeText((time.hours ?? 0).toString(), defaultLength: 2),
              ),
              SizedBox(height: 5),
              Text('Hours', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          SizedBox(width: 10),
          Column(
            children: [
              timerCircularContainer(
                time.min ?? 0,
                60,
                timeText((time.min ?? 0).toString(), defaultLength: 2),
              ),
              SizedBox(height: 5),
              Text(
                'Minutes',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          SizedBox(width: 10),
          Column(
            children: [
              timerCircularContainer(
                time.sec ?? 0,
                60,
                timeText((time.sec ?? 0).toString(), defaultLength: 2),
              ),
              SizedBox(height: 5),
              Text(
                'Seconds',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          SizedBox(width: 10),
          Image.asset(
            "assets/flash_deal.png",
            height: 20,
            color: MyTheme.golden,
          ),
          SizedBox(width: 10),
        ],
      ),
    );
  }
  //It is for Circular

  Widget timerCircularContainer(
    int currentValue,
    int totalValue,
    String timeText,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            value: currentValue / totalValue,
            backgroundColor: MyTheme.accent_color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              MyTheme.accent_color,
            ),
            strokeWidth: 4.0,
            strokeCap: StrokeCap.round,
          ),
        ),
        Text(
          timeText,
          style: TextStyle(
            color:MyTheme.accent_color,
            fontSize: 10.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  //
  Widget buildTimerRowRowShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 0, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(width: 10),
          ShimmerHelper().buildCircleShimmer(height: 30, width: 30),
          SizedBox(width: 12),
          ShimmerHelper().buildCircleShimmer(height: 30, width: 30),
          SizedBox(width: 10),
          ShimmerHelper().buildCircleShimmer(height: 30, width: 30),
          SizedBox(width: 10),
          ShimmerHelper().buildCircleShimmer(height: 30, width: 30),
          SizedBox(width: 10),
          Image.asset(
            "assets/flash_deal.png",
            height: 20,
            color: MyTheme.golden,
          ),
          Spacer(),
        ],
      ),
    );
  }

  Widget timerContainer(Widget child) {
    return Container(
      constraints: BoxConstraints(minWidth: 30, minHeight: 24),
      alignment: Alignment.center,
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: MyTheme.accent_color,
      ),
      child: child,
    );
  }
}
