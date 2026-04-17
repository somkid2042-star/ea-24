import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scratcher/scratcher.dart';
import 'package:ea24_mobile/data_model/product_mini_response.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';
import '../../custom/lang_text.dart';
import '../../custom/my_separator.dart';
import '../../custom/toast_component.dart';
import '../../custom/useful_elements.dart';
import '../../helpers/main_helpers.dart';
import '../../helpers/shared_value_helper.dart';
import '../../helpers/shimmer_helper.dart';
import '../../my_theme.dart';
import '../../repositories/coupon_repository.dart';
import 'coupon_products.dart';

class Coupons extends StatefulWidget {
  const Coupons({super.key});

  @override
  State<Coupons> createState() => _CouponsState();
}

class _CouponsState extends State<Coupons> {
  final ScrollController _scrollController = ScrollController();
  late ConfettiController _confettiController;

  Set<String> _scratchedCoupons = {};

  bool _dataFetch = false;
  final List<dynamic> _couponsList = [];
  int _page = 1;
  int _totalData = 0;
  bool _showLoadingContainer = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _loadScratchedCoupons();
    fetchData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (_couponsList.length < _totalData) {
          _page++;
          _showLoadingContainer = true;
          fetchData();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadScratchedCoupons() async {
    final prefs = await SharedPreferences.getInstance();
    _scratchedCoupons = (prefs.getStringList('scratched_coupon_ids') ?? [])
        .toSet();
    setState(() {});
  }

  Future<void> _markScratched(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final idStr = id.toString();
    if (_scratchedCoupons.contains(idStr)) return;

    _scratchedCoupons.add(idStr);
    final list = prefs.getStringList('scratched_coupon_ids') ?? [];
    list.add(idStr);
    await prefs.setStringList('scratched_coupon_ids', list);
  }

  fetchData() async {
    final res = await CouponRepository().getCouponResponseList(page: _page);
    if (!mounted) return;
    setState(() {
      _couponsList.addAll(res.data ?? []);
      _totalData = res.meta?.total ?? 0;
      _dataFetch = true;
      _showLoadingContainer = false;
    });
  }

  Future<void> _onRefresh() async {
    _page = 1;
    _couponsList.clear();
    _dataFetch = false;
    fetchData();
  }

  LinearGradient _selectGradient(int index) {
    if (index == 0 || (index + 1) % 3 == 1) {
      return MyTheme.buildLinearGradient1();
    } else if ((index + 1) % 3 == 2) {
      return MyTheme.buildLinearGradient2();
    }
    return MyTheme.buildLinearGradient3();
  }

  Widget body() {
    if (!_dataFetch) {
      return ShimmerHelper().buildListShimmer();
    }

    if (_couponsList.isEmpty) {
      return Center(child: Text(LangText(context).local.no_data_is_available));
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
          itemCount: _couponsList.length,
          separatorBuilder: (_, __) => SizedBox(height: 15.h),
          itemBuilder: (_, index) => buildCouponCard(index),
        ),
      ),
    );
  }

  Widget buildCouponCard(int index) {
    final coupon = _couponsList[index];
    final couponId = coupon.id!;
    final scratched = _scratchedCoupons.contains(couponId.toString());

    Widget revealedContent = Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: Colors.white..withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${LangText(context).local.code}: ${coupon.code}",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, size: 18.sp, color: Colors.white),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: coupon.code!));
              ToastComponent.showDialog(LangText(context).local.copied_ucf);
            },
          ),
        ],
      ),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Material(
          elevation: 0,
          borderRadius: BorderRadius.circular(30.r),
          child: Container(
            height: 200.h,
            padding: EdgeInsets.fromLTRB(30.w, 22.h, 30.w, 8.h),
            decoration: BoxDecoration(
              gradient: _selectGradient(index),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildCouponHeader(index),
                SizedBox(height: 25.h),
                MySeparator(color: Colors.white),
                SizedBox(height: 5.h),
                buildProductImageList(index),
                SizedBox(height: 8.h),
                SizedBox(
                  height: 40.h,
                  child: scratched
                      ? revealedContent
                      : Scratcher(
                          brushSize: 22,
                          threshold: 45,
                          color: Colors.grey.shade300,
                          onThreshold: () async {
                            await _markScratched(couponId);
                            _confettiController.play();
                            Clipboard.setData(
                              ClipboardData(text: coupon.code!),
                            );
                            ToastComponent.showDialog("🎉 Coupon Revealed");
                            setState(() {});
                          },
                          child: revealedContent,
                        ),
                ),
              ],
            ),
          ),
        ),
        buildCouponSideDecorations(),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          emissionFrequency: 0.05,
          numberOfParticles: 40,
          gravity: 0.25,
        ),
      ],
    );
  }

  Widget buildCouponHeader(int index) {
    final coupon = _couponsList[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          coupon.shopName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          coupon.discountType == "percent"
              ? "${coupon.discount}% ${LangText(context).local.off}"
              : "${convertPrice(coupon.discount.toString())} ${LangText(context).local.off}",
          style: TextStyle(
            color: Colors.white,
            fontSize: 21.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildProductImageList(int index) {
    return FutureBuilder<ProductMiniResponse>(
      future: CouponRepository().getCouponProductList(
        id: _couponsList[index].id!,
      ),
      builder: (_, snapshot) {
        final products = snapshot.data?.products;
        if (products == null || products.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              "No products found",
              style: TextStyle(color: Colors.white70, fontSize: 11.sp),
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CouponProducts(
                  code: _couponsList[index].code!,
                  id: _couponsList[index].id!,
                ),
              ),
            );
          },
          child: SizedBox(
            height: 36.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length.clamp(0, 3),
              itemBuilder: (_, i) => Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5.r),
                  child: Image.network(
                    products[i].thumbnailImage!,
                    width: 36.w,
                    height: 34.h,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildCouponSideDecorations() {
    return Row(
      children: [
        Container(
          height: 40.h,
          width: 20.w,
          decoration: BoxDecoration(
            color: MyTheme.mainColor,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(30.r),
              bottomRight: Radius.circular(30.r),
            ),
          ),
        ),
        const Spacer(),
        Container(
          height: 40.h,
          width: 20.w,
          decoration: BoxDecoration(
            color: MyTheme.mainColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.r),
              bottomLeft: Radius.circular(30.r),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLoadingContainer() {
    return Container(
      height: _showLoadingContainer ? 36.h : 0,
      alignment: Alignment.center,
      child: Text(
        _couponsList.length >= _totalData
            ? AppLocalizations.of(context)!.no_more_coupons_ucf
            : AppLocalizations.of(context)!.loading_coupons_ucf,
        style: TextStyle(fontSize: 12.sp),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.mainColor,
        appBar: AppBar(
          backgroundColor: MyTheme.mainColor,
          leading: UsefulElements.backButton(context),
          title: Text(
            LangText(context).local.coupons_ucf,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: MyTheme.dark_font_grey,
            ),
          ),
        ),
        body: Stack(
          children: [
            body(),
            Align(
              alignment: Alignment.bottomCenter,
              child: buildLoadingContainer(),
            ),
          ],
        ),
      ),
    );
  }
}
