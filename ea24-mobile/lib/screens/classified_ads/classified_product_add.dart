import 'dart:convert';
import 'package:ea24_mobile/data_model/category.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../custom/aiz_summer_note.dart';
import '../../custom/device_info.dart';
import '../../custom/lang_text.dart';
import '../../custom/loading.dart';
import '../../custom/my_widget.dart';
import '../../custom/toast_component.dart';
import '../../custom/useful_elements.dart';
import '../../data_model/uploaded_file_list_response.dart';
import '../../helpers/shared_value_helper.dart';
import '../../my_theme.dart';
import '../../repositories/brand_repository.dart';
import '../../repositories/classified_product_repository.dart';
import '../../repositories/product_repository.dart';
import '../uploads/upload_file.dart';
import 'package:ea24_mobile/l10n/app_localizations.dart';

class ClassifiedProductAdd extends StatefulWidget {
  const ClassifiedProductAdd({super.key});

  @override
  State<ClassifiedProductAdd> createState() => _ClassifiedProductAddState();
}

class _ClassifiedProductAddState extends State<ClassifiedProductAdd> {
  double mHeight = 0.0, mWidth = 0.0;
  bool _generalExpanded = true;
  bool _mediaExpanded = false;
  bool _priceExpanded = false;
  bool _hasFocus = false;

  // Controllers
  final TextEditingController productNameEditTextController =
      TextEditingController();
  final TextEditingController unitEditTextController = TextEditingController();
  final TextEditingController tagEditTextController = TextEditingController();
  final TextEditingController locationTextController = TextEditingController();
  final TextEditingController metaTitleTextController = TextEditingController();
  final TextEditingController metaDescriptionEditTextController =
      TextEditingController();
  final TextEditingController videoLinkController = TextEditingController();
  final TextEditingController unitPriceEditTextController =
      TextEditingController(text: "0");

  final GlobalKey<FlutterSummernoteState> productDescriptionKey = GlobalKey();

  CommonDropDownItemWithChild? selectedCategory;
  final List<CommonDropDownItemWithChild> categories = [];
  CommonDropDownItem? selectedBrand;
  final List<CommonDropDownItem> brands = [];
  CommonDropDownItem? selectedVideoType;
  final List<CommonDropDownItem> videoType = [];
  final List<FileInfo> productGalleryImages = [];
  FileInfo? thumbnailImage;
  FileInfo? pdfSpecification;
  FileInfo? metaImage;
  List<String?> tags = [];
  String? description = "";
  final List<String> itemList = ['new', 'used'];
  String? selectedCondition;

  @override
  void initState() {
    super.initState();
    selectedCondition = itemList.first;
    fetchAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setConstDropdownValues();
  }

  // Reusable Dialog Function
  Future<bool> _showDisclosureDialog(String purpose) async {
    bool? userAgreed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Permission Required"),
        content: Text(purpose, textAlign: TextAlign.center),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.deny_ucf),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Agree"),
          ),
        ],
      ),
    );
    return userAgreed ?? false;
  }

  void setConstDropdownValues() {
    videoType.clear();
    videoType.addAll([
      CommonDropDownItem("youtube", AppLocalizations.of(context)!.youtube_ucf),
      CommonDropDownItem(
        "dailymotion",
        AppLocalizations.of(context)!.dailymotion_ucf,
      ),
      CommonDropDownItem("vimeo", AppLocalizations.of(context)!.vimeo_ucf),
    ]);
    selectedVideoType = videoType.first;
  }

  List<CommonDropDownItemWithChild> setChildCategory(List<CatData> child) {
    List<CommonDropDownItemWithChild> list = [];
    for (var element in child) {
      var children = element.child ?? [];
      var model = CommonDropDownItemWithChild(
        key: element.id.toString(),
        value: element.name,
        children: children.isNotEmpty ? setChildCategory(children) : [],
      );
      list.add(model);
    }
    return list;
  }

  Future<void> getCategories() async {
    categories.clear();
    var categoryResponse = await ProductRepository().getCategoryRes();
    for (var element in categoryResponse.data!) {
      var model = CommonDropDownItemWithChild(
        key: element.id.toString(),
        value: element.name,
        level: element.level,
        children: setChildCategory(element.child!),
      );
      categories.add(model);
    }
    if (categories.isNotEmpty) {
      selectedCategory = categories.first;
    }
    setState(() {});
  }

  Future<void> getBrands() async {
    brands.clear();
    var brandsRes = await BrandRepository().getAllBrands();
    for (var element in brandsRes.data!) {
      brands.add(CommonDropDownItem("${element.id}", element.name));
    }
    setState(() {});
  }

  bool requiredFieldVerification() {
    if (productNameEditTextController.text.trim().isEmpty) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.product_name_required,
      );
      return false;
    } else if (unitEditTextController.text.trim().isEmpty) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.product_unit_required,
      );
      return false;
    } else if (locationTextController.text.trim().isEmpty) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.location_required,
      );
      return false;
    } else if (tags.isEmpty) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.product_tag_required,
      );
      return false;
    } else if (description == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.product_description_required,
      );
      return false;
    }
    return true;
  }

  String? productName,
      brandId,
      categoryId,
      unit,
      conditon,
      location,
      photos,
      thumbnailImg,
      videoProvider,
      videoLink,
      unitPrice,
      externalLink,
      pdf,
      metaTitle,
      metaDescription,
      metaImg;

  var tagMap = [];

  void setProductPhotoValue() {
    photos = "";
    for (int i = 0; i < productGalleryImages.length; i++) {
      if (i != (productGalleryImages.length - 1)) {
        photos = "$photos${productGalleryImages[i].id},";
      } else {
        photos = "$photos${productGalleryImages[i].id}";
      }
    }
  }

  Future<void> setProductValues() async {
    productName = productNameEditTextController.text.trim();
    if (selectedBrand != null) brandId = selectedBrand!.key;
    if (selectedCategory != null) categoryId = selectedCategory!.key;
    unit = unitEditTextController.text.trim();
    conditon = selectedCondition;
    location = locationTextController.text.trim();

    tagMap.clear();
    for (var element in tags) {
      tagMap.add(jsonEncode({"value": '$element'}));
    }

    if (productDescriptionKey.currentState != null) {
      description = await productDescriptionKey.currentState!.getText();
    }

    setProductPhotoValue();

    if (thumbnailImage != null) thumbnailImg = "${thumbnailImage!.id}";
    videoProvider = selectedVideoType!.key;
    videoLink = videoLinkController.text.trim();

    if (pdfSpecification != null) pdf = "${pdfSpecification!.id}";
    unitPrice = unitPriceEditTextController.text.trim();
    metaTitle = metaTitleTextController.text.trim();
    metaDescription = metaDescriptionEditTextController.text.trim();
    if (metaImage != null) metaImg = "${metaImage!.id}";
  }

  Future<void> submit() async {
    if (!requiredFieldVerification()) {
      return;
    }
    Loading.show(context);
    await setProductValues();
    Map<String, dynamic> postValue = {
      "name": productName,
      "added_by": "customer",
      "category_id": categoryId,
      "brand_id": brandId,
      "unit": unit,
      "conditon": selectedCondition,
      "location": location,
      "tags": [tagMap.toString()],
      "description": description,
      "photos": photos,
      "thumbnail_img": thumbnailImg,
      "video_provider": videoProvider,
      "video_link": videoLink,
      "pdf": pdf,
      "unit_price": unitPrice,
      "meta_title": metaTitle,
      "meta_description": metaDescription,
      "meta_img": metaImg,
    };

    var postBody = jsonEncode(postValue);
    var response = await ClassifiedProductRepository().addProductResponse(
      postBody,
    );
    if (!mounted) return;
    Loading.close();
    if (response.result) {
      ToastComponent.showDialog(response.message);
      Navigator.pop(context);
    } else {
      dynamic errorMessages = response.message;
      if (errorMessages is String) {
        ToastComponent.showDialog(errorMessages);
      } else {
        ToastComponent.showDialog(errorMessages.join(","));
      }
    }
  }

  void fetchAll() {
    getBrands();
    getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "Add New Classified Product",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MyTheme.dark_font_grey,
            ),
          ),
          backgroundColor: MyTheme.white,
          leading: UsefulElements.backButton(context),
        ),
        body: buildBody(),
      ),
    );
  }

  Widget buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        child: Column(
          children: [
            buildGeneral(),
            itemSpacer(),
            buildMedia(),
            itemSpacer(),
            buildPrice(),
          ],
        ),
      ),
    );
  }

  Widget buildGeneral() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _generalExpanded = !_generalExpanded;
        });
      },
      child: Material(
        elevation: 10,
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color.fromRGBO(255, 255, 255, 0),
              width: 0.0,
            ),
            boxShadow: [BoxShadow(color: MyTheme.white)],
          ),
          padding: const EdgeInsets.only(top: 10, left: 5, right: 5),
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.general_ucf,
                    style: TextStyle(
                      fontSize: 13,
                      color: MyTheme.dark_font_grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _generalExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.navigate_next_rounded,
                    size: 20,
                    color: MyTheme.dark_font_grey,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Visibility(
                visible: _generalExpanded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildEditTextField(
                      AppLocalizations.of(context)!.product_name_ucf,
                      AppLocalizations.of(context)!.product_name_ucf,
                      productNameEditTextController,
                      isMandatory: true,
                    ),
                    itemSpacer(),
                    _buildDropDownField(
                      AppLocalizations.of(context)!.brand_ucf,
                      (value) {
                        setState(() {
                          selectedBrand = value;
                        });
                      },
                      selectedBrand,
                      brands,
                    ),
                    itemSpacer(),
                    _buildDropDownFieldWithChildren(
                      AppLocalizations.of(context)!.categories_ucf,
                      (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                      selectedCategory,
                      categories,
                    ),
                    itemSpacer(),
                    buildEditTextField(
                      AppLocalizations.of(context)!.product_unit_ucf,
                      AppLocalizations.of(context)!.product_unit_ucf,
                      unitEditTextController,
                      isMandatory: true,
                    ),
                    itemSpacer(),
                    buildGroupItems(
                      AppLocalizations.of(context)!.condition_ucf,
                      Focus(
                        onFocusChange: (hasFocus) {
                          setState(() {
                            _hasFocus = hasFocus;
                          });
                        },
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: MyTheme.white,
                            border: Border.all(
                              color: _hasFocus
                                  ? MyTheme.textfield_grey
                                  : MyTheme.accent_color,
                              style: BorderStyle.solid,
                              width: _hasFocus ? 0.5 : 0.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: MyTheme.blue_grey.withValues(alpha: .15),
                                blurRadius: 20,
                                spreadRadius: 0.0,
                                offset: const Offset(
                                  0.0,
                                  10.0,
                                ), // shadow direction: bottom right
                              ),
                            ],
                          ),
                          child: DropdownButton<String>(
                            menuMaxHeight: 300,
                            isDense: true,
                            underline: Container(),
                            isExpanded: true,
                            onChanged: (String? value) {
                              setState(() {
                                selectedCondition = value;
                              });
                            },
                            icon: const Icon(Icons.arrow_drop_down),
                            value: selectedCondition,
                            items: itemList
                                .map(
                                  (value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        color: MyTheme.font_grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                    itemSpacer(),
                    buildEditTextField(
                      AppLocalizations.of(context)!.location_ucf,
                      AppLocalizations.of(context)!.location_ucf,
                      locationTextController,
                      isMandatory: true,
                    ),
                    itemSpacer(),
                    buildTagsEditTextField(
                      LangText(context).local.tags_ucf,
                      LangText(context).local.tags_ucf,
                      tagEditTextController,
                      isMandatory: true,
                    ),
                    itemSpacer(),
                    buildGroupItems(
                      AppLocalizations.of(context)!.descriptions_ucf,
                      summerNote(
                        AppLocalizations.of(context)!.descriptions_ucf,
                      ),
                    ),
                    itemSpacer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  buildMedia() {
    return GestureDetector(
      onTap: () {
        _mediaExpanded = !_mediaExpanded;
        setState(() {});
      },
      child: Material(
        elevation: 10,
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color.fromRGBO(255, 255, 255, 0),
              width: 0.0,
            ),
            boxShadow: [BoxShadow(color: MyTheme.white)],
          ),
          padding: const EdgeInsets.only(top: 10, left: 5, right: 5),
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.media_ucf,
                    style: TextStyle(
                      fontSize: 13,
                      color: MyTheme.dark_font_grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _mediaExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.navigate_next_rounded,
                    size: 20,
                    color: MyTheme.dark_font_grey,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Visibility(
                visible: _mediaExpanded,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      chooseGalleryImageField(),
                      itemSpacer(),
                      chooseSingleImageField(
                        AppLocalizations.of(context)!.thumbnail_image_ucf,
                        (onChosenImage) {
                          thumbnailImage = onChosenImage;
                          setChange();
                        },
                        thumbnailImage,
                      ),
                      buildGroupItems(
                        AppLocalizations.of(context)!.video_form_ucf,
                        _buildDropDownField(
                          AppLocalizations.of(context)!.video_url_ucf,
                          (newValue) {
                            selectedVideoType = newValue;
                            setChange();
                          },
                          selectedVideoType,
                          videoType,
                        ),
                      ),
                      itemSpacer(),
                      buildEditTextField(
                        AppLocalizations.of(context)!.video_url_ucf,
                        AppLocalizations.of(context)!.video_link_ucf,
                        videoLinkController,
                      ),
                      itemSpacer(),
                      chooseSingleFileField(
                        AppLocalizations.of(context)!.pdf_specification_ucf,
                        "",
                        (onChosenFile) {
                          pdfSpecification = onChosenFile;
                          setChange();
                        },
                        pdfSpecification,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget chooseSingleFileField(
    String title,
    String shortMessage,
    dynamic onChosenFile,
    FileInfo? selectedFile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: MyTheme.font_grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            fileField(
              AppLocalizations.of(context)!.document,
              onChosenFile,
              selectedFile,
            ),
          ],
        ),
      ],
    );
  }

  Widget fileField(
    String fileType,
    dynamic onChosenFile,
    FileInfo? selectedFile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            bool isPermissionAgreed =
                prefs.getBool('file_permission_agreed') ?? false;

            if (!isPermissionAgreed) {
              String purpose =
                  "To upload your PDF specification, this app needs to access your documents.";
              bool userAgreed = await _showDisclosureDialog(purpose);

              if (userAgreed) {
                await prefs.setBool('file_permission_agreed', true);
              } else {
                ToastComponent.showDialog("Permission denied to access files.");
                return;
              }
            }
            if (!mounted) return;
            List<FileInfo>? chooseFile = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UploadFile(fileType: fileType, canSelect: true),
              ),
            );

            if (chooseFile != null && chooseFile.isNotEmpty) {
              onChosenFile(chooseFile.first);
            }
          },
          child: MyWidget().myContainer(
            width: DeviceInfo(context).width!,
            height: 36,
            borderRadius: 6.0,
            borderColor: MyTheme.light_grey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: Text(
                    AppLocalizations.of(context)!.choose_file,
                    style: TextStyle(fontSize: 12, color: MyTheme.grey_153),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  height: 46,
                  width: 80,
                  color: MyTheme.light_grey,
                  child: Text(
                    AppLocalizations.of(context)!.browse,
                    style: TextStyle(fontSize: 12, color: MyTheme.grey_153),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (selectedFile != null)
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                height: 40,
                alignment: Alignment.center,
                width: 40,
                decoration: BoxDecoration(color: MyTheme.grey_153),
                child: Text(
                  "${selectedFile.fileOriginalName}.${selectedFile.extension!}",
                  style: TextStyle(fontSize: 9, color: MyTheme.white),
                ),
              ),
              Positioned(
                top: 0,
                right: 5,
                child: Container(
                  height: 15,
                  width: 15,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: MyTheme.white,
                  ),
                  child: InkWell(
                    onTap: () {
                      onChosenFile(null);
                    },
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: MyTheme.brick_red,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget chooseSingleImageField(
    String title,
    dynamic onChosenImage,
    FileInfo? selectedFile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: MyTheme.font_grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            imageField(onChosenImage, selectedFile),
          ],
        ),
      ],
    );
  }

  Widget imageField(dynamic onChosenImage, FileInfo? selectedFile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            bool isPermissionAgreed =
                prefs.getBool('gallery_permission_agreed') ?? false;

            if (!isPermissionAgreed) {
              String purpose =
                  "To upload a product image, this app needs to access your gallery.";
              bool userAgreed = await _showDisclosureDialog(purpose);

              if (userAgreed) {
                await prefs.setBool('gallery_permission_agreed', true);
              } else {
                ToastComponent.showDialog(
                  "Permission denied to access photos.",
                );
                return;
              }
            }
            if (!mounted) return;

            List<FileInfo>? chooseFile = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const UploadFile(fileType: "image", canSelect: true),
              ),
            );

            if (chooseFile != null && chooseFile.isNotEmpty) {
              onChosenImage(chooseFile.first);
            }
          },
          child: MyWidget().myContainer(
            width: DeviceInfo(context).width!,
            height: 36,
            borderColor: MyTheme.accent_color,
            borderWith: 0.2,
            borderRadius: 6.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: Text(
                    AppLocalizations.of(context)!.choose_file,
                    style: TextStyle(fontSize: 12, color: MyTheme.grey_153),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  height: 46,
                  width: 80,
                  color: MyTheme.light_grey,
                  child: Text(
                    AppLocalizations.of(context)!.browse,
                    style: TextStyle(fontSize: 12, color: MyTheme.grey_153),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (selectedFile != null)
          Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.bottomCenter,
            children: [
              const SizedBox(height: 60, width: 70),
              MyWidget.imageWithPlaceholder(
                border: Border.all(width: 0.5, color: MyTheme.light_grey),
                radius: BorderRadius.circular(5),
                height: 50.0,
                width: 50.0,
                url: selectedFile.url,
              ),
              Positioned(
                top: 3,
                right: 2,
                child: Container(
                  height: 15,
                  width: 15,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: MyTheme.light_grey,
                  ),
                  child: InkWell(
                    onTap: () {
                      onChosenImage(null);
                    },
                    child: Icon(Icons.close, size: 12, color: MyTheme.cinnabar),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  buildPrice() {
    return GestureDetector(
      onTap: () {
        _priceExpanded = !_priceExpanded;
        setState(() {});
      },
      child: Material(
        elevation: 10,
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color.fromRGBO(255, 255, 255, 0),
              width: 0.0,
            ),
            boxShadow: [BoxShadow(color: MyTheme.white)],
          ),
          padding: const EdgeInsets.only(top: 10, left: 5, right: 5),
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.auction_price_ucf,
                    style: TextStyle(
                      fontSize: 13,
                      color: MyTheme.dark_font_grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _priceExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.navigate_next_rounded,
                    size: 20,
                    color: MyTheme.dark_font_grey,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Visibility(
                visible: _priceExpanded,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildEditTextField(
                        AppLocalizations.of(context)!.auction_price_ucf,
                        LangText(
                          context,
                        ).local.custom_unit_price_and_base_price,
                        unitPriceEditTextController,
                        isMandatory: true,
                      ),
                      itemSpacer(),
                      buildGroupItems(
                        AppLocalizations.of(context)!.meta_tags_ucf,
                        buildEditTextField(
                          AppLocalizations.of(context)!.meta_title_ucf,
                          AppLocalizations.of(context)!.meta_title_ucf,
                          metaTitleTextController,
                          isMandatory: false,
                        ),
                      ),
                      itemSpacer(),
                      buildGroupItems(
                        AppLocalizations.of(context)!.meta_description_ucf,
                        Container(
                          padding: const EdgeInsets.all(8),
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: MyTheme.accent_color,
                              style: BorderStyle.solid,
                              width: 0.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: MyTheme.white.withValues(alpha: .15),
                                blurRadius: 20,
                                spreadRadius: 0.0,
                                offset: const Offset(0.0, 10.0),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: metaDescriptionEditTextController,
                            keyboardType: TextInputType.multiline,
                            minLines: 1,
                            maxLines: 50,
                            enabled: true,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration.collapsed(
                              hintText: LangText(
                                context,
                              ).local.meta_description_ucf,
                            ),
                          ),
                        ),
                      ),
                      itemSpacer(),
                      chooseSingleImageField(
                        AppLocalizations.of(context)!.meta_image_ucf,
                        (onChosenImage) {
                          metaImage = onChosenImage;
                          setChange();
                        },
                        metaImage,
                      ),
                      itemSpacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              MyTheme.accent_color,
                            ),
                            shape:
                                WidgetStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                ),
                          ),
                          onPressed: submit,
                          child: Text(
                            AppLocalizations.of(context)!.save_product_ucf,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEditTextField(
    String title,
    String hint,
    TextEditingController textEditingController, {
    isMandatory = false,
  }) {
    return buildCommonSingleField(
      title,
      MyWidget.customCardView(
        shadowColor: MyTheme.noColor,
        backgroundColor: MyTheme.white,
        elevation: 0,
        width: DeviceInfo(context).width!,
        height: 36,
        borderRadius: 10,
        child: TextField(
          controller: textEditingController,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: MyTheme.white,
            hintStyle: TextStyle(fontSize: 12.0, color: MyTheme.textfield_grey),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: MyTheme.accent_color, width: 0.2),
              borderRadius: BorderRadius.all(Radius.circular(6.0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: MyTheme.textfield_grey, width: 0.5),
              borderRadius: const BorderRadius.all(Radius.circular(6.0)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          ),
        ),
      ),
      isMandatory: isMandatory,
    );
  }

  buildCommonSingleField(title, Widget child, {isMandatory = false}) {
    return Column(
      children: [
        Row(
          children: [
            buildFieldTitle(title),
            if (isMandatory)
              const Text(
                " *",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Text buildFieldTitle(title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: MyTheme.font_grey,
      ),
    );
  }

  Widget itemSpacer({double height = 10}) {
    return SizedBox(height: height);
  }

  Widget _buildDropDownField(
    String title,
    dynamic onchange,
    CommonDropDownItem? selectedValue,
    List<CommonDropDownItem> itemList, {
    bool isMandatory = false,
    double? width,
  }) {
    return buildCommonSingleField(
      title,
      _buildDropDown(onchange, selectedValue, itemList, width: width),
      isMandatory: isMandatory,
    );
  }

  Widget _buildDropDownFieldWithChildren(
    String title,
    dynamic onchange,
    CommonDropDownItemWithChild? selectedValue,
    List<CommonDropDownItemWithChild> itemList, {
    bool isMandatory = false,
    double? width,
  }) {
    return buildCommonSingleField(
      title,
      _buildDropDownWithChildren(
        onchange,
        selectedValue,
        itemList,
        width: width,
      ),
      isMandatory: isMandatory,
    );
  }

  Widget _buildDropDown(
    dynamic onchange,
    CommonDropDownItem? selectedValue,
    List<CommonDropDownItem> itemList, {
    double? width,
  }) {
    return Focus(
      onFocusChange: (hasFocus) {},
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: MyTheme.accent_color,
            style: BorderStyle.solid,
            width: 0.2,
          ),
          boxShadow: const [],
        ),
        child: DropdownButton<CommonDropDownItem>(
          borderRadius: BorderRadius.circular(10),
          dropdownColor: Colors.white,
          menuMaxHeight: 300,
          isDense: true,
          underline: Container(),
          isExpanded: true,
          onChanged: (CommonDropDownItem? value) {
            onchange(value);
          },
          icon: const Icon(Icons.arrow_drop_down, size: 22),
          value: selectedValue,
          items: itemList
              .map(
                (value) => DropdownMenuItem<CommonDropDownItem>(
                  value: value,
                  child: Text(
                    value.value!,
                    style: const TextStyle(fontSize: 12.0),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDropDownWithChildren(
    dynamic onchange,
    CommonDropDownItemWithChild? selectedValue,
    List<CommonDropDownItemWithChild> itemList, {
    double? width,
  }) {
    return Focus(
      onFocusChange: (hasFocus) {},
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: MyTheme.accent_color,
            style: BorderStyle.solid,
            width: 0.2,
          ),
          boxShadow: [
            BoxShadow(
              color: MyTheme.white.withValues(alpha: .15),
              blurRadius: 20,
              spreadRadius: 0.0,
              offset: const Offset(0.0, 10.0),
            ),
          ],
        ),
        child: DropdownButton<CommonDropDownItemWithChild>(
          menuMaxHeight: 300,
          isDense: true,
          underline: Container(),
          isExpanded: true,
          onChanged: (CommonDropDownItemWithChild? value) {
            onchange(value);
          },
          icon: const Icon(Icons.arrow_drop_down),
          value: selectedValue,
          items: itemList
              .map(
                (value) => DropdownMenuItem<CommonDropDownItemWithChild>(
                  value: value,
                  child: Text(
                    value.value!,
                    style: TextStyle(color: MyTheme.font_grey, fontSize: 12.0),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  setChange() {
    setState(() {});
  }

  Widget buildTagsEditTextField(
    String title,
    String hint,
    TextEditingController textEditingController, {
    isMandatory = false,
  }) {
    return buildCommonSingleField(
      title,
      Container(
        padding: const EdgeInsets.only(top: 10, bottom: 8, left: 10, right: 10),
        alignment: Alignment.centerLeft,
        constraints: BoxConstraints(minWidth: DeviceInfo(context).width!),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: MyTheme.accent_color,
            style: BorderStyle.solid,
            width: 0.2,
          ),
          boxShadow: [
            BoxShadow(
              color: MyTheme.white.withValues(alpha: .15),
              blurRadius: 20,
              spreadRadius: 0.0,
              offset: const Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          runAlignment: WrapAlignment.start,
          clipBehavior: Clip.antiAlias,
          children: List.generate(tags.length + 1, (index) {
            if (index == tags.length) {
              return TextField(
                onSubmitted: (string) {
                  var tag = textEditingController.text
                      .trim()
                      .replaceAll(",", "")
                      .toString();
                  if (tag.isNotEmpty) addTag(tag);
                },
                onChanged: (string) {
                  if (string.trim().contains(",")) {
                    var tag = string.trim().replaceAll(",", "").toString();
                    if (tag.isNotEmpty) addTag(tag);
                  }
                },
                controller: textEditingController,
                keyboardType: TextInputType.text,
                maxLines: 1,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: AppLocalizations.of(
                    context,
                  )!.type_and_hit_submit_ucf,
                  hintStyle: const TextStyle(fontSize: 12),
                  constraints: const BoxConstraints(maxWidth: 150),
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: MyTheme.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(width: 2, color: MyTheme.grey_153),
              ),
              constraints: BoxConstraints(
                maxWidth: (DeviceInfo(context).width! - 50) / 4,
              ),
              margin: const EdgeInsets.only(right: 5, bottom: 5),
              child: Stack(
                fit: StackFit.loose,
                children: [
                  Container(
                    padding: const EdgeInsets.only(
                      left: 10,
                      right: 20,
                      top: 5,
                      bottom: 5,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: (DeviceInfo(context).width! - 50) / 4,
                    ),
                    child: Text(
                      tags[index].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    child: InkWell(
                      onTap: () {
                        tags.removeAt(index);
                        setChange();
                      },
                      child: Icon(
                        Icons.highlight_remove,
                        size: 15,
                        color: MyTheme.cinnabar,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
      isMandatory: isMandatory,
    );
  }

  addTag(String string) {
    if (string.trim().isNotEmpty) {
      tags.add(string.trim());
    }
    tagEditTextController.clear();
    setChange();
  }

  Widget buildGroupItems(groupTitle, Widget children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildGroupTitle(groupTitle),
        itemSpacer(height: 14.0),
        children,
      ],
    );
  }

  Text buildGroupTitle(title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: MyTheme.font_grey,
      ),
    );
  }

  summerNote(title) {
    if (productDescriptionKey.currentState != null) {
      productDescriptionKey.currentState!.getText().then((value) {
        description = value;
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: MyTheme.font_grey,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          width: double.infinity,
          child: FlutterSummernote(
            showBottomToolbar: false,
            value: description,
            key: productDescriptionKey,
          ),
        ),
      ],
    );
  }

  pickGalleryImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isPermissionAgreed =
        prefs.getBool('gallery_permission_agreed') ?? false;

    if (!isPermissionAgreed) {
      String purpose =
          "To upload product gallery images, this app needs to access your photos.";
      bool userAgreed = await _showDisclosureDialog(purpose);

      if (userAgreed) {
        await prefs.setBool('gallery_permission_agreed', true);
      } else {
        ToastComponent.showDialog("Permission denied to access photos.");
        return;
      }
    }
    List<FileInfo> tmp = List.from(productGalleryImages);
    if (!mounted) return;
    List<FileInfo>? images = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadFile(
          fileType: "image",
          canSelect: true,
          canMultiSelect: true,
          prevData: tmp,
        ),
      ),
    );

    if (images != null) {
      setState(() {
        productGalleryImages.clear();
        productGalleryImages.addAll(images);
      });
      setProductPhotoValue();
    }
  }

  Widget chooseGalleryImageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.gallery_images,
              style: TextStyle(
                fontSize: 12,
                color: MyTheme.font_grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () {
                pickGalleryImages();
              },
              child: MyWidget().myContainer(
                width: DeviceInfo(context).width!,
                height: 36,
                borderRadius: 6.0,
                borderColor: MyTheme.accent_color,
                borderWith: 0.2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 14.0),
                      child: Text(
                        AppLocalizations.of(context)!.choose_file,
                        style: TextStyle(fontSize: 12, color: MyTheme.grey_153),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      height: 46,
                      width: 80,
                      color: MyTheme.light_grey,
                      child: Text(
                        AppLocalizations.of(context)!.browse,
                        style: TextStyle(fontSize: 12, color: MyTheme.grey_153),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (productGalleryImages.isNotEmpty)
          Wrap(
            children: List.generate(
              productGalleryImages.length,
              (index) => Stack(
                children: [
                  MyWidget.imageWithPlaceholder(
                    height: 60.0,
                    width: 60.0,
                    url: productGalleryImages[index].url,
                  ),
                  Positioned(
                    top: 0,
                    right: 5,
                    child: Container(
                      height: 15,
                      width: 15,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: MyTheme.white,
                      ),
                      child: InkWell(
                        onTap: () {
                          productGalleryImages.removeAt(index);
                          setState(() {});
                        },
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: MyTheme.cinnabar,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class CommonDropDownItem {
  String? key, value;
  CommonDropDownItem(this.key, this.value);
}

class CommonDropDownItemWithChild {
  String? key, value, levelText;
  int? level;
  List<CommonDropDownItemWithChild> children;

  CommonDropDownItemWithChild({
    this.key,
    this.value,
    this.levelText,
    this.children = const [],
    this.level,
  });

  setLevelText() {
    String tmpTxt = "";
    for (int i = 0; i < level!; i++) {
      tmpTxt += "–";
    }
    levelText = "$tmpTxt $levelText";
  }
}
