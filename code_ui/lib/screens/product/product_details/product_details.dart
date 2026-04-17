// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:async';
import 'package:active_ecommerce_cms_demo_app/screens/product/product_details/widget_for_product_details/product_media.dart';
import 'package:active_ecommerce_cms_demo_app/screens/product/product_details/widget_for_product_details/product_media_slider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../custom/box_decorations.dart';
import '../../../custom/btn.dart';
import '../../../custom/device_info.dart';
import '../../../custom/lang_text.dart';
import '../../../custom/quantity_input.dart';
import '../../../custom/toast_component.dart';
import '../../../data_model/product_details_response.dart';
import '../../../helpers/color_helper.dart';
import '../../../helpers/main_helpers.dart';
import '../../../helpers/shared_value_helper.dart';
import '../../../helpers/shimmer_helper.dart';
import '../../../helpers/system_config.dart';
import '../../../my_theme.dart';
import '../../../presenter/cart_counter.dart';
import '../../../repositories/cart_repository.dart';
import '../../../repositories/chat_repository.dart';
import '../../../repositories/product_repository.dart';
import '../../../repositories/wishlist_repository.dart';
import '../../../ui_elements/mini_product_card.dart';
import '../../brand_products.dart';
import '../../chat/chat.dart';
import '../../checkout/cart.dart';
import '../../seller_details.dart';
import '../product_reviews.dart';
import '../widgets/tappable_icon_widget.dart';

class ProductDetails extends StatefulWidget {
  final String slug;

  const ProductDetails({super.key, required this.slug});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails>
    with TickerProviderStateMixin {
  bool _showCopied = false;
  String? _appbarPriceString = ". . .";
  int _currentImage = 0;
  final ScrollController _mainScrollController = ScrollController(
    initialScrollOffset: 0.0,
  );
  final ScrollController _colorScrollController = ScrollController();
  final ScrollController _variantScrollController = ScrollController();
  TextEditingController sellerChatTitleController = TextEditingController();
  TextEditingController sellerChatMessageController = TextEditingController();

  double _scrollPosition = 0.0;

  WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..enableZoom(false);
  double webViewHeight = 50.0.h;

  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final List<ProductMedia> _mediaList = [];

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

  var _singlePriceString;
  int? _quantity = 1;
  int? _stock = 0;
  var _stockTxt;

  double opacity = 0;

  final List<dynamic> _relatedProducts = [];
  bool _relatedProductInit = false;
  final List<dynamic> _topProducts = [];
  bool _topProductInit = false;

  String formatPrice(String? price) {
    if (price == null || price.isEmpty) return '';

    if (SystemConfig.systemCurrency != null) {
      return price.replaceAll(
        SystemConfig.systemCurrency!.code!,
        SystemConfig.systemCurrency!.symbol!,
      );
    }
    return price;
  }


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
      _mediaList.clear();

      if (_productDetails!.photos != null) {
        for (var photo in _productDetails!.photos!) {
          _mediaList.add(ProductMedia(type: 'image', url: photo.path!));
        }
      }
      if (_productDetails!.videos != null) {
        for (var video in _productDetails!.videos!) {
          String? thumbnail = video.thumbnail;
          if (thumbnail == null || thumbnail.isEmpty) {
            thumbnail = _productDetails!.thumbnailImage;
          }
          _mediaList.add(
            ProductMedia(
              type: 'hosted_video',
              url: video.path!,
              thumbnail: video.thumbnail,
            ),
          );
        }
      }
      if (_productDetails!.videoLink != null) {
        for (var ytLink in _productDetails!.videoLink!) {
          String? videoId = YoutubePlayer.convertUrlToId(ytLink);
          if (videoId != null && videoId.isNotEmpty) {
            bool isShort = ytLink.toString().contains('/shorts/');
            _mediaList.add(
              ProductMedia(
                type: 'youtube_video',
                url: ytLink,
                thumbnail: YoutubePlayer.getThumbnail(videoId: videoId),
                isShort: isShort,
              ),
            );
          }
        }
      }

      for (var choiceOpiton in _productDetails!.choiceOptions!) {
        _selectedChoices.add(choiceOpiton.options![0]);
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
    _stockTxt = variantResponse.variantData!.stockTxt;
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
        if (_mediaList.isNotEmpty) {
          _carouselController.jumpToPage(pindex);
        }
      }
      pindex++;
    });
    setQuantity(_quantity);
    setState(() {});
  }

  reset() {
    restProductDetailValues();
    _mediaList.clear();
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
    _mediaList.clear();
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
    addToCart(mode: "add_to_cart", context: context, snackbar: snackbar);
  }

  onPressBuyNow(context) {
    addToCart(mode: "buy_now", context: context);
  }

  Future<void> addToCart({
    required String mode,
    required BuildContext context,
    SnackBar? snackbar,
  }) async {
    loading();
    // login check
    if (!guest_checkout_status.$ && is_logged_in.$ == false) {
      context.go("/users/login");
      return;
    }

    final cartAddResponse = await CartRepository().getCartAddResponse(
      _productDetails!.id,
      _variant,
      user_id.$,
      _quantity,
    );

    if (!context.mounted) return;
    Navigator.of(loadingcontext).pop();

    temp_user_id.$ = cartAddResponse.tempUserId;
    temp_user_id.save();

    if (cartAddResponse.result == false) {
      ToastComponent.showDialog(cartAddResponse.message);
      return;
    }

    // cart counter update
    Provider.of<CartCounter>(context, listen: false).getCount();

    if (mode == "add_to_cart") {
      if (snackbar != null) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(snackbar);
      }

      reset();
      fetchAll();
    } else if (mode == "buy_now") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Cart(hasBottomnav: false)),
      ).then(onPopped);
    } else if (mode == "buy_now") {
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

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),

              backgroundColor: MyTheme.white,
              insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
              contentPadding: EdgeInsets.only(
                top: 36.0.h,
                left: 36.0.w,
                right: 36.0.w,
                bottom: 2.0.h,
              ),
              content: SizedBox(
                width: 400.w,
                child: SingleChildScrollView(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.0.h),
                          child: GestureDetector(
                            onTap: () {
                              onCopyTap(setState);

                              final link = _productDetails?.link;
                              if (link == null || link.isEmpty) return;

                              Clipboard.setData(ClipboardData(text: link));
                            },
                            child: Container(
                              width: 160.w,
                              height: 40.h,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(253, 253, 253, 1),
                                borderRadius: BorderRadius.circular(8.0.r),
                                border: Border.all(
                                  color:  MyTheme.light_grey,
                                  width: 1.0,
                                ),
                              ),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(opacity: animation, child: child),

                                  child: _showCopied
                                      ? Row(
                                    key: const ValueKey('copied'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check,
                                        color: Colors.green,
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        AppLocalizations.of(context)!.copied_ucf,
                                        style: TextStyle(
                                          color: MyTheme.medium_grey,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                      : Row(
                                    key: const ValueKey('copy'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.copy,
                                        color: MyTheme.medium_grey,
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        AppLocalizations.of(context)!.copy_product_link_ucf,
                                        style: TextStyle(
                                          color: MyTheme.medium_grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        ),

                        Padding(
                          padding: EdgeInsets.only(bottom: 8.0.h),
                          child: GestureDetector(
                            onTap: () {
                              Share.share(_productDetails!.link!);
                            },
                            child: Container(
                              width: 160.w,
                              height: 40.h,

                              decoration: BoxDecoration(
                                color: MyTheme.accent_color,
                                borderRadius: .circular(8.0.r),

                              ),
                              padding: .fromLTRB(10.w, 0, 5.w, 0),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.arrowshape_turn_up_right,
                                    color: Colors.white,
                                    size: 18.sp,
                                  ),
                                  SizedBox(width: 5.w),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.share_options_ucf,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding: app_language_rtl.$!
                          ? EdgeInsets.only(left: 8.0.w)
                          : EdgeInsets.only(right: 8.0.w),
                      child: Btn.minWidthFixHeight(
                        minWidth: 75.w,
                        height: 30.h,
                        color: Color.fromRGBO(253, 253, 253, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0.r),
                          side: BorderSide(
                            color:  MyTheme.light_grey,
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
          backgroundColor: MyTheme.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
          contentPadding: EdgeInsets.only(
            top: 36.0.h,
            left: 36.0.w,
            right: 36.0.w,
            bottom: 2.0.h,
          ),
          content: SizedBox(
            width: 400.w,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0.h),
                    child: Text(
                      AppLocalizations.of(context)!.title_ucf,
                      style: TextStyle(
                        color: MyTheme.font_grey,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 16.0.h),
                    child: SizedBox(
                      height: 40.h,
                      child: TextField(
                        controller: sellerChatTitleController,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(
                            context,
                          )!.enter_title_ucf,
                          hintStyle: TextStyle(
                            fontSize: 12.0.sp,
                            color: MyTheme.textfield_grey,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: MyTheme.textfield_grey,
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.all(
                              Radius.circular(8.0.r),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: MyTheme.textfield_grey,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.all(
                              Radius.circular(8.0.r),
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.0.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0.h),
                    child: Text(
                      "${AppLocalizations.of(context)!.message_ucf} *",
                      style: TextStyle(
                        color: MyTheme.font_grey,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 16.0.h),
                    child: TextField(
                      controller: sellerChatMessageController,
                      autofocus: false,
                      minLines: 3,
                      maxLines: 7,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        )!.enter_message_ucf,
                        hintStyle: TextStyle(
                          fontSize: 12.0.sp,
                          color: MyTheme.textfield_grey,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: MyTheme.textfield_grey,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0.r),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: MyTheme.textfield_grey,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0.r),
                          ),
                        ),
                        contentPadding: EdgeInsets.only(
                          right: 16.0.w,
                          left: 8.0.w,
                          top: 16.0.h,
                          bottom: 16.0.h,
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
                Expanded(
                  child: Btn.minWidthFixHeight(
                    minWidth: 75.w,
                    height: 30.h,
                    color: Color.fromRGBO(253, 253, 253, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0.r),
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
                SizedBox(width: 10.w),
                Expanded(
                  child: Btn.minWidthFixHeight(
                    minWidth: 75.w,
                    height: 30.h,
                    color: MyTheme.accent_color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0.r),
                      side: BorderSide(color: MyTheme.light_grey, width: 1.0),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.send_all_capital,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
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
              SizedBox(width: 10.w),
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
      backgroundColor: MyTheme.soft_accent_color,
      behavior: SnackBarBehavior.fixed,
      duration: const Duration(milliseconds: 1200),
      padding: EdgeInsets.zero,
      content: Container(
        height: 80.h,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: .start,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.added_to_cart,
                    style: TextStyle(color: MyTheme.font_grey, fontSize: 13.sp),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => Cart(hasBottomnav: true)),
                );
              },
              child: Text(
                AppLocalizations.of(context)!.show_cart_all_capital,
                style: TextStyle(
                  color: MyTheme.accent_color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        ),
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
          displacement: 10.0,
          edgeOffset: 0,
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
                stretch: true,
                automaticallyImplyLeading: false,
                expandedHeight: 355.0.h,
                title: AnimatedOpacity(
                  opacity: _scrollPosition > 250 ? 1 : 0,
                  duration: Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: _scrollPosition <= 250,
                    child: Container(
                      padding: EdgeInsets.only(left: 8.w),
                      width: DeviceInfo(context).width! / 2,
                      child: Text(
                        "${_productDetails != null ? _productDetails!.name : ''}",
                        style: TextStyle(
                          color: MyTheme.dark_font_grey,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [],
                  background: Stack(
                    children: [
                      // Product Slider
                      Positioned.fill(
                        child: ProductMediaSlider(
                          onPurchase: () {
                            onPressBuyNow(context);
                          },
                          price:  formatPrice(_singlePriceString),

                          mediaList: _mediaList,
                          carouselController: _carouselController,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: 48.h,
                          left: 33.w,
                          right: 33.w,
                        ),
                        child: Row(
                          children: [
                            Builder(
                              builder: (context) => SizedBox(
                                width: 40.w,
                                height: 40.h,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20.r),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Center(
                                    child: Container(
                                      decoration:
                                          BoxDecorations.buildCircularButtonDecorationForProductDetails(),
                                      width: 36.w,
                                      height: 36.h,
                                      child: Center(
                                        child: Icon(
                                          CupertinoIcons.arrow_left,
                                          color: MyTheme.dark_font_grey,
                                          size: 20.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
                                width: 32.w,
                                height: 32.h,
                                padding: EdgeInsets.all(2.r),
                                child: badges.Badge(
                                  position: badges.BadgePosition.topEnd(
                                    top: -6.h,
                                    end: -6.w,
                                  ),
                                  badgeStyle: badges.BadgeStyle(
                                    shape: badges.BadgeShape.circle,
                                    badgeColor: MyTheme.accent_color,
                                    borderRadius: BorderRadius.circular(10.r),
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
                                          fontSize: 12.sp,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      "assets/cart.png",
                                      color: MyTheme.dark_font_grey,
                                      height: 16.h,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 15.w),
                            InkWell(
                              onTap: () {
                                onPressShare(context);
                              },
                              child: TappableIconWidget(
                                icon: Icons.share_outlined,
                                color: MyTheme.dark_font_grey,
                              ),
                            ),
                            SizedBox(width: 15.w),
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
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.r),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .08),
                          blurRadius: 20.r,
                          spreadRadius: 0.0,
                          offset: Offset(0.0, 0.0),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(14.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              //product name
                              _productDetails != null
                                  ? Text(
                                      _productDetails!.name!,
                                      style: TextStyle(
                                        color: Color(0xff3E4447),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Public Sans',
                                        fontSize: 13.sp,
                                      ),
                                      maxLines: 2,
                                    )
                                  : ShimmerHelper().buildBasicShimmer(
                                      height: 30.0.h,
                                    ),
                              SizedBox(height: 13.h),
                              _productDetails != null
                                  ? buildRatingAndWishButtonRow()
                                  : ShimmerHelper().buildBasicShimmer(
                                      height: 30.0.h,
                                    ),
                              if (_productDetails != null &&
                                  _productDetails!.estShippingTime != null &&
                                  _productDetails!.estShippingTime! > 0)
                                _productDetails != null
                                    ? buildShippingTime()
                                    : ShimmerHelper().buildBasicShimmer(
                                        height: 30.0.h,
                                      ),
                              SizedBox(height: 12.h),
                              //product price
                              _productDetails != null
                                  ? buildMainPriceRow()
                                  : ShimmerHelper().buildBasicShimmer(
                                      height: 30.0.h,
                                    ),
                              SizedBox(height: 14.h),
                              //club_point
                              Visibility(
                                visible: club_point_addon_installed.$,
                                child: _productDetails != null
                                    ? buildClubPointRow()
                                    : ShimmerHelper().buildBasicShimmer(
                                        height: 30.0.h,
                                      ),
                              ),
                              SizedBox(height: 9.h),
                              //Brand
                              _productDetails != null
                                  ? buildBrandRow()
                                  : ShimmerHelper().buildBasicShimmer(
                                      height: 50.0.h,
                                    ),
                            ],
                          ),
                        ),
                        _productDetails != null
                            ? buildSellerRow(context)
                            : ShimmerHelper().buildBasicShimmer(height: 50.0.h),
                        Padding(
                          padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 0),
                          child: Column(
                            children: [
                              SizedBox(height: 8.h),
                              //variation
                              _productDetails != null
                                  ? buildChoiceOptionList()
                                  : buildVariantShimmers(),

                              _productDetails != null
                                  ? (_colorList.isNotEmpty
                                        ? buildColorRow()
                                        : Container())
                                  : ShimmerHelper().buildBasicShimmer(
                                      height: 30.0.h,
                                    ),
                              SizedBox(height: 10.h),

                              ///whole sale
                              Visibility(
                                visible: whole_sale_addon_installed.$,
                                child: _productDetails != null
                                    ? _productDetails!.wholesale!.isNotEmpty
                                          ? buildWholeSaleQuantityPrice()
                                          : SizedBox.shrink()
                                    : ShimmerHelper().buildBasicShimmer(
                                        height: 30.0.h,
                                      ),
                              ),
                              //quentity
                              _productDetails != null
                                  ? buildQuantityRow()
                                  : ShimmerHelper().buildBasicShimmer(
                                      height: 30.0.h,
                                    ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: _productDetails != null
                              ? buildTotalPriceRow()
                              : ShimmerHelper().buildBasicShimmer(
                                  height: 30.0.h,
                                ),
                        ),
                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),
                ),
              ),

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
                            blurRadius: 16.r,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              16.0.w,
                              20.0.h,
                              16.0.w,
                              0.0,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.description_ucf,
                              style: TextStyle(
                                color: Color(0xff3E4447),
                                fontFamily: 'Public Sans',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          //Expandable Description
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              16.0.w,
                              0.0,
                              8.0.w,
                              8.0.h,
                            ),
                            child: _productDetails != null
                                ? buildExpandableDescription()
                                : Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.0.w,
                                      vertical: 8.0.h,
                                    ),
                                    child: ShimmerHelper().buildBasicShimmer(
                                      height: 60.0.h,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    if (_productDetails?.downloads != null)
                      Column(
                        children: [
                          SizedBox(height: 10.h),
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
                              height: 48.h,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  18.0.w,
                                  14.0.h,
                                  18.0.w,
                                  14.0.h,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.downloads_ucf,
                                      style: TextStyle(
                                        color: MyTheme.dark_font_grey,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Spacer(),
                                    Image.asset(
                                      "assets/arrow.png",
                                      height: 11.h,
                                      width: 20.w,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 10.h),
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
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              spreadRadius: 0,
                              blurRadius: 16.r,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            18.0.w,
                            14.0.h,
                            18.0.w,
                            14.0.h,
                          ),
                          child: Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.reviews_ucf,
                                style: TextStyle(
                                  color: Color(0xff3E4447),
                                  fontFamily: 'Public Sans',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),
                              Image.asset(
                                "assets/arrow.png",
                                height: 11.h,
                                width: 20.w,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_relatedProductInit == true && _relatedProducts.isNotEmpty)
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: EdgeInsets.fromLTRB(18.0.w, 12.0.h, 18.0.w, 0.0),
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.products_you_may_also_like,
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Roboto',
                          fontSize: 18.sp,
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
                    padding: EdgeInsets.fromLTRB(16.0.w, 8.0.h, 16.0.w, 0.0),
                    child: Text(
                      AppLocalizations.of(context)!.top_selling_products_ucf,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.0.w, 0.0, 16.0.w, 0.0),
                    child: buildTopSellingProductList(),
                  ),
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
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
                        ? EdgeInsets.only(left: 8.0.w)
                        : EdgeInsets.only(right: 8.0.w),
                    child: Container(
                      width: 30.w,
                      height: 30.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0.r),
                        border: Border.all(
                          color: Color.fromRGBO(112, 112, 112, 0.298),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6.0.r),
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
                    fontSize: 10.sp,
                  ),
                ),
                Text(
                  _productDetails!.shopName!,
                  style: TextStyle(
                    color: Color(0xff3E4447),
                    fontSize: 10.sp,
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
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36.0.r),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 20.r,
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
                      height: 16.h,
                      width: 16.w,
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
      height: 35.h,
      color: Color(0xffFEF0D7),
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        children: [
          Padding(
            padding: app_language_rtl.$!
                ? EdgeInsets.only(left: 8.0.w)
                : EdgeInsets.only(right: 8.0.w),
            child: SizedBox(
              width: 75.w,
              child: Text(
                AppLocalizations.of(context)!.total_price_ucf,
                style: TextStyle(color: Color(0xff6B7377), fontSize: 10.sp),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 5.0.w),
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
                fontSize: 16.0.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Row buildQuantityRow() {
    return Row(
      children: [
        Padding(
          padding: app_language_rtl.$!
              ? EdgeInsets.only(left: 8.0.w)
              : EdgeInsets.only(right: 8.0.w),
          child: SizedBox(
            width: 75.w,
            child: Text(
              AppLocalizations.of(context)!.quantity_ucf,
              style: TextStyle(
                color: Color(0xff6B7377),
                fontFamily: 'Public Sans',
              ),
            ),
          ),
        ),
        SizedBox(
          height: 30.h,
          width: 120.w,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              buildQuantityDownButton(),
              SizedBox(width: 1.w),
              SizedBox(
                width: 30.w,
                child: Center(
                  child: QuantityInputField.show(
                    quantityText,
                    isDisable: _quantity == 0,
                    onSubmitted: () {
                      _quantity = int.parse(quantityText.text);

                      fetchAndSetVariantWiseInfo();
                    },
                  ),
                ),
              ),
              buildQuantityUpButton(),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0.w),
          child: Text(
            "$_stockTxt",
            style: TextStyle(color: Color(0xff6B7377), fontSize: 14.sp),
          ),
        ),
      ],
    );
  }

  TextEditingController quantityText = TextEditingController(text: "0");

  Padding buildVariantShimmers() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.0.w, 0.0, 8.0.w, 0.0),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 8.0.h),
            child: Row(
              children: [
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0.w)
                      : EdgeInsets.only(right: 8.0.w),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0.h,
                    width: 60.w,
                  ),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0.w)
                      : EdgeInsets.only(right: 8.0.w),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0.h,
                    width: 60.w,
                  ),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0.w)
                      : EdgeInsets.only(right: 8.0.w),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0.h,
                    width: 60.w,
                  ),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0.w)
                      : EdgeInsets.only(right: 8.0.w),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0.h,
                    width: 60.w,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 8.0.h),
            child: Row(
              children: [
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0.w)
                      : EdgeInsets.only(right: 8.0.w),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0.h,
                    width: 60.w,
                  ),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0.w)
                      : EdgeInsets.only(right: 8.0.w),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0.h,
                    width: 60.w,
                  ),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0.w)
                      : EdgeInsets.only(right: 8.0.w),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0.h,
                    width: 60.w,
                  ),
                ),
                Padding(
                  padding: app_language_rtl.$!
                      ? EdgeInsets.only(left: 8.0.w)
                      : EdgeInsets.only(right: 8.0.w),
                  child: ShimmerHelper().buildBasicShimmer(
                    height: 30.0.h,
                    width: 60.w,
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
        return buildChoiceOpiton(_productDetails!.choiceOptions, index);
      },
    );
  }

  buildChoiceOpiton(choiceOptions, choiceOptionsIndex) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, 4.0.h, 0.0, 0.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: app_language_rtl.$!
                ? EdgeInsets.only(left: 8.0.w)
                : EdgeInsets.only(right: 8.0.w),
            child: SizedBox(
              width: 75.w,
              child: Text(
                choiceOptions[choiceOptionsIndex].title,
                style: const TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
              ),
            ),
          ),
          SizedBox(
            width: 240.w,
            child: Scrollbar(
              controller: _variantScrollController,
              child: Wrap(
                children: List.generate(
                  choiceOptions[choiceOptionsIndex].options.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(bottom: 8.0.h, right: 2.0.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildChoiceItem(
                          choiceOptions[choiceOptionsIndex].options[index],
                          choiceOptionsIndex,
                          index,
                        ),
                      ],
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
          ? EdgeInsets.only(left: 8.0.w)
          : EdgeInsets.only(right: 8.0.w),
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
            borderRadius: BorderRadius.circular(3.0.r),
            color: MyTheme.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6.r,
                spreadRadius: 1,
                offset: Offset(0.0, 3.0),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0.w, vertical: 3.0.h),
            child: Center(
              child: Text(
                option,
                style: TextStyle(
                  color: _selectedChoices[choiceOptionsIndex] == option
                      ? MyTheme.accent_color
                      : Color.fromRGBO(224, 224, 225, 1),
                  fontSize: 12.0.sp,
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
              ? EdgeInsets.only(left: 8.0.w)
              : EdgeInsets.only(right: 8.0.w),
          child: SizedBox(
            width: 75.w,
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
          height: 35.h,
          width: 107.w + 44.w,
          child: Scrollbar(
            controller: _colorScrollController,
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return SizedBox(width: 10.w);
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
        width: _selectedColorIndex == index ? 28.w : 20.w,
        height: _selectedColorIndex == index ? 28.w : 20.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0.r),
          color: ColorHelper.getColorFromColorCode(_colorList[index]),
          boxShadow: [
            _selectedColorIndex == index
                ? BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _selectedColorIndex == index ? 0.25 : 0.12,
                    ),
                    blurRadius: 10.r,
                    spreadRadius: 2.0,
                    offset: Offset(0.0, 6.0),
                  )
                : BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _selectedColorIndex == index ? 0.25 : 0.16,
                    ),
                    blurRadius: 6.r,
                    spreadRadius: 0.0,
                    offset: Offset(0.0, 3.0),
                  ),
          ],
        ),
        child: _selectedColorIndex == index
            ? buildColorCheckerContainer()
            : Container(height: 25.h),
      ),
    );
  }

  buildColorCheckerContainer() {
    return Padding(
      padding: EdgeInsets.all(6.r),
      child: Image.asset("assets/white_tick.png", width: 16.w, height: 16.h),
    );
  }

  Widget buildWholeSaleQuantityPrice() {
    return DataTable(
      columnSpacing: DeviceInfo(context).width! * 0.125,
      columns: [
        DataColumn(
          label: Text(
            LangText(context).local.min_qty_ucf,
            style: TextStyle(fontSize: 12.sp, color: MyTheme.dark_grey),
          ),
        ),
        DataColumn(
          label: Text(
            LangText(context).local.max_qty_ucf,
            style: TextStyle(fontSize: 12.sp, color: MyTheme.dark_grey),
          ),
        ),
        DataColumn(
          label: Text(
            LangText(context).local.unit_price_ucf,
            style: TextStyle(fontSize: 12.sp, color: MyTheme.dark_grey),
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
                  fontSize: 12.sp,
                ),
              ),
            ),
            DataCell(
              Text(
                _productDetails!.wholesale![index].maxQty.toString(),
                style: TextStyle(
                  color: Color.fromRGBO(152, 152, 153, 1),
                  fontSize: 12.sp,
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
                  fontSize: 12.sp,
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
      constraints: BoxConstraints(maxWidth: 120.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0.r),
        color: Color(0xffFFF4E8),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.0.w, vertical: 6.0.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset("assets/clubpoint.png", width: 18.w, height: 12.h),
                SizedBox(width: 4.w),
                Text(
                  AppLocalizations.of(context)!.club_point_ucf,
                  style: TextStyle(
                    color: Color(0xff6B7377),
                    fontSize: 10.sp,
                    fontFamily: 'Public Sans',
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            Text(
              _productDetails!.earnPoint.toString(),
              style: TextStyle(color: Color(0xffF7941D), fontSize: 12.0.sp),
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
          formatPrice(_singlePriceString),
          style: TextStyle(
            color: MyTheme.price_color,
            fontFamily: 'Public Sans',
            fontSize: 16.0.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Visibility(
          visible: _productDetails!.hasDiscount!,
          child: Padding(
            padding: EdgeInsets.only(left: 8.0.w),
            child: Text(
              formatPrice(_productDetails!.strokedPrice),
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Color(0xffA8AFB3),
                fontFamily: 'Public Sans',
                fontSize: 12.0.sp,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
        Visibility(
          visible: _productDetails!.hasDiscount!,
          child: Padding(
            padding: EdgeInsets.only(left: 8.0.w),
            child: Text(
              "${_productDetails!.discount}",
              style: TextStyle(
                fontSize: 12.sp,
                color: MyTheme.accent_color,
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
            fontSize: 16.0.sp,
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
          width: 300.w,
          child: Padding(
            padding: EdgeInsets.only(top: 22.0.h),
            child: Text(
              _appbarPriceString!,
              style: TextStyle(fontSize: 16.sp, color: MyTheme.font_grey),
            ),
          ),
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
      actions: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
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
    if (_productDetails != null && _stock != null && _stock! <= 0) {
      return BottomAppBar(
        color: MyTheme.white.withValues(alpha: 0.9),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 23.w, vertical: 10.h),
          height: 50.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0.r),
            color: Colors.grey,
          ),
          child: Center(
            child: Text(
              "Out of Stock",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
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
              margin: EdgeInsets.only(left: 23.w, right: 14.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0.r),
                color: MyTheme.accent_color,
                boxShadow: [
                  BoxShadow(
                    color: MyTheme.golden_shadow,
                    blurRadius: 20.r,
                    spreadRadius: 0.0,
                    offset: Offset(0.0, 10.0),
                  ),
                ],
              ),
              height: 50.h,
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.add_to_cart_ucf,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
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
              margin: EdgeInsets.only(left: 14.w, right: 23.w),
              height: 50.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0.r),
                color: Color(0xff23272B),
                boxShadow: [
                  BoxShadow(
                    color: MyTheme.black_shadow,
                    blurRadius: 20.r,
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
                    fontSize: 16.sp,
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
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductReviews(id: _productDetails!.id),
          ),
        );
      },
      child: Row(
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
            padding: EdgeInsets.symmetric(horizontal: 4.0.w),
            child: Text(
              "(${_productDetails!.ratingCount})",
              style: TextStyle(
                color: Color.fromRGBO(152, 152, 153, 1),
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  buildShippingTime() {
    return Row(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0.w),
          child: Text(
            LangText(context).local.estimate_shipping_time_ucf,
            style: TextStyle(
              color: Color.fromRGBO(152, 152, 153, 1),
              fontSize: 10.sp,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0.w),
          child: Text(
            "${_productDetails!.estShippingTime}  ${LangText(context).local.days_ucf}",
            style: TextStyle(
              color: Color.fromRGBO(152, 152, 153, 1),
              fontSize: 10.sp,
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
                      ? EdgeInsets.only(left: 8.0.w)
                      : EdgeInsets.only(right: 8.0.w),
                  child: SizedBox(
                    width: 75.w,
                    child: Text(
                      AppLocalizations.of(context)!.brand_ucf,
                      style: TextStyle(
                        color: Color(0xff6B7377),
                        fontSize: 10.sp,
                        fontFamily: 'Public Sans',
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0.w),
                  child: Text(
                    _productDetails!.brand!.name!,
                    style: TextStyle(
                      color: Color(0xff3E4447),
                      fontFamily: 'Public Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 10.sp,
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
            if (webViewHeight == 50.h) {
              try {
                var result = await controller.runJavaScriptReturningResult(
                  "document.body.scrollHeight",
                );
                double? newHeight = double.tryParse(result.toString());
                if (newHeight != null && newHeight > 50) {
                  webViewHeight = newHeight;
                }
              } catch (e) {
                if (kDebugMode) {
                  print("Error getting webview content height: $e");
                }
              }
            } else {
              webViewHeight = 50.h;
            }
            if (mounted) {
              setState(() {});
            }
          },
          child: Text(
            webViewHeight == 50.h
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
      return Row(
        children: [
          Padding(
            padding: app_language_rtl.$!
                ? EdgeInsets.only(left: 8.0.w)
                : EdgeInsets.only(right: 8.0.w),
            child: ShimmerHelper().buildBasicShimmer(
              height: 120.0.h,
              width: (MediaQuery.of(context).size.width - 32.w) / 3,
            ),
          ),
          Padding(
            padding: app_language_rtl.$!
                ? EdgeInsets.only(left: 8.0.w)
                : EdgeInsets.only(right: 8.0.w),
            child: ShimmerHelper().buildBasicShimmer(
              height: 120.0.h,
              width: (MediaQuery.of(context).size.width - 32.w) / 3,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 0.0),
            child: ShimmerHelper().buildBasicShimmer(
              height: 120.0.h,
              width: (MediaQuery.of(context).size.width - 32.w) / 3,
            ),
          ),
        ],
      );
    } else if (_topProducts.isNotEmpty) {
      return SingleChildScrollView(
        child: SizedBox(
          height: 320.h,
          child: ListView.separated(
            separatorBuilder: (context, index) => SizedBox(width: 10.w),
            itemCount: _topProducts.length,
            scrollDirection: Axis.horizontal,
            padding: .fromLTRB(0.w, 8.h, 16.w, 0.h),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return MiniProductCard(
                id: _topProducts[index].id,
                slug: _topProducts[index].slug,
                image: _topProducts[index].thumbnailImage,
                name: _topProducts[index].name,
                mainPrice: _topProducts[index].mainPrice,
                isWholesale: _topProducts[index].isWholesale,
                strokedPrice: _topProducts[index].strokedPrice,
                hasDiscount: _topProducts[index].hasDiscount,
              );
            },
          ),
        ),
      );
    } else {
      return SizedBox(
        height: 100.h,
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
                ? EdgeInsets.only(left: 8.0.w)
                : EdgeInsets.only(right: 8.0.w),
            child: ShimmerHelper().buildBasicShimmer(
              height: 120.0.h,
              width: (MediaQuery.of(context).size.width - 32.w) / 3,
            ),
          ),
          Padding(
            padding: app_language_rtl.$!
                ? EdgeInsets.only(left: 8.0.w)
                : EdgeInsets.only(right: 8.0.w),
            child: ShimmerHelper().buildBasicShimmer(
              height: 120.0.h,
              width: (MediaQuery.of(context).size.width - 32.w) / 3,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 0.0),
            child: ShimmerHelper().buildBasicShimmer(
              height: 120.0.h,
              width: (MediaQuery.of(context).size.width - 32.w) / 3,
            ),
          ),
        ],
      );
    } else if (_relatedProducts.isNotEmpty) {
      return SingleChildScrollView(
        child: SizedBox(
          height: 214.h,
          child: ListView.separated(
            separatorBuilder: (context, index) => SizedBox(width: 10.w),
            padding: .fromLTRB(16.w, 8.h, 16.w, 0.h),
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
                hasDiscount: _relatedProducts[index].hasDiscount,
              );
            },
          ),
        ),
      );
    } else {
      return SizedBox();
    }
  }

  buildQuantityUpButton() => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.16),
          blurRadius: 6.r,
          spreadRadius: 0.0,
          offset: Offset(0.0, 3.0),
        ),
      ],
    ),
    width: 36.w,
    child: IconButton(
      icon: Icon(Icons.add, size: 16, color: Color(0xff707070)),
      onPressed: () {
        if (_quantity! < _stock!) {
          _quantity = (_quantity!) + 1;
          setState(() {});
          //fetchVariantPrice();

          fetchAndSetVariantWiseInfo();
          // calculateTotalPrice();
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
          blurRadius: 6.r,
          spreadRadius: 0.0,
          offset: Offset(0.0, 3.0),
        ),
      ],
    ),
    width: 30.w,
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

  String makeHtml(String string) {
    return """
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      margin: 0;
      padding: 8px;
      color: #000000; /* NEW: Set a default text color to black */
      background-color: #ffffff; /* NEW: Set a default white background */
    }
    /* This makes sure images scale down to fit the screen width */
    img {
      max-width: 100%;
      height: auto;
    }
    /* This makes tables scrollable horizontally */
    table {
      display: block;
      width: 100% !important;
      overflow-x: auto;
      white-space: nowrap;
      -webkit-overflow-scrolling: touch;
    }
    /* This helps ensure all text content wraps correctly */
    * {
       word-wrap: break-word;
       overflow-wrap: break-word;
    }
  </style>
</head>
<body>
    $string
</body>
</html>
""";
  }
}

