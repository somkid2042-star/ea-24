import 'package:ea24_mobile/custom/lang_text.dart';
import 'package:ea24_mobile/custom/useful_elements.dart';
import 'package:ea24_mobile/helpers/shimmer_helper.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/repositories/shop_repository.dart';
import 'package:ea24_mobile/ui_elements/shop_square_card.dart';
import 'package:flutter/material.dart';

import '../data_model/shop_response.dart';

class TopSellers extends StatefulWidget {
  const TopSellers({super.key});

  @override
  State<TopSellers> createState() => _TopSellersState();
}

class _TopSellersState extends State<TopSellers> {
  ScrollController? _scrollController;
  List<Shop> topSellers = [];
  bool isInit = false;

  getTopSellers() async {
    ShopResponse response = await ShopRepository().topSellers();
    isInit = true;
    if (response.shops != null) {
      topSellers.addAll(response.shops!);
    }

    setState(() {});
  }

  clearAll() {
    isInit = false;
    topSellers.clear();
    setState(() {});
  }

  Future<void> onRefresh() async {
    clearAll();

    return await getTopSellers();
  }

  @override
  void initState() {
    getTopSellers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.mainColor,
      appBar: buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: buildTopSellerList(context)),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      leading: UsefulElements.backButton(context),
      title: Text(
        LangText(context).local.top_sellers_ucf,
        style: TextStyle(
            fontSize: 16,
            color: MyTheme.dark_font_grey,
            fontWeight: FontWeight.bold),
      ),
      elevation: 0.0,
      scrolledUnderElevation: 0.0,
      titleSpacing: 0,
    );
  }

  Widget buildTopSellerList(context) {
    if (isInit) {

      return GridView.builder(

        itemCount: topSellers.length,
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.66),
        padding: EdgeInsets.only(top: 20, bottom: 10, left: 18, right: 18),
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return ShopSquareCard(
            id: topSellers[index].id,
            shopSlug: topSellers[index].slug ?? "",
            image: topSellers[index].logo,
            name: topSellers[index].name,
            stars: double.parse(topSellers[index].rating.toString()),
          );
        },
      );
    } else {
      return ShimmerHelper()
          .buildSquareGridShimmer(scontroller: _scrollController);
    }
  }
}
