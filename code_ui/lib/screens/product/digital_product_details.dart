import 'dart:async';

import 'package:badges/badges.dart' as badges;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app_config.dart';
import '../../custom/box_decorations.dart';
import '../../custom/btn.dart';
import '../../custom/device_info.dart';
import '../../custom/lang_text.dart';
import '../../custom/toast_component.dart';
import '../../data_model/product_details_response.dart';
import '../../helpers/color_helper.dart';
import '../../helpers/main_helpers.dart';
import '../../helpers/shared_value_helper.dart';
import '../../helpers/shimmer_helper.dart';
import '../../helpers/system_config.dart';
import '../../my_theme.dart';
import '../../presenter/cart_counter.dart';
import '../../repositories/cart_repository.dart';
import '../../repositories/chat_repository.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/wishlist_repository.dart';
import '../../ui_elements/mini_product_card.dart';
import '../../ui_elements/top_selling_products_card.dart';
import '../brand_products.dart';
import '../chat/chat.dart';
import '../checkout/cart.dart';
import '../seller_details.dart';
import '../video_description_screen.dart';
import 'product_reviews.dart';
import 'widgets/product_slider_image_widget.dart';
import 'widgets/tappable_icon_widget.dart';

class DigitalProductDetails extends StatefulWidget {
  final String slug;

  const DigitalProductDetails({super.key, required this.slug});

  @override
  State<DigitalProductDetails> createState() => _DigitalProductDetailsState();
}

class _DigitalProductDetailsState extends State<DigitalProductDetails>
    with TickerProviderStateMixin {
  bool _showCopied = false;
  String? _appbarPriceString = ". . .";
  int _currentImage = 0;
  final ScrollController _mainScrollController = ScrollController(
    initialScrollOffset: 0.0,
  );
  final ScrollController _colorScrollController = ScrollController();
  final ScrollController _variantScrollController = ScrollController();
  final ScrollController _imageScrollController = ScrollController();
  TextEditingController sellerChatTitleController = TextEditingController();
  TextEditingController sellerChatMessageController = TextEditingController();

  double _scrollPosition = 0.0;

  WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..enableZoom(false);
  double webViewHeight = 50.0;

  final CarouselSliderController _carouselController =
      CarouselSliderController();
  late BuildContext loadingcontext;

  //init values

  bool _isInWishList = false;
  DetailedProduct? _productDetails;
  final _productImageList = [];
  final _colorList = [];
  int _selectedColorIndex = 0;
  final _selectedChoices = [];
  var _choiceString = "";
  String? _variant = "";
  String? _totalPrice = "...";
  // ignore: prefer_typing_uninitialized_variables
  var _singlePriceString;
  int? _quantity = 1;
  int? _stock = 0;

  double opacity = 0;

  final List<dynamic> _relatedProducts = [];
  bool _relatedProductInit = false;
  final List<dynamic> _topProducts = [];
  bool _topProductInit = false;

  @override
  void initState() {
    quantityText.text = "${_quantity ?? 0}";
    controller;

    _mainScrollController.addListener(() {
      _scrollPosition = _mainScrollController.position.pixels;

      if (_mainScrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (100 > _scrollPosition && _scrollPosition > 1) {
          opacity = _scrollPosition / 100;
        }
      }

      if (_mainScrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (100 > _scrollPosition && _scrollPosition > 1) {
          opacity = _scrollPosition / 100;

          if (100 > _scrollPosition) {
            opacity = 1;
          }
        }
      }

      setState(() {});
    });
    fetchAll();
    super.initState();
  }

  fetchAll() {
    fetchProductDetails();
    if (is_logged_in.$ == true) {
      fetchWishListCheckInfo();
    }
    fetchRelatedProducts();
    fetchTopProducts();
  }

  fetchProductDetails() async {
    var productDetailsResponse = await ProductRepository().getProductDetails(
      slug: widget.slug,
      userId: user_id.$,
    );

    if (productDetailsResponse.detailedProducts!.isNotEmpty) {
      _productDetails = productDetailsResponse.detailedProducts![0];
      sellerChatTitleController.text =
          productDetailsResponse.detailedProducts![0].name!;
    }

    setProductDetailValues();

    setState(() {});
  }

  fetchRelatedProducts() async {
    var relatedProductResponse = await ProductRepository()
        .getFrequentlyBoughProducts(slug: widget.slug);
    _relatedProducts.addAll(relatedProductResponse.products!);
    _relatedProductInit = true;

    setState(() {});
  }

  fetchTopProducts() async {
    var topProductResponse = await ProductRepository()
        .getTopFromThisSellerProducts(slug: widget.slug);
    _topProducts.addAll(topProductResponse.products!);
    _topProductInit = true;
  }

  setProductDetailValues() {
    if (_productDetails != null) {
      controller.loadHtmlString(makeHtml(_productDetails!.description!));
      _appbarPriceString = _productDetails!.priceHighLow;
      _singlePriceString = _productDetails!.mainPrice;
      _stock = _productDetails!.currentStock;
      for (var photo in _productDetails!.photos!) {
        _productImageList.add(photo.path);
      }

      for (var choiceOption in _productDetails!.choiceOptions!) {
        _selectedChoices.add(choiceOption.options![0]);
      }
      for (var color in _productDetails!.colors!) {
        _colorList.add(color);
      }
      setChoiceString();
      fetchAndSetVariantWiseInfo(changeAppbarString: true);

      setState(() {});
    }
  }

  setChoiceString() {
    _choiceString = _selectedChoices.join(",").toString();

    setState(() {});
  }

  fetchWishListCheckInfo() async {
    var wishListCheckResponse = await WishListRepository()
        .isProductInUserWishList(productSlug: widget.slug);

    if (wishListCheckResponse.isInWishlist != null) {
      _isInWishList = wishListCheckResponse.isInWishlist!;
    } else {
      _isInWishList = false;
    }

    setState(() {});
  }

  addToWishList() async {
    var wishListCheckResponse = await WishListRepository().add(
      productSlug: widget.slug,
    );

    _isInWishList = wishListCheckResponse.isInWishlist;
    setState(() {});
  }

  removeFromWishList() async {
    var wishListCheckResponse = await WishListRepository().remove(
      productSlug: widget.slug,
    );

    _isInWishList = wishListCheckResponse.isInWishlist;
    setState(() {});
  }

  onWishTap() {
    if (is_logged_in.$ == false) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.you_need_to_log_in,
      );
      return;
    }

    if (_isInWishList) {
      _isInWishList = false;
      setState(() {});
      removeFromWishList();
    } else {
      _isInWishList = true;
      setState(() {});
      addToWishList();
    }
  }

  setQuantity(quantity) {
    quantityText.text = "${quantity ?? 0}";
  }

  fetchAndSetVariantWiseInfo({bool changeAppbarString = true}) async {
    var colorString = _colorList.isNotEmpty
        ? _colorList[_selectedColorIndex].toString().replaceAll("#", "")
        : "";

    var variantResponse = await ProductRepository().getVariantWiseInfo(
      slug: widget.slug,
      color: colorString,
      variants: _choiceString,
      qty: _quantity,
    );
    _stock = variantResponse.variantData!.stock;
    if (_quantity! > _stock!) {
      _quantity = _stock;
    }

    _variant = variantResponse.variantData!.variant;
    _totalPrice = variantResponse.variantData!.price;

    int pindex = 0;
    _productDetails!.photos?.forEach((photo) {
      if (photo.variant == _variant &&
          variantResponse.variantData!.image != "") {
        _currentImage = pindex;
        _carouselController.jumpToPage(pindex);
      }
      pindex++;
    });
    setQuantity(_quantity);
    setState(() {});
  }

  reset() {
    restProductDetailValues();
    _currentImage = 0;
    _productImageList.clear();
    _colorList.clear();
    _selectedChoices.clear();
    _relatedProducts.clear();
    _topProducts.clear();
    _choiceString = "";
    _variant = "";
    _selectedColorIndex = 0;
    _quantity = 1;
    _isInWishList = false;
    sellerChatTitleController.clear();
    setState(() {});
  }

  restProductDetailValues() {
    _appbarPriceString = " . . .";
    _productDetails = null;
    _productImageList.clear();
    _currentImage = 0;
    setState(() {});
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchAll();
  }

  _onVariantChange(choiceOptionsIndex, value) {
    _selectedChoices[choiceOptionsIndex] = value;
    setChoiceString();
    setState(() {});
    fetchAndSetVariantWiseInfo();
  }

  _onColorChange(index) {
    _selectedColorIndex = index;
    setState(() {});
    fetchAndSetVariantWiseInfo();
  }

  onPressAddToCart(context, snackbar) {
    addToCart(mode: "add_to_cart", snackbar: snackbar);
  }

  onPressBuyNow(context) {
    addToCart(mode: "buy_now");
  }

  addToCart({required String mode, snackbar}) async {
    if (!guest_checkout_status.$ && is_logged_in.$ == false) {
      context.go("/users/login");
      return;
    }

    final cartAddResponse = await CartRepository().getCartAddResponse(
      _productDetails!.id,
      _variant,
      user_id.$,
      1,
    );
    if (!mounted) return;
    temp_user_id.$ = cartAddResponse.tempUserId;
    temp_user_id.save();
    if (cartAddResponse.result == false) {
      ToastComponent.showDialog(cartAddResponse.message);
      return;
    }
    Provider.of<CartCounter>(context, listen: false).getCount();

    if (mode == "add_to_cart") {
      if (snackbar != null) {
        ScaffoldMessenger.of(context).showSnackBar(snackbar);
      }
      reset();
      fetchAll();
    } else if (mode == 'buy_now') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Cart(hasBottomnav: false)),
      ).then(onPopped);
    }
  }

  onPopped(value) async {
    reset();
    fetchAll();
  }

  onCopyTap(setState) {
    setState(() {
      _showCopied = true;
    });
  }

  onPressShare(context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, StateSetter setState) {
            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 10),
              contentPadding: EdgeInsets.only(
                top: 36.0,
                left: 36.0,
                right: 36.0,
                bottom: 2.0,
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Btn.minWidthFixHeight(
                          minWidth: 75,
                          height: 26,
                          color: Color.fromRGBO(253, 253, 253, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(color: Colors.black, width: 1.0),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.copy_product_link_ucf,
                            style: TextStyle(color: MyTheme.medium_grey),
                          ),
                          onPressed: () async {
                            onCopyTap(setState);

                            await Clipboard.setData(
                              ClipboardData(text: _productDetails!.link ?? ""),
                            );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Copied to clipboard"),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(milliseconds: 300),
                              ),
                            );
                          },
                        ),
                      ),
                      _showCopied
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                AppLocalizations.of(context)!.copied_ucf,
                                style: TextStyle(
                                  color: MyTheme.medium_grey,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : Container(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Btn.minWidthFixHeight(
                          minWidth: 75,
                          height: 26,
                          color: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(color: Colors.black, width: 1.0),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.share_options_ucf,
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            Share.share(_productDetails!.link!);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding: app_language_rtl.$!
                          ? EdgeInsets.only(left: 8.0)
                          : EdgeInsets.only(right: 8.0),
                      child: Btn.minWidthFixHeight(
                        minWidth: 75,
                        height: 30,
                        color: Color.fromRGBO(253, 253, 253, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(
                            color: MyTheme.font_grey,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          LangText(context).local.close_all_capital,
                          style: TextStyle(color: MyTheme.font_grey),
                        ),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  onTapSellerChat() {
    return showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: app_language_rtl.$!
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: AlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 10),
          contentPadding: EdgeInsets.only(
            top: 36.0,
            left: 36.0,
            right: 36.0,
            bottom: 2.0,
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      AppLocalizations.of(context)!.title_ucf,
                      style: TextStyle(color: MyTheme.font_grey, fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: sellerChatTitleController,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(
                            context,
                          )!.enter_title_ucf,
                          hintStyle: TextStyle(
                            fontSize: 12.0,
                            color: MyTheme.textfield_grey,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: MyTheme.textfield_grey,
                              width: 0.5,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: MyTheme.textfield_grey,
                              width: 1.0,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "${AppLocalizations.of(context)!.message_ucf} *",
                      style: TextStyle(color: MyTheme.font_grey, fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SizedBox(
                      height: 55,
                      child: TextField(
                        controller: sellerChatMessageController,
                        autofocus: false,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(
                            context,
                          )!.enter_message_ucf,
                          hintStyle: TextStyle(
                            fontSize: 12.0,
                            color: MyTheme.textfield_grey,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: MyTheme.textfield_grey,
                              width: 0.5,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: MyTheme.textfield_grey,
                              width: 1.0,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8.0),
                            ),
                          ),
                          contentPadding: EdgeInsets.only(
                            right: 16.0,
                            left: 8.0,
                            top: 16.0,
                            bottom: 16.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Btn.minWidthFixHeight(
                    minWidth: 75,
                    height: 30,
                    color: Color.fromRGBO(253, 253, 253, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: MyTheme.light_grey, width: 1.0),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.close_all_capital,
                      style: TextStyle(color: MyTheme.font_grey),
                    ),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                  ),
                ),
                SizedBox(width: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Btn.minWidthFixHeight(
                    minWidth: 75,
                    height: 30,
                    color: MyTheme.accent_color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: MyTheme.light_grey, width: 1.0),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.send_all_capital,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      onPressSendMessage();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
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

  showLoginWarning() {
    return ToastComponent.showDialog(
      AppLocalizations.of(context)!.you_need_to_log_in,
    );
  }

  onPressSendMessage() async {
    if (!is_logged_in.$) {
      showLoginWarning();
      return;
    }
    loading();
    var title = sellerChatTitleController.text.toString();
    var message = sellerChatMessageController.text.toString();

    if (title == "" || message == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.title_or_message_empty_warning,
      );
      return;
    }

    var conversationCreateResponse = await ChatRepository()
        .getCreateConversationResponse(
          productId: _productDetails!.id,
          title: title,
          message: message,
        );
    if (!mounted) return;
    Navigator.of(loadingcontext).pop();

    if (conversationCreateResponse.result == false) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.could_not_create_conversation,
      );
      return;
    }

    sellerChatTitleController.clear();
    sellerChatMessageController.clear();
    setState(() {});

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Chat(
            conversationId: conversationCreateResponse.conversation_id,
            messengerName: conversationCreateResponse.shop_name,
            messengerTitle: conversationCreateResponse.title,
            messengerImage: conversationCreateResponse.shop_logo,
          );
        },
      ),
    ).then((value) {
      onPopped(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    SnackBar addedToCartSnackbar = SnackBar(
      content: Text(
        AppLocalizations.of(context)!.added_to_cart,
        style: TextStyle(color: MyTheme.font_grey),
      ),
      backgroundColor: MyTheme.soft_accent_color,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: AppLocalizations.of(context)!.show_cart_all_capital,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return Cart(hasBottomnav: false);
              },
            ),
          ).then((value) {
            onPopped(value);
          });
        },
        textColor: MyTheme.accent_color,
        disabledTextColor: Colors.grey,
      ),
    );

    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        extendBody: true,
        backgroundColor: MyTheme.mainColor,
        bottomNavigationBar: buildBottomAppBar(context, addedToCartSnackbar),
        body: RefreshIndicator(
          color: MyTheme.accent_color,
          backgroundColor: Colors.white,
          onRefresh: _onPageRefresh,
          child: CustomScrollView(
            controller: _mainScrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: <Widget>[
              SliverAppBar(
                elevation: 0,
                scrolledUnderElevation: 0.0,
                backgroundColor: MyTheme.mainColor,
                pinned: true,
                automaticallyImplyLeading: false,
                expandedHeight: 355.0,
                title: AnimatedOpacity(
                  opacity: _scrollPosition > 250 ? 1 : 0,
                  duration: Duration(milliseconds: 200),
                  child: Container(
                    padding: EdgeInsets.only(left: 8),
                    width: DeviceInfo(context).width! / 2,
                    child: Text(
                      "${_productDetails != null ? _productDetails!.name : ''}",
                      style: TextStyle(
                        color: MyTheme.dark_font_grey,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Positioned.fill(
                        child: ProductSliderImageWidget(
                          productImageList: _productImageList,
                          currentImage: _currentImage,
                          carouselController: _carouselController,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 48,
                          left: 33,
                          right: 33,
                        ),
                        child: Row(
                          children: [
                            Builder(
                              builder: (context) => InkWell(
                                onTap: () {
                                  return Navigator.of(context).pop();
                                },
                                child: Container(
                                  decoration:
                                      BoxDecorations.buildCircularButtonDecorationForProductDetails(),
                                  width: 36,
                                  height: 36,
                                  child: Center(
                                    child: Icon(
                                      CupertinoIcons.arrow_left,
                                      color: MyTheme.dark_font_grey,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Show product name in appbar
                            Spacer(),
                            // Cart button at top
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return Cart(hasBottomnav: false);
                                    },
                                  ),
                                ).then((value) {
                                  onPopped(value);
                                });
                              },
                              child: Container(
                                decoration:
                                    BoxDecorations.buildCircularButtonDecorationForProductDetails(),
                                width: 32,
                                height: 32,
                                padding: EdgeInsets.all(2),
                                child: badges.Badge(
                                  position: badges.BadgePosition.topEnd(
                                    top: -6,
                                    end: -6,
                                  ),
                                  badgeStyle: badges.BadgeStyle(
                                    shape: badges.BadgeShape.circle,
                                    badgeColor: MyTheme.accent_color,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  badgeAnimation: badges.BadgeAnimation.slide(
                                    toAnimate: true,
                                  ),
                                  stackFit: StackFit.loose,
                                  badgeContent: Consumer<CartCounter>(
                                    builder: (context, cart, child) {
                                      return Text(
                                        "${cart.cartCounter}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      "assets/cart.png",
                                      color: MyTheme.dark_font_grey,
                                      height: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 15),
                            InkWell(
                              onTap: () {
                                onPressShare(context);
                              },
                              child: TappableIconWidget(
                                icon: Icons.share_outlined,
                                color: MyTheme.dark_font_grey,
                              ),
                            ),
                            SizedBox(width: 15),
                            InkWell(
                              onTap: () {
                                onWishTap();
                              },
                              child: TappableIconWidget(
                                icon: Icons.favorite,
                                color: _isInWishList
                                    ? Color.fromRGBO(230, 46, 4, 1)
                                    : MyTheme.dark_font_grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .08),
                          blurRadius: 20,
                          spreadRadius: 0.0,
                          offset: Offset(0.0, 0.0),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _productDetails != null
                                  ? Text(
                                      _productDetails!.name!,
                                      style: TextStyle(
                                        color: Color(0xff3E4447),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Public Sans',
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                    )
                                  : ShimmerHelper().buildBasicShimmer(
                                      height: 30.0,
                                    ),
                              SizedBox(height: 13),
                              _productDetails != null
                                  ? buildRatingAndWishButtonRow()
                                  : ShimmerHelper().buildBasicShimmer(
                                      height: 30.0,
                                    ),
                              if (_productDetails != null &&
                                  _productDetails!.estShippingTime != null &&
                                  _productDetails!.estShippingTime! > 0)
                                _productDetails != null
                                    ? buildShippingTime()
                                    : ShimmerHelper().buildBasicShimmer(
                                        height: 30.0,
                                      ),
                              SizedBox(height: 12),
                              _productDetails != null
                                  ? buildMainPriceRow()
                                  : ShimmerHelper().buildBasicShimmer(
                                      height: 30.0,
                                    ),
                              SizedBox(height: 14),
                              Visibility(
                                visible: club_point_addon_installed.$,
                                child: _productDetails != null
                                    ? buildClubPointRow()
                                    : ShimmerHelper().buildBasicShimmer(
                                        height: 30.0,
                                      ),
                              ),
                              SizedBox(height: 9),
                              _productDetails != null
                                  ? buildBrandRow()
                                  : ShimmerHelper().buildBasicShimmer(
                                      height: 50.0,
                                    ),
                            ],
                          ),
                        ),
                        _productDetails != null
                            ? buildSellerRow(context)
                            : ShimmerHelper().buildBasicShimmer(height: 50.0),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                          child: Column(
                            children: [
                              SizedBox(height: 11),

                              _productDetails != null
                                  ? buildChoiceOptionList()
                                  : buildVariantShimmers(),

                              _productDetails != null
                                  ? (_colorList.isNotEmpty
                                        ? buildColorRow()
                                        : Container())
                                  : ShimmerHelper().buildBasicShimmer(
                                      height: 30.0,
                                    ),
                              SizedBox(height: 20),

                              ///whole sale
                              Visibility(
                                visible: whole_sale_addon_installed.$,
                                child: _productDetails != null
                                    ? _productDetails!.wholesale!.isNotEmpty
                                          ? buildWholeSaleQuantityPrice()
                                          : SizedBox.shrink()
                                    : ShimmerHelper().buildBasicShimmer(
                                        height: 30.0,
                                      ),
                              ),

                              _productDetails != null
                                  ? SizedBox()
                                  : ShimmerHelper().buildBasicShimmer(
                                      height: 30.0,
                                    ),
                            ],
                          ),
                        ),
                        SizedBox(height: 27),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _productDetails != null
                              ? buildTotalPriceRow()
                              : ShimmerHelper().buildBasicShimmer(height: 30.0),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),

              //for description
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            spreadRadius: 0,
                            blurRadius: 16,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              20.0,
                              16.0,
                              0.0,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.description_ucf,
                              style: TextStyle(
                                color: Color(0xff3E4447),
                                fontFamily: 'Public Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              0.0,
                              8.0,
                              8.0,
                            ),
                            child: _productDetails != null
                                ? buildExpandableDescription()
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 8.0,
                                    ),
                                    child: ShimmerHelper().buildBasicShimmer(
                                      height: 60.0,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    if (_productDetails?.downloads != null)
                      Column(
                        children: [
                          SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              var url = Uri.parse(
                                _productDetails?.downloads ?? "",
                              );

                              launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            child: Container(
                              color: MyTheme.white,
                              height: 48,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18.0,
                                  14.0,
                                  18.0,
                                  14.0,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.downloads_ucf,
                                      style: TextStyle(
                                        color: MyTheme.dark_font_grey,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Spacer(),
                                    Image.asset(
                                      "assets/arrow.png",
                                      height: 11,
                                      width: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        if (_productDetails!.videoLink == null ||
                            _productDetails!.videoLink!.isEmpty) {
                          ToastComponent.showDialog(
                            AppLocalizations.of(context)!.video_not_available,
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return VideoDescription(
                                url: _productDetails!.videoLink![0],
                              );
                            },
                          ),
                        ).then((value) {
                          onPopped(value);
                        });
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              spreadRadius: 0,
                              blurRadius: 16,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            18.0,
                            14.0,
                            18.0,
                            14.0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.video_ucf,
                                style: TextStyle(
                                  color: Color(0xff3E4447),
                                  fontSize: 13,
                                  fontFamily: 'Public Sans',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              Image.asset(
                                "assets/arrow.png",
                                color: Color(0xff6B7377),
                                height: 11,
                                width: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return ProductReviews(id: _productDetails!.id);
                            },
                          ),
                        ).then((value) {
                          onPopped(value);
                        });
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              spreadRadius: 0,
                              blurRadius: 16,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            18.0,
                            14.0,
                            18.0,
                            14.0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.reviews_ucf,
                                style: TextStyle(
                                  color: Color(0xff3E4447),
                                  fontFamily: 'Public Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              Image.asset(
                                "assets/arrow.png",
                                height: 11,
                                width: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18.0, 22.0, 18.0, 0.0),
                    child: Text(
                      AppLocalizations.of(context)!.products_you_may_also_like,
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  buildProductsMayLikeList(),
                ]),
              ),

              //Top selling product
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 0.0),
                    child: Text(
                      AppLocalizations.of(context)!.top_selling_products_ucf,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
                    child: buildTopSellingProductList(),
                  ),
                  Container(height: 83),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSellerRow(BuildContext context) {
    return Container(
      color: Color(0xffF6F7F8),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _productDetails!.addedBy == "admin"
              ? Container()
              : InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SellerDetails(
                          slug: _productDetails?.shopSlug ?? "",
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: app_language_rtl.$!
                        ? EdgeInsets.only(left: 8.0)
                        : EdgeInsets.only(right: 8.0),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: Color.fromRGBO(112, 112, 112, 0.298),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6.0),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/placeholder.png',
                          image: _productDetails!.shopLogo!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
          SizedBox(
            width: MediaQuery.of(context).size.width * (.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.seller_ucf,
                  style: TextStyle(
                    color: Color(0xff6B7377),
                    fontFamily: 'Public Sans',
                    fontSize: 10,
                  ),
                ),
                Text(
                  _productDetails!.shopName!,
                  style: TextStyle(
                    color: Color(0xff3E4447),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          Visibility(
            visible: conversation_system_status.$,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36.0),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 20,
                    spreadRadius: 0.0,
                    offset: Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (!is_logged_in.$) {
                        ToastComponent.showDialog(
                          LangText(context).local.you_need_to_log_in,
                        );
                        return;
                      }

                      onTapSellerChat();
                    },
                    child: Image.asset(
                      'assets/chat.png',
                      height: 16,
                      width: 16,
                      color: Color(0xff6B7377),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTotalPriceRow() {
    return Container(
      height: 40,
      color: Color(0xffFEF0D7),
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Padding(
            padding: app_language_rtl.$!
                ? EdgeInsets.only(left: 8.0)
                : EdgeInsets.only(right: 8.0),
            child: SizedBox(
              width: 75,
              child: Text(
                AppLocalizations.of(context)!.total_price_ucf,
                style: TextStyle(color: Color(0xff6B7377), fontSize: 10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text(
              SystemConfig.systemCurrency != null
                  ? _totalPrice.toString().replaceAll(
                      SystemConfig.systemCurrency!.code!,
                      SystemConfig.systemCurrency!.symbol!,
                    )
                  : SystemConfig.systemCurrency!.symbol! +
                        _totalPrice.toString(),
              style: TextStyle(
                color: MyTheme.accent_color,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextEditingController quantityText = TextEditingController(text: "0");

  Padding buildVariantShimmers() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 8.0, 0.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0,
                    width: 60,
                  ),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0,
                    width: 60,
                  ),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0,
                    width: 60,
                  ),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0,
                    width: 60,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0,
                    width: 60,
                  ),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0,
                    width: 60,
                  ),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0,
                    width: 60,
                  ),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0,
                    width: 60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  buildChoiceOptionList() {
    return ListView.builder(
      itemCount: _productDetails!.choiceOptions!.length,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: buildChoiceOpiton(_productDetails!.choiceOptions, index),
        );
      },
    );
  }

  buildChoiceOpiton(choiceOptions, choiceOptionsIndex) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 14.0, 0.0, 0.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: app_language_rtl.$!
                ? EdgeInsets.only(left: 8.0)
                : EdgeInsets.only(right: 8.0),
            child: SizedBox(
              width: 75,
              child: Text(
                choiceOptions[choiceOptionsIndex].title,
                style: TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
              ),
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width - (107 + 45),
            child: Scrollbar(
              controller: _variantScrollController,
              child: Wrap(
                children: List.generate(
                  choiceOptions[choiceOptionsIndex].options.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      width: 75,
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: buildChoiceItem(
                        choiceOptions[choiceOptionsIndex].options[index],
                        choiceOptionsIndex,
                        index,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  buildChoiceItem(option, choiceOptionsIndex, index) {
    return Padding(
      padding: app_language_rtl.$!
          ? EdgeInsets.only(left: 8.0)
          : EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          _onVariantChange(choiceOptionsIndex, option);
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedChoices[choiceOptionsIndex] == option
                  ? MyTheme.accent_color
                  : MyTheme.noColor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(3.0),
            color: MyTheme.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                spreadRadius: 1,
                offset: Offset(0.0, 3.0),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 3.0,
            ),
            child: Center(
              child: Text(
                option,
                style: TextStyle(
                  color: _selectedChoices[choiceOptionsIndex] == option
                      ? MyTheme.accent_color
                      : Color.fromRGBO(224, 224, 225, 1),
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  buildColorRow() {
    return Row(
      children: [
        Padding(
          padding: app_language_rtl.$!
              ? EdgeInsets.only(left: 8.0)
              : EdgeInsets.only(right: 8.0),
          child: SizedBox(
            width: 75,
            child: Text(
              AppLocalizations.of(context)!.color_ucf,
              style: TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
            ),
          ),
        ),
        Container(
          alignment: app_language_rtl.$!
              ? Alignment.centerRight
              : Alignment.centerLeft,
          height: 40,
          width: MediaQuery.of(context).size.width - (107 + 44),
          child: Scrollbar(
            controller: _colorScrollController,
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return SizedBox(width: 10);
              },
              itemCount: _colorList.length,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [buildColorItem(index)],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget buildColorItem(index) {
    return InkWell(
      onTap: () {
        _onColorChange(index);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        width: _selectedColorIndex == index ? 28 : 20,
        height: _selectedColorIndex == index ? 28 : 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: ColorHelper.getColorFromColorCode(_colorList[index]),
          boxShadow: [
            _selectedColorIndex == index
                ? BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _selectedColorIndex == index ? 0.25 : 0.12,
                    ),
                    blurRadius: 10,
                    spreadRadius: 2.0,
                    offset: Offset(0.0, 6.0),
                  )
                : BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _selectedColorIndex == index ? 0.25 : 0.16,
                    ),
                    blurRadius: 6,
                    spreadRadius: 0.0,
                    offset: Offset(0.0, 3.0),
                  ),
          ],
        ),
        child: _selectedColorIndex == index
            ? buildColorCheckerContainer()
            : Container(height: 25),
      ),
    );
  }

  buildColorCheckerContainer() {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Image.asset("assets/white_tick.png", width: 16, height: 16),
    );
  }

  Widget buildWholeSaleQuantityPrice() {
    return DataTable(
      columnSpacing: DeviceInfo(context).width! * 0.125,

      columns: [
        DataColumn(
          label: Text(
            LangText(context).local.min_qty_ucf,
            style: TextStyle(fontSize: 12, color: MyTheme.dark_grey),
          ),
        ),
        DataColumn(
          label: Text(
            LangText(context).local.max_qty_ucf,
            style: TextStyle(fontSize: 12, color: MyTheme.dark_grey),
          ),
        ),
        DataColumn(
          label: Text(
            LangText(context).local.unit_price_ucf,
            style: TextStyle(fontSize: 12, color: MyTheme.dark_grey),
          ),
        ),
      ],
      rows: List<DataRow>.generate(_productDetails!.wholesale!.length, (index) {
        return DataRow(
          cells: <DataCell>[
            DataCell(
              Text(
                _productDetails!.wholesale![index].minQty.toString(),
                style: TextStyle(
                  color: Color.fromRGBO(152, 152, 153, 1),
                  fontSize: 12,
                ),
              ),
            ),
            DataCell(
              Text(
                _productDetails!.wholesale![index].maxQty.toString(),
                style: TextStyle(
                  color: Color.fromRGBO(152, 152, 153, 1),
                  fontSize: 12,
                ),
              ),
            ),
            DataCell(
              Text(
                convertPrice(
                  _productDetails!.wholesale![index].price.toString(),
                ),
                style: TextStyle(
                  color: Color.fromRGBO(152, 152, 153, 1),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget buildClubPointRow() {
    return Container(
      constraints: BoxConstraints(maxWidth: 120),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        color: Color(0xffFFF4E8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset("assets/clubpoint.png", width: 18, height: 12),
                SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.club_point_ucf,
                  style: TextStyle(
                    color: Color(0xff6B7377),
                    fontSize: 10,
                    fontFamily: 'Public Sans',
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            Text(
              _productDetails!.earnPoint.toString(),
              style: TextStyle(color: Color(0xffF7941D), fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  }

  Row buildMainPriceRow() {
    return Row(
      children: [
        Text(
          SystemConfig.systemCurrency != null
              ? _singlePriceString.replaceAll(
                  SystemConfig.systemCurrency!.code,
                  SystemConfig.systemCurrency!.symbol,
                )
              : _singlePriceString,

          style: TextStyle(
            color: Color(0xffE62E04),
            fontFamily: 'Public Sans',
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Visibility(
          visible: _productDetails!.hasDiscount!,
          child: Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(
              SystemConfig.systemCurrency != null
                  ? _productDetails!.strokedPrice!.replaceAll(
                      SystemConfig.systemCurrency!.code!,
                      SystemConfig.systemCurrency!.symbol!,
                    )
                  : _productDetails!.strokedPrice!,
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Color(0xffA8AFB3),
                fontFamily: 'Public Sans',
                fontSize: 12.0,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
        Visibility(
          visible: _productDetails!.hasDiscount!,
          child: Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(
              "${_productDetails!.discount}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Text(
          "/${_productDetails!.unit}",
          // _singlePriceString,
          style: TextStyle(
            color: MyTheme.accent_color,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  AppBar buildAppBar(double statusBarHeight, BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: SizedBox(
        height:
            kToolbarHeight +
            statusBarHeight -
            (MediaQuery.of(context).viewPadding.top > 40 ? 32.0 : 16.0),

        child: SizedBox(
          width: 300,
          child: Padding(
            padding: const EdgeInsets.only(top: 22.0),
            child: Text(
              _appbarPriceString!,
              style: TextStyle(fontSize: 16, color: MyTheme.font_grey),
            ),
          ),
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          child: IconButton(
            icon: Icon(Icons.share_outlined, color: MyTheme.dark_grey),
            onPressed: () {
              onPressShare(context);
            },
          ),
        ),
      ],
    );
  }

  Widget buildBottomAppBar(BuildContext context, addedToCartSnackbar) {
    return BottomNavigationBar(
      backgroundColor: MyTheme.white.withValues(alpha: 0.9),
      items: [
        BottomNavigationBarItem(
          backgroundColor: Colors.transparent,
          label: '',
          icon: InkWell(
            onTap: () {
              onPressAddToCart(context, addedToCartSnackbar);
            },
            child: Container(
              margin: EdgeInsets.only(left: 23, right: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                color: MyTheme.accent_color,
                boxShadow: [
                  BoxShadow(
                    color: MyTheme.accent_color_shadow,
                    blurRadius: 20,
                    spreadRadius: 0.0,
                    offset: Offset(0.0, 10.0),
                  ),
                ],
              ),
              height: 50,
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.add_to_cart_ucf,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        BottomNavigationBarItem(
          label: "",
          icon: InkWell(
            onTap: () {
              onPressBuyNow(context);
            },
            child: Container(
              margin: EdgeInsets.only(left: 14, right: 23),
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                color: MyTheme.golden,
                boxShadow: [
                  BoxShadow(
                    color: MyTheme.golden_shadow,
                    blurRadius: 20,
                    spreadRadius: 0.0,
                    offset: Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.buy_now_ucf,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  buildRatingAndWishButtonRow() {
    return Row(
      children: [
        RatingBar(
          itemSize: 15.0,
          ignoreGestures: true,
          initialRating: double.parse(_productDetails!.rating.toString()),
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          ratingWidget: RatingWidget(
            full: Icon(Icons.star, color: Colors.amber),
            half: Icon(Icons.star_half, color: Colors.amber),
            empty: Icon(Icons.star, color: Color.fromRGBO(224, 224, 225, 1)),
          ),
          itemPadding: EdgeInsets.only(right: 1.0),
          onRatingUpdate: (rating) {},
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "(${_productDetails!.ratingCount})",
            style: TextStyle(
              color: Color.fromRGBO(152, 152, 153, 1),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  buildShippingTime() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            LangText(context).local.estimate_shipping_time_ucf,
            style: TextStyle(
              color: Color.fromRGBO(152, 152, 153, 1),
              fontSize: 10,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "${_productDetails!.estShippingTime}  ${LangText(context).local.days_ucf}",
            style: TextStyle(
              color: Color.fromRGBO(152, 152, 153, 1),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  buildBrandRow() {
    return _productDetails!.brand!.id! > 0
        ? InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return BrandProducts(slug: _productDetails!.brand!.slug!);
                  },
                ),
              );
            },
            child: Row(
              children: [
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0)
                      : EdgeInsets.only(right: 8.0),
                  child: SizedBox(
                    width: 75,
                    child: Text(
                      AppLocalizations.of(context)!.brand_ucf,
                      style: TextStyle(
                        color: Color(0xff6B7377),
                        fontSize: 10,
                        fontFamily: 'Public Sans',
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    _productDetails!.brand!.name!,
                    style: TextStyle(
                      color: Color(0xff3E4447),
                      fontFamily: 'Public Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          )
        : Container();
  }

  buildExpandableDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: DeviceInfo(context).width,
          height: webViewHeight,
          child: WebViewWidget(controller: controller),
        ),
        Btn.basic(
          onPressed: () async {
            if (webViewHeight == 50) {
              webViewHeight = double.parse(
                (await controller.runJavaScriptReturningResult(
                  "document.getElementById('scaled-frame').clientHeight",
                )).toString(),
              );
            } else {
              webViewHeight = 50;
            }
            setState(() {});
          },
          child: Text(
            webViewHeight == 50
                ? LangText(context).local.view_more
                : LangText(context).local.less,
            style: TextStyle(color: Color(0xff0077B6)),
          ),
        ),
      ],
    );
  }

  buildTopSellingProductList() {
    if (_topProductInit == false && _topProducts.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ShimmerHelper().buildBasicShimmer(height: 75.0),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ShimmerHelper().buildBasicShimmer(height: 75.0),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ShimmerHelper().buildBasicShimmer(height: 75.0),
          ),
        ],
      );
    } else if (_topProducts.isNotEmpty) {
      return SingleChildScrollView(
        child: ListView.separated(
          separatorBuilder: (context, index) => SizedBox(height: 16),
          itemCount: _topProducts.length,
          scrollDirection: Axis.vertical,
          padding: EdgeInsets.only(top: 16),
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return TopSellingProductsCard(
              id: _topProducts[index].id,
              slug: _topProducts[index].slug,
              image: _topProducts[index].thumbnail_image,
              name: _topProducts[index].name,
              mainPrice: _topProducts[index].main_price,
              strokedPrice: _topProducts[index].stroked_price,
              hasDiscount: _topProducts[index].has_discount,
            );
          },
        ),
      );
    } else {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(
              context,
            )!.no_top_selling_products_from_this_seller,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    }
  }

  buildProductsMayLikeList() {
    if (_relatedProductInit == false && _relatedProducts.isEmpty) {
      return Row(
        children: [
          Padding(
            padding: app_language_rtl.$!
                ? EdgeInsets.only(left: 8.0)
                : EdgeInsets.only(right: 8.0),
            child: ShimmerHelper().buildBasicShimmer(
              height: 120.0,
              width: (MediaQuery.of(context).size.width - 32) / 3,
            ),
          ),
          Padding(
            padding: app_language_rtl.$!
                ? EdgeInsets.only(left: 8.0)
                : EdgeInsets.only(right: 8.0),
            child: ShimmerHelper().buildBasicShimmer(
              height: 120.0,
              width: (MediaQuery.of(context).size.width - 32) / 3,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 0.0),
            child: ShimmerHelper().buildBasicShimmer(
              height: 120.0,
              width: (MediaQuery.of(context).size.width - 32) / 3,
            ),
          ),
        ],
      );
    } else if (_relatedProducts.isNotEmpty) {
      return SingleChildScrollView(
        child: SizedBox(
          height: 248,
          child: ListView.separated(
            separatorBuilder: (context, index) => SizedBox(width: 16),
            padding: const EdgeInsets.all(16),
            itemCount: _relatedProducts.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return MiniProductCard(
                id: _relatedProducts[index].id,
                slug: _relatedProducts[index].slug,
                image: _relatedProducts[index].thumbnailImage,
                name: _relatedProducts[index].name,
                mainPrice: _relatedProducts[index].mainPrice,
                strokedPrice: _relatedProducts[index].strokedPrice,
                isWholesale: _relatedProducts[index].isWholesale,
                discount: _relatedProducts[index].discount,
                hasDiscount: _relatedProducts[index].hasDiscount ?? false,
              );
            },
          ),
        ),
      );
    } else {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_related_product,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    }
  }

  buildQuantityUpButton() => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.16),
          blurRadius: 6,
          spreadRadius: 0.0,
          offset: Offset(0.0, 3.0),
        ),
      ],
    ),
    width: 36,
    child: IconButton(
      icon: Icon(Icons.add, size: 16, color: MyTheme.dark_grey),
      onPressed: () {
        if (_quantity! < _stock!) {
          _quantity = (_quantity!) + 1;
          setState(() {});

          fetchAndSetVariantWiseInfo();
        }
      },
    ),
  );

  buildQuantityDownButton() => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.16),
          blurRadius: 6,
          spreadRadius: 0.0,
          offset: Offset(0.0, 3.0),
        ),
      ],
    ),
    width: 30,
    child: IconButton(
      icon: Center(
        child: Icon(Icons.remove, size: 16, color: Color(0xff707070)),
      ),
      onPressed: () {
        if (_quantity! > 1) {
          _quantity = _quantity! - 1;
          setState(() {});

          fetchAndSetVariantWiseInfo();
        }
      },
    ),
  );

  buildProductImageSection() {
    if (_productImageList.isEmpty) {
      return Row(
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 40.0,
                    width: 40.0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 40.0,
                    width: 40.0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 40.0,
                    width: 40.0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 40.0,
                    width: 40.0,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: ShimmerHelper().buildBasicShimmer(height: 190.0),
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 250,
            width: 64,
            child: Scrollbar(
              controller: _imageScrollController,
              thumbVisibility: false,
              thickness: 4.0,
              child: Padding(
                padding: app_language_rtl.$!
                    ? EdgeInsets.only(left: 8.0)
                    : EdgeInsets.only(right: 8.0),
                child: ListView.builder(
                  itemCount: _productImageList.length,
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    int itemIndex = index;
                    return GestureDetector(
                      onTap: () {
                        _currentImage = itemIndex;

                        setState(() {});
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        margin: EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 2.0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _currentImage == itemIndex
                                ? MyTheme.accent_color
                                : Color.fromRGBO(112, 112, 112, .3),
                            width: _currentImage == itemIndex ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: FadeInImage.assetNetwork(
                            placeholder: 'assets/placeholder.png',
                            image: _productImageList[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              openPhotoDialog(context, _productImageList[_currentImage]);
            },
            child: SizedBox(
              height: 250,
              width: MediaQuery.of(context).size.width - 96,
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/placeholder_rectangle.png',
                image: _productImageList[_currentImage],
                fit: BoxFit.scaleDown,
              ),
            ),
          ),
        ],
      );
    }
  }

  openPhotoDialog(BuildContext context, path) => showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: Stack(
          children: [
            PhotoView(
              enableRotation: true,
              heroAttributes: const PhotoViewHeroAttributes(tag: "someTag"),
              imageProvider: NetworkImage(path),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Container(
                decoration: ShapeDecoration(
                  color: MyTheme.medium_grey_50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                      topRight: Radius.circular(25),
                      topLeft: Radius.circular(25),
                    ),
                  ),
                ),
                width: 40,
                height: 40,
                child: IconButton(
                  icon: Icon(Icons.clear, color: MyTheme.white),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  String makeHtml(String string) {
    return """
<!DOCTYPE html>
<html>

<head>

<meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="${AppConfig.RAW_BASE_URL}/public/assets/css/vendors.css">
  <style>
  *{
  margin:0 !important;
  padding:0 !important;
  }

    #scaled-frame {
    }
  </style>
</head>

<body id="main_id">
  <div id="scaled-frame">
$string
  </div>
</body>

</html>
""";
  }
}
