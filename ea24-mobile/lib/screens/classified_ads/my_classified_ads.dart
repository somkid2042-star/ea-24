// ignore_for_file: constant_identifier_names

import 'package:ea24_mobile/custom/common_functions.dart';
import 'package:ea24_mobile/custom/device_info.dart';
import 'package:ea24_mobile/custom/lang_text.dart';
import 'package:ea24_mobile/custom/toast_component.dart';
import 'package:ea24_mobile/custom/useful_elements.dart';
import 'package:ea24_mobile/data_model/classified_ads_response.dart';
import 'package:ea24_mobile/data_model/user_info_response.dart';
import 'package:ea24_mobile/helpers/shared_value_helper.dart';
import 'package:ea24_mobile/helpers/shimmer_helper.dart';
import 'package:ea24_mobile/my_theme.dart';
import 'package:ea24_mobile/repositories/profile_repository.dart';
import 'package:ea24_mobile/screens/classified_ads/classified_product_details.dart';
import 'package:ea24_mobile/screens/package/packages.dart';
import 'package:flutter/material.dart';

import '../../repositories/classified_product_repository.dart';
import 'classified_product_add.dart';
import 'classified_product_edit.dart';

class MyClassifiedAds extends StatefulWidget {
  final bool fromBottomBar;

  const MyClassifiedAds({super.key, this.fromBottomBar = false});

  @override
  State<MyClassifiedAds> createState() => _MyClassifiedAdsState();
}

class _MyClassifiedAdsState extends State<MyClassifiedAds> {
  bool _isProductInit = false;
  bool _showMoreProductLoadingContainer = false;

  List<ClassifiedAdsMiniData> _productList = [];
  UserInformation? _userInfo;

  String _remainingProduct = "40";
  String? _currentPackageName = "...";
  late BuildContext? loadingContext;
  late BuildContext switchContext;
  BuildContext? featuredSwitchContext;

  final ScrollController _scrollController = ScrollController(
    initialScrollOffset: 0,
  );

  double mHeight = 0.0, mWidht = 0.0;
  int _page = 1;

  getProductList() async {
    var productResponse = await ClassifiedProductRepository()
        .getOwnClassifiedProducts(page: _page);
    if (!mounted) return;
    if (productResponse.data!.isEmpty) {
      ToastComponent.showDialog(LangText(context).local.no_more_products_ucf);
    }
    _productList.addAll(productResponse.data!);
    _showMoreProductLoadingContainer = false;
    _isProductInit = true;
    setState(() {});
  }

  getUserInfo() async {
    var userInfoRes = await ProfileRepository().getUserInfoResponse();
    if (userInfoRes.data.isNotEmpty) {
      _userInfo = userInfoRes.data.first;
      _remainingProduct = _userInfo!.remainingUploads.toString();
      _currentPackageName = _userInfo!.packageName;
    }

    setState(() {});
  }

  deleteProduct(int? id) async {
    loading();
    var response = await ClassifiedProductRepository()
        .getDeleteClassifiedProductResponse(id);
    Navigator.pop(loadingContext!);
    if (response.result) {
      resetAll();
    }
    ToastComponent.showDialog(response.message, duration: 3);
  }

  productStatusChange(int? index, bool value, setState, id) async {
    loading();
    var response = await ClassifiedProductRepository()
        .getStatusChangeClassifiedProductResponse(id, value ? 1 : 0);
    if (!mounted) return;
    Navigator.pop(loadingContext!);
    if (response.result) {
      _productList[index!].status = value;
      resetAll();
    }
    Navigator.pop(switchContext);
    ToastComponent.showDialog(response.message, duration: 3);
  }

  scrollControllerPosition() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _showMoreProductLoadingContainer = true;
        setState(() {
          _page++;
        });
        getProductList();
      }
    });
  }

  cleanAll() {
    // print("clean all");
    _isProductInit = false;
    _showMoreProductLoadingContainer = false;
    _productList = [];
    _page = 1;
    _remainingProduct = "....";
    _currentPackageName = "...";
    setState(() {});
  }

  fetchAll() {
    getProductList();
    getUserInfo();
  }

  resetAll() {
    cleanAll();
    fetchAll();
  }

  _tabOption(int index, productId, listIndex) async {
    switch (index) {
      case 0:
        showChangeStatusDialog(listIndex, productId);
        break;
      case 1:
        showDeleteWarningDialog(productId);
        break;
      case 2:
        bool? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassifiedProductEdit(productId: productId),
          ),
        );

        if (result == true) {
          setState(() {
            resetAll();
          });
        }
        break;

      default:
        break;
    }
  }

  void dismissLoading() {
    if (loadingContext != null) {
      Navigator.of(loadingContext!).pop();
      loadingContext = null;
    }
  }

  @override
  void initState() {
    scrollControllerPosition();
    fetchAll();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    mHeight = MediaQuery.of(context).size.height;
    mWidht = MediaQuery.of(context).size.width;
    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 0.0,
          elevation: 0,
          title: Text(
            LangText(context).local.my_products_ucf,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MyTheme.dark_font_grey,
            ),
          ),
          backgroundColor: MyTheme.mainColor,
          leading: UsefulElements.backButton(context),
        ),
        backgroundColor: MyTheme.mainColor,
        body: buildBody(context),
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () async {
        resetAll();
        // Future.delayed(Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        child: Column(
          children: [
            buildTop2BoxContainer(context),
            SizedBox(height: 16),
            Visibility(
              visible: classified_product_status.$,
              child: buildPackageUpgradeContainer(context),
            ),
            SizedBox(height: 15),
            Container(
              child: _isProductInit
                  ? productsContainer()
                  : ShimmerHelper().buildListShimmer(
                      itemCount: 20,
                      itemHeight: 80.0,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPackageUpgradeContainer(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            height: 40,
            width: DeviceInfo(context).width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: MyTheme.accent_color, width: 1),
              color: Color(0xffFBEAE6),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UpdatePackage()),
                ).then((value) {
                  resetAll();
                });
                //  MyTransaction(context: context).push(Packages());
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset("assets/package.png", height: 20, width: 20),
                      SizedBox(width: 5),
                      Text(
                        LangText(context).local.current_package_ucf,
                        style: TextStyle(fontSize: 10, color: MyTheme.grey_153),
                      ),
                      SizedBox(width: 11),
                      Text(
                        _currentPackageName!,
                        style: TextStyle(
                          fontSize: 10,
                          color: MyTheme.accent_color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Row(
                    children: [
                      Text(
                        LangText(context).local.upgrade_package_ucf,
                        style: TextStyle(
                          fontSize: 12,
                          color: MyTheme.accent_color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Image.asset(
                        "assets/next_arrow.png",
                        color: MyTheme.accent_color,
                        height: 9.08,
                        width: 7,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Container buildTop2BoxContainer(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  spreadRadius: 0.5,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
              color: MyTheme.accent_color,
            ),
            height: 75,
            width: mWidht / 2 - 23,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  LangText(context).local.remaining_uploads,
                  style: CommonFunctions.dashboardBoxText(context),
                ),
                SizedBox(height: 2),
                Text(
                  _remainingProduct,
                  style: CommonFunctions.dashboardBoxNumber(context),
                ),
              ],
            ),
          ),
          // if(false)
          SizedBox(width: 10),
          InkWell(
            onTap: () {
              if (int.parse(_remainingProduct) == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UpdatePackage()),
                ).then((value) {
                  resetAll();
                });

                ToastComponent.showDialog(
                  LangText(context).local.classified_product_limit_expired,
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClassifiedProductAdd(),
                  ),
                ).then((value) => resetAll());
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    spreadRadius: 0.5,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
                color: Color(0xffFEF0D7),
                border: Border.all(color: Color(0xffFFA800), width: 1),
              ),
              height: 75,
              width: mWidht / 2 - 23,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    LangText(context).local.add_new_products_ucf,
                    style: CommonFunctions.dashboardBoxText(context).copyWith(
                      color: MyTheme.accent_color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Image.asset(
                    "assets/add.png",
                    color: MyTheme.accent_color,
                    height: 18,
                    width: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget productsContainer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LangText(context).local.all_products_ucf,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: MyTheme.accent_color,
            ),
          ),
          SizedBox(height: 10),
          ListView.separated(
            separatorBuilder: (context, index) => SizedBox(height: 20),
            physics: NeverScrollableScrollPhysics(),
            itemCount: _productList.length + 1,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              // print(index);
              if (index == _productList.length) {
                return moreProductLoading();
              }
              return productItem(
                index: index,
                productId: _productList[index].id,
                imageUrl: _productList[index].thumbnailImage,
                slug: _productList[index].slug,
                productTitle: _productList[index].name!,
                productPrice: _productList[index].unitPrice,
                condition: _productList[index].condition.toString(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget productItem({
    int? index,
    productId,
    String? slug,
    String? imageUrl,
    required String productTitle,
    String? productPrice,
    String? condition,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassifiedAdsDetails(slug: slug ?? ''),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              //   spreadRadius: 0.5,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                UsefulElements.roundImageWithPlaceholder(
                  width: 88.0,
                  height: 80.0,
                  fit: BoxFit.cover,
                  url: imageUrl,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    bottomLeft: Radius.circular(5),
                  ),
                ),
                SizedBox(width: 5),
                SizedBox(
                  width: mWidht - 129,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                textAlign: TextAlign.start,
                                productTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xff3E4447),
                                  fontSize: 13,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            child: showOptions(
                              listIndex: index,
                              productId: productId,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Visibility(
              visible: true,
              child: Positioned.fill(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: condition == "new"
                          ? MyTheme.golden
                          : MyTheme.accent_color,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(6.0),
                        bottomRight: Radius.circular(6.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x14000000),
                          offset: Offset(-1, 1),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      condition ?? "",
                      style: TextStyle(
                        fontSize: 10,
                        color: const Color(0xffffffff),
                        fontWeight: FontWeight.w700,
                        height: 1.8,
                      ),
                      textHeightBehavior: TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                      ),
                      softWrap: false,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  showDeleteWarningDialog(id) {
    showDialog(
      context: context,
      builder: (context) => SizedBox(
        width: DeviceInfo(context).width! * 1.5,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            LangText(context).local.do_you_want_to_delete_it,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.red,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this product?',
            style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
          ),
          actions: [
            TextButton(
              child: Text(LangText(context).local.cancel_ucf),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                deleteProduct(id);
              },
              child: Text(LangText(context).local.yes_ucf),
            ),
          ],
        ),
      ),
    );
  }

  Widget showOptions({listIndex, productId}) {
    return SizedBox(
      width: 35,
      child: PopupMenuButton<MenuOptions>(
        color: Colors.white,
        offset: Offset(-12, 0),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Container(
            width: 35,
            padding: EdgeInsets.symmetric(horizontal: 15),
            alignment: Alignment.topRight,
            child: Image.asset(
              "assets/more.png",
              width: 3,
              height: 15,
              fit: BoxFit.contain,
              color: MyTheme.grey_153,
            ),
          ),
        ),
        onSelected: (MenuOptions result) {
          _tabOption(result.index, productId, listIndex);
          // setState(() {
          //   _menuOptionSelected = result;
          // });
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuOptions>>[
          PopupMenuItem<MenuOptions>(
            value: MenuOptions.Edit,
            child: Text(LangText(context).local.edit_ucf),
          ),
          PopupMenuItem<MenuOptions>(
            value: MenuOptions.Status,
            child: Text(LangText(context).local.status_ucf),
          ),
          PopupMenuItem<MenuOptions>(
            value: MenuOptions.Delete,
            child: Text(LangText(context).local.delete_ucf),
          ),
        ],
      ),
    );
  }

  void showChangeStatusDialog(int? index, id) {
    showDialog(
      context: context,
      builder: (context) {
        switchContext = context;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.0),
              ),
              content: SizedBox(
                height: 40,
                width: DeviceInfo(context).width,
                child: Center(
                  // Centering the content
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _productList[index!].status!
                            ? LangText(context).local.published_ucf
                            : LangText(context).local.unpublished_ucf,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _productList[index].status!,
                          activeThumbColor: Colors.green,
                          activeTrackColor: Color(0xffE9E9F0),
                          inactiveThumbColor: MyTheme.grey_153,
                          onChanged: (value) {
                            productStatusChange(index, value, setState, id);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showFeaturedUnFeaturedDialog(int index, id) {
    showDialog(
      context: context,
      builder: (context) {
        featuredSwitchContext = context;
        return StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: 75,
              width: DeviceInfo(context).width,
              child: AlertDialog(
                content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _productList[index].published!
                          ? LangText(context).local.published_ucf
                          : LangText(context).local.unpublished_ucf,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Switch(
                      value: _productList[index].published!,
                      activeThumbColor: Colors.green,
                      inactiveThumbColor: MyTheme.grey_153,
                      onChanged: (value) {},
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

  loading() {
    showDialog(
      context: context,
      builder: (context) {
        loadingContext = context;
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text(LangText(context).local.loading_ucf),
            ],
          ),
        );
      },
    );
  }

  Widget moreProductLoading() {
    return _showMoreProductLoadingContainer
        ? Container(
            alignment: Alignment.center,
            child: SizedBox(
              height: 40,
              width: 40,
              child: Row(
                children: [
                  SizedBox(width: 2, height: 2),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          )
        : SizedBox(height: 5, width: 5);
  }
}

enum MenuOptions { Status, Delete, Edit }
