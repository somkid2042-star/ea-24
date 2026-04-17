import 'dart:async';
import 'package:ea24_mobile/custom/toast_component.dart';
import 'package:ea24_mobile/data_model/flash_deal_response.dart'
    hide Product;
import 'package:ea24_mobile/data_model/product_mini_response.dart';
import 'package:ea24_mobile/data_model/category_response.dart';
import 'package:ea24_mobile/data_model/slider_response.dart';
import 'package:ea24_mobile/repositories/category_repository.dart';
import 'package:ea24_mobile/repositories/flash_deal_repository.dart';
import 'package:ea24_mobile/repositories/product_repository.dart';
import 'package:ea24_mobile/repositories/sliders_repository.dart';
import 'package:ea24_mobile/single_banner/model.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';

class HomePresenter extends ChangeNotifier {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  int current_slider = 0;

  ScrollController? allProductScrollController;
  ScrollController? featuredCategoryScrollController;
  ScrollController mainScrollController = ScrollController();

  late AnimationController pirated_logo_controller;
  late Animation<double> pirated_logo_animation;

  /// Slider & Banner
  List<AIZSlider> carouselImageList = [];
  List<AIZSlider> bannerOneImageList = [];
  List<AIZSlider> bannerTwoImageList = [];
  List<AIZSlider> flashDealBannerImageList = [];

  /// Flash Deal
  List<FlashDealResponseDatum> flashDealList = [];

  List<FlashDealResponseDatum> _banners = [];
  List<FlashDealResponseDatum> get banners => [..._banners];

  final List<SingleBanner> _singleBanner = [];
  List<SingleBanner> get singleBanner => _singleBanner;

  /// Categories
  List<Category> featuredCategoryList = [];

  /// Products
  List<Product> featuredProductList = [];
  List<Product> allProductList = [];

  /// Flags
  bool isCategoryInitial = true;
  bool isCarouselInitial = true;
  bool isBannerOneInitial = true;
  bool isFlashDealInitial = true;
  bool isBannerTwoInitial = true;
  bool isBannerFlashDeal = true;

  bool isFeaturedProductInitial = true;
  bool isAllProductInitial = true;

  bool isTodayDeal = false;
  bool isFlashDeal = false;

  /// Pagination
  int? totalFeaturedProductData = 0;
  int featuredProductPage = 1;
  bool showFeaturedLoadingContainer = false;

  int? totalAllProductData = 0;
  int allProductPage = 1;
  bool showAllLoadingContainer = false;

  int cartCount = 0;

  /// ================= FETCH ALL =================

  fetchAll() {
    fetchCarouselImages();
    fetchBannerOneImages();
    fetchBannerTwoImages();
    fetchFeaturedCategories();
    fetchFeaturedProducts();
    fetchAllProducts();
    fetchTodayDealData();
    fetchFlashDealData();
    fetchBannerFlashDeal();
    fetchFlashDealBannerImages();
  }

  /// ================= FLASH DEAL =================

  FlashDealResponseDatum? getFeaturedFlashDeal() {
    if (flashDealList.isEmpty) return null;
    try {
      return flashDealList.firstWhere((e) => e.isFeatured == 1);
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchBannerFlashDeal() async {
    try {
      _banners = await SlidersRepository().fetchBanners();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading banners: $e');
    }
  }

  fetchFlashDealData() async {
    var deal = await FlashDealRepository().getFlashDeals();
    if (deal.success == true && deal.flashDeals!.isNotEmpty) {
      flashDealList = deal.flashDeals!;
      isFlashDeal = true;
    } else {
      isFlashDeal = false;
    }
    notifyListeners();
  }

  fetchTodayDealData() async {
    var deal = await ProductRepository().getTodaysDealProducts();
    isTodayDeal = deal.success == true && deal.products!.isNotEmpty;
    notifyListeners();
  }

  /// ================= SLIDERS =================

  fetchCarouselImages() async {
    var res = await SlidersRepository().getSliders();
    carouselImageList = res.sliders ?? [];
    isCarouselInitial = false;
    notifyListeners();
  }

  fetchBannerOneImages() async {
    var res = await SlidersRepository().getBannerOneImages();
    bannerOneImageList = res.sliders ?? [];
    isBannerOneInitial = false;
    notifyListeners();
  }

  fetchBannerTwoImages() async {
    var res = await SlidersRepository().getBannerTwoImages();
    bannerTwoImageList = res.sliders ?? [];
    isBannerTwoInitial = false;
    notifyListeners();
  }

  fetchFlashDealBannerImages() async {
    var res = await SlidersRepository().getFlashDealBanner();
    flashDealBannerImageList = res.sliders ?? [];
    isFlashDealInitial = false;
    notifyListeners();
  }

  /// ================= CATEGORY =================

  fetchFeaturedCategories() async {
    var res = await CategoryRepository().getFeturedCategories();
    featuredCategoryList = res.categories ?? [];
    isCategoryInitial = false;
    notifyListeners();
  }

  /// ================= PRODUCTS =================

  fetchFeaturedProducts() async {
    try {
      var res = await ProductRepository().getFeaturedProducts(
        page: featuredProductPage,
      );
      featuredProductPage++;

      if (res.products != null) {
        featuredProductList.addAll(res.products!);
      }

      totalFeaturedProductData = res.meta?.total ?? 0;
      isFeaturedProductInitial = false;
      showFeaturedLoadingContainer = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Featured product error: $e");
    }
  }

  fetchAllProducts() async {
    var res = await ProductRepository().getFilteredProducts(
      page: allProductPage,
    );

    if (res.products != null) {
      allProductList.addAll(res.products!);
    }

    totalAllProductData = res.meta?.total ?? 0;
    isAllProductInitial = false;
    showAllLoadingContainer = false;
    notifyListeners();
  }

  /// ================= RESET =================

  reset() {
    carouselImageList.clear();
    bannerOneImageList.clear();
    bannerTwoImageList.clear();
    featuredCategoryList.clear();
    flashDealList.clear();
    flashDealBannerImageList.clear();

    isCarouselInitial = true;
    isBannerOneInitial = true;
    isBannerTwoInitial = true;
    isCategoryInitial = true;

    resetFeaturedProductList();
    resetAllProductList();
  }

  resetFeaturedProductList() {
    featuredProductList.clear();
    isFeaturedProductInitial = true;
    totalFeaturedProductData = 0;
    featuredProductPage = 1;
    showFeaturedLoadingContainer = false;
    notifyListeners();
  }

  resetAllProductList() {
    allProductList.clear();
    isAllProductInitial = true;
    totalAllProductData = 0;
    allProductPage = 1;
    showAllLoadingContainer = false;
    notifyListeners();
  }

  /// ================= SCROLL =================

  mainScrollListener() {
    mainScrollController.addListener(() {
      if (mainScrollController.position.pixels ==
          mainScrollController.position.maxScrollExtent) {
        allProductPage++;
        ToastComponent.showDialog("More Products Loading...");
        showAllLoadingContainer = true;
        fetchAllProducts();
      }
    });
  }

  /// ================= ANIMATION =================

  initPiratedAnimation(vnc) {
    pirated_logo_controller = AnimationController(
      vsync: vnc,
      duration: Duration(milliseconds: 2000),
    );

    pirated_logo_animation = Tween<double>(begin: 40, end: 60).animate(
      CurvedAnimation(parent: pirated_logo_controller, curve: Curves.bounceOut),
    );

    pirated_logo_controller.repeat();
  }

  incrementCurrentSlider(index) {
    current_slider = index;
    notifyListeners();
  }

  @override
  void dispose() {
    pirated_logo_controller.dispose();
    super.dispose();
  }

  Future<void> onRefresh() async {
    reset();
    fetchAll();
  }
}
