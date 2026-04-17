import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/device_info.dart';
import 'package:active_ecommerce_cms_demo_app/custom/useful_elements.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/category_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/presenter/bottom_appbar_index.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/category_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/category_list_n_product/category_products.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';

import '../../custom/category_item_card_widget.dart';

class CategoryList extends StatefulWidget {
  final String slug;
  final bool isBaseCategory;
  final bool isTopCategory;
  final BottomAppbarIndex? bottomAppbarIndex;

  const CategoryList({
    super.key,
    required this.slug,
    this.isBaseCategory = false,
    this.isTopCategory = false,
    this.bottomAppbarIndex,
  });
  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PreferredSize(
              preferredSize: Size(DeviceInfo(context).width!, 50),
              child: buildAppBar(context),
            ),
            body: buildBody(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: widget.isBaseCategory || widget.isTopCategory
                ? Container(height: 0)
                : buildBottomContainer(),
          ),
        ],
      ),
    );
  }

  Widget buildBody() {
    return Container(
      color: Color(0xffECF1F5),
      child: CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              buildCategoryList(),
              Container(height: widget.isBaseCategory ? 60 : 90),
            ]),
          ),
        ],
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      leading: widget.isBaseCategory
          ? Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 0.0,
                  horizontal: 0.0,
                ),
                child: UsefulElements.backToMain(
                  context,
                  goBack: false,
                  color: "black",
                ),
              ),
            )
          : Builder(
              builder: (context) => IconButton(
                icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
      title: Text(
        getAppBarTitle(),
        style: TextStyle(
          fontSize: 16,
          color: Color(0xff121423),
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  String getAppBarTitle() {
    String name = widget.isTopCategory
        ? AppLocalizations.of(context)!.top_categories_ucf
        : AppLocalizations.of(context)!.categories_ucf;

    return name;
  }

  buildCategoryList() {
    var data = widget.isTopCategory
        ? CategoryRepository().getTopCategories()
        : CategoryRepository().getCategories(parentId: widget.slug);
    return FutureBuilder(
      future: data,
      builder: (context, AsyncSnapshot<CategoryResponse> snapshot) {
        // if getting response is
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SingleChildScrollView(
            child: ShimmerHelper().buildCategoryCardShimmer(
              isBaseCategory: widget.isBaseCategory,
            ),
          );
        }
        // if response has issue
        if (snapshot.hasError) {
          return Container(height: 10);
        } else if (snapshot.hasData) {
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.7,
              crossAxisCount: 3,
            ),
            itemCount: snapshot.data!.categories!.length,
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              bottom: widget.isBaseCategory ? 30 : 0,
            ),
            scrollDirection: Axis.vertical,
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return CategoryItemCardWidget(
                categoryResponse: snapshot.data!,
                index: index,
              );
            },
          );
        } else {
          return SingleChildScrollView(
            child: ShimmerHelper().buildCategoryCardShimmer(
              isBaseCategory: widget.isBaseCategory,
            ),
          );
        }
      },
    );
  }

  Container buildBottomContainer() {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      height: widget.isBaseCategory ? 0 : 80,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SizedBox(
                width: (MediaQuery.of(context).size.width - 32),
                height: 40,
                child: Btn.basic(
                  minWidth: MediaQuery.of(context).size.width,
                  color: MyTheme.accent_color,
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                  ),
                  child: Text(
                    "${AppLocalizations.of(context)!.all_products_of_ucf} ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return CategoryProducts(slug: widget.slug);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
