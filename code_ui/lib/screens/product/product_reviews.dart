import 'dart:async';
import 'dart:ui';

import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/my_widget.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/uploaded_file_list_response.dart';
import 'package:active_ecommerce_cms_demo_app/screens/uploads/upload_file.dart';

import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/review_repositories.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../custom/lang_text.dart';

class ProductReviews extends StatefulWidget {
  final int? id;

  const ProductReviews({super.key, this.id});

  @override
  State<ProductReviews> createState() => _ProductReviewsState();
}

class _ProductReviewsState extends State<ProductReviews> {
  final TextEditingController _myReviewTextController = TextEditingController();
  final ScrollController _xcrollController = ScrollController();
  final ScrollController scrollController = ScrollController();
  double _myRating = 0.0;
  List<FileInfo> _selectedReviewImages = [];

  final List<dynamic> _reviewList = [];
  bool _isInitial = true;
  int _page = 1;
  int? _totalData = 0;
  bool _showLoadingContainer = false;

  @override
  void initState() {
    super.initState();
    fetchData();
    _xcrollController.addListener(() {
      if (_xcrollController.position.pixels ==
          _xcrollController.position.maxScrollExtent) {
        setState(() {
          _page++;
        });
        _showLoadingContainer = true;
        fetchData();
      }
    });
  }

  @override
  void dispose() {
    _xcrollController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    var reviewResponse = await ReviewRepository().getReviewResponse(
      widget.id,
      page: _page,
    );
    _reviewList.addAll(reviewResponse.reviews!);
    _isInitial = false;
    _totalData = reviewResponse.meta?.total ?? 0;
    _showLoadingContainer = false;
    setState(() {});
  }

  void reset() {
    _reviewList.clear();
    _isInitial = true;
    _totalData = 0;
    _page = 1;
    _showLoadingContainer = false;
    _myRating = 0.0;
    _myReviewTextController.text = "";
    _selectedReviewImages.clear();
    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    fetchData();
  }

  Future<void> _pickImages() async {
    List<FileInfo>? images = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadFile(
          fileType: "image",
          canSelect: true,
          canMultiSelect: true,
          prevData: _selectedReviewImages,
        ),
      ),
    );

    if (images != null) {
      setState(() {
        _selectedReviewImages = images;
      });
    }
  }

  void onTapReviewSubmit(BuildContext context) async {
    if (!is_logged_in.$) {
      ToastComponent.showDialog(
        LangText(context).local.you_need_to_login_to_give_a_review,
      );
      return;
    }

    var myReviewText = _myReviewTextController.text.toString();
    if (myReviewText.isEmpty) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.review_can_not_empty_warning,
      );
      return;
    }
    if (_myRating < 1.0) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.at_least_one_star_must_be_given,
      );
      return;
    }

    String imageIds = _selectedReviewImages.map((image) => image.id).join(',');

    var reviewSubmitResponse = await ReviewRepository().getReviewSubmitResponse(
      widget.id,
      _myRating.toInt(),
      myReviewText,
      imageIds,
    );

    ToastComponent.showDialog(reviewSubmitResponse.message!);

    if (reviewSubmitResponse.result == true) {
      reset();
      fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: buildAppBar(context),
        body: Stack(
          children: [
            RefreshIndicator(
              color: MyTheme.accent_color,
              backgroundColor: Colors.white,
              onRefresh: _onRefresh,
              displacement: 0,
              child: CustomScrollView(
                controller: _xcrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: buildProductReviewsList(),
                      ),
                      const SizedBox(height: 180),
                    ]),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: buildBottomBar(context),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: buildLoadingContainer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomBar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8)),
          height: 180,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: buildGiveReviewSection(context),
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.reviews_ucf,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  Widget buildProductReviewsList() {
    if (_isInitial && _reviewList.isEmpty) {
      return ShimmerHelper().buildListShimmer(itemCount: 10, itemHeight: 75.0);
    }
    if (_reviewList.isNotEmpty) {
      return ListView.builder(
        controller: scrollController,
        itemCount: _reviewList.length,
        scrollDirection: Axis.vertical,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 18.0),
            child: buildProductReviewsItem(index),
          );
        },
      );
    }
    if (_totalData == 0) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_reviews_yet_be_the_first,
          ),
        ),
      );
    }
    return Container();
  }

  Widget buildReviewImages(int index) {
    if (_reviewList[index].images != null &&
        _reviewList[index].images.isNotEmpty) {
      return SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _reviewList[index].images.length,
          itemBuilder: (context, imageIndex) {
            String? imagePath = _reviewList[index].images[imageIndex].path;
            return Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                onTap: () {
                  if (imagePath != null && imagePath.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/placeholder.png',
                          image: imagePath,
                        ),
                      ),
                    );
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: (imagePath != null && imagePath.isNotEmpty)
                      ? FadeInImage.assetNetwork(
                          placeholder: 'assets/placeholder.png',
                          image: imagePath,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/placeholder.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget buildProductReviewsItem(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: const Color.fromRGBO(112, 112, 112, .3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child:
                    (_reviewList[index].avatar != null &&
                        _reviewList[index].avatar.isNotEmpty)
                    ? FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: _reviewList[index].avatar,
                        fit: BoxFit.cover,
                      )
                    : Image.asset('assets/placeholder.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _reviewList[index].userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: MyTheme.font_grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _reviewList[index].time,
                    style: TextStyle(color: MyTheme.medium_grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            RatingBar(
              itemSize: 12.0,
              ignoreGestures: true,
              initialRating: double.parse(_reviewList[index].rating.toString()),
              direction: Axis.horizontal,
              itemCount: 5,
              ratingWidget: RatingWidget(
                full: const Icon(Icons.star, color: Colors.amber),
                half: const Icon(Icons.star_half, color: Colors.amber),
                empty: const Icon(
                  Icons.star,
                  color: Color.fromRGBO(224, 224, 225, 1),
                ),
              ),
              itemPadding: const EdgeInsets.only(right: 1.0),
              onRatingUpdate: (rating) {},
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 56.0, top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildExpandableDescription(index),
              const SizedBox(height: 10),
              buildReviewImages(index),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildExpandableDescription(int index) {
    return ExpandableNotifier(
      child: ScrollOnExpand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expandable(
              collapsed: Text(
                _reviewList[index].comment,
                style: TextStyle(color: MyTheme.font_grey),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              expanded: Text(
                _reviewList[index].comment,
                style: TextStyle(color: MyTheme.font_grey),
              ),
            ),
            if (_reviewList[index].comment.length > 100)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Builder(
                    builder: (context) {
                      var controller = ExpandableController.of(context)!;
                      return Btn.basic(
                        child: Text(
                          !controller.expanded
                              ? AppLocalizations.of(context)!.view_more
                              : AppLocalizations.of(context)!.show_less_ucf,
                          style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 11,
                          ),
                        ),
                        onPressed: () => controller.toggle(),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget buildLoadingContainer() {
    return Container(
      height: _showLoadingContainer ? 36 : 0,
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text(
          _totalData == _reviewList.length
              ? AppLocalizations.of(context)!.no_more_reviews_ucf
              : AppLocalizations.of(context)!.loading_more_reviews_ucf,
        ),
      ),
    );
  }

  Widget buildSelectedImages() {
    if (_selectedReviewImages.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedReviewImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: MyWidget.imageWithPlaceholder(
                    url: _selectedReviewImages[index].url,
                    // FIX: Changed int to double
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: -5,
                  right: -5,
                  child: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                    onPressed: () {
                      setState(() {
                        _selectedReviewImages.removeAt(index);
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildGiveReviewSection(BuildContext context) {
    return Column(
      children: [
        RatingBar.builder(
          itemSize: 20.0,
          initialRating: _myRating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          glowColor: Colors.amber,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
          itemBuilder: (context, _) =>
              const Icon(Icons.star, color: Colors.amber),
          onRatingUpdate: (rating) {
            setState(() {
              _myRating = rating;
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: MyTheme.textfield_grey),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: MyTheme.font_grey,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  autofocus: false,
                  maxLines: 1,
                  inputFormatters: [LengthLimitingTextInputFormatter(255)],
                  controller: _myReviewTextController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color.fromRGBO(251, 251, 251, 1),
                    hintText: AppLocalizations.of(
                      context,
                    )!.type_your_review_here,
                    hintStyle: TextStyle(
                      fontSize: 14.0,
                      color: MyTheme.textfield_grey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: MyTheme.textfield_grey,
                        width: 0.5,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(35.0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: MyTheme.medium_grey,
                        width: 0.5,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(35.0),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => onTapReviewSubmit(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: MyTheme.accent_color,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.send, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        buildSelectedImages(),
      ],
    );
  }
}
