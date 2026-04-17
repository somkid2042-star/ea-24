// import 'package:ea24_mobile/custom/box_decorations.dart';
// import 'package:ea24_mobile/custom/btn.dart';
// import 'package:ea24_mobile/custom/device_info.dart';
// import 'package:ea24_mobile/custom/enum_classes.dart';
// import 'package:ea24_mobile/custom/lang_text.dart';
// import 'package:ea24_mobile/custom/toast_component.dart';
// import 'package:ea24_mobile/custom/useful_elements.dart';
// import 'package:ea24_mobile/data_model/delivery_info_response.dart';
// import 'package:ea24_mobile/helpers/shared_value_helper.dart';
// import 'package:ea24_mobile/helpers/shimmer_helper.dart';
// import 'package:ea24_mobile/helpers/system_config.dart';
// import 'package:ea24_mobile/l10n/app_localizations.dart';
// import 'package:ea24_mobile/my_theme.dart';
// import 'package:ea24_mobile/repositories/address_repository.dart';
// import 'package:ea24_mobile/repositories/shipping_repository.dart';
// import 'package:ea24_mobile/screens/checkout/checkout.dart';
// import 'package:flutter/material.dart';
//
// class ShippingInfo extends StatefulWidget {
//   final String? guestCheckOutShippingAddress;
//
//   const ShippingInfo({super.key, this.guestCheckOutShippingAddress});
//
//   @override
//   State<ShippingInfo> createState() => _ShippingInfoState();
// }
//
// class _ShippingInfoState extends State<ShippingInfo> {
//   final ScrollController _mainScrollController = ScrollController();
//   final List<SellerWithShipping> _sellerWiseShippingOption = [];
//   List<DeliveryInfoResponse> _deliveryInfoList = [];
//   String? _shippingCostString = ". . .";
//   bool _isFetchDeliveryInfo = false;
//   double mWidth = 0;
//   double mHeight = 0;
//
//   fetchAll() {
//     getDeliveryInfo();
//   }
//
//   getDeliveryInfo() async {
//     _deliveryInfoList = await (ShippingRepository().getDeliveryInfo(
//       guestAddress: widget.guestCheckOutShippingAddress,
//     ));
//     _isFetchDeliveryInfo = true;
//
//     for (var element in _deliveryInfoList) {
//       ShippingOption shippingOption;
//       int? shippingId;
//       bool isAllDigital =
//           element.cartItems?.every((item) => item.isDigital ?? false) ?? false;
//       bool hasCarriers = element.carriers?.data?.isNotEmpty ?? false;
//       if (hasCarriers && !isAllDigital) {
//         shippingOption = ShippingOption.Carrier;
//         shippingId = element.carriers!.data!.first.id;
//       } else {
//         shippingOption = ShippingOption.HomeDelivery;
//         shippingId = null;
//       }
//
//       _sellerWiseShippingOption.add(
//         SellerWithShipping(
//           element.ownerId,
//           shippingOption,
//           shippingId,
//           isAllDigital: isAllDigital,
//         ),
//       );
//     }
//
//     getSetShippingCost();
//     setState(() {});
//   }
//
//   getSetShippingCost() async {
//     var shippingCostResponse = await AddressRepository()
//         .getShippingCostResponse(shippingType: _sellerWiseShippingOption);
//
//     if (shippingCostResponse.result == true &&
//         shippingCostResponse.valueString != null) {
//       _shippingCostString = shippingCostResponse.valueString;
//     } else {
//       _shippingCostString = "0.0";
//     }
//     setState(() {});
//   }
//
//   resetData() {
//     clearData();
//     fetchAll();
//   }
//
//   clearData() {
//     _deliveryInfoList.clear();
//     _sellerWiseShippingOption.clear();
//     _shippingCostString = ". . .";
//     _isFetchDeliveryInfo = false;
//     setState(() {});
//   }
//
//   Future<void> _onRefresh() async {
//     clearData();
//     fetchAll();
//   }
//
//   onPopped(value) async {
//     resetData();
//   }
//
//   changeShippingOption(ShippingOption option, int sellerIndex) {
//     _sellerWiseShippingOption[sellerIndex].shippingOption = option;
//     _sellerWiseShippingOption[sellerIndex].shippingId = null;
//
//     if (option == ShippingOption.PickUpPoint) {
//       if (_deliveryInfoList[sellerIndex].pickupPoints!.isNotEmpty) {
//         _sellerWiseShippingOption[sellerIndex].shippingId =
//             _deliveryInfoList[sellerIndex].pickupPoints!.first.id;
//       }
//     } else if (option == ShippingOption.Carrier) {
//       if (_deliveryInfoList[sellerIndex].carriers!.data!.isNotEmpty) {
//         _sellerWiseShippingOption[sellerIndex].shippingId =
//             _deliveryInfoList[sellerIndex].carriers!.data!.first.id;
//       }
//     }
//     getSetShippingCost();
//     setState(() {});
//   }
//
//   onPressProceed(context) async {
//     bool hasError = _sellerWiseShippingOption.any(
//       (seller) =>
//           !seller.isAllDigital &&
//           seller.shippingOption != ShippingOption.HomeDelivery &&
//           seller.shippingId == null,
//     );
//
//     if (hasError) {
//       ToastComponent.showDialog(
//         LangText(context).local.please_choose_valid_info,
//       );
//       return;
//     }
//     var shippingCostResponse = await AddressRepository()
//         .getShippingCostResponse(shippingType: _sellerWiseShippingOption);
//
//     if (shippingCostResponse.result == false) {
//       ToastComponent.showDialog(LangText(context).local.network_error);
//       return;
//     }
//
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) {
//           return Checkout(
//             title: AppLocalizations.of(context)!.checkout_ucf,
//             paymentFor: PaymentFor.order,
//             guestCheckOutShippingAddress: widget.guestCheckOutShippingAddress,
//           );
//         },
//       ),
//     ).then((value) {
//       onPopped(value);
//     });
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     fetchAll();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     _mainScrollController.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     mHeight = MediaQuery.of(context).size.height;
//     mWidth = MediaQuery.of(context).size.width;
//     return Directionality(
//       textDirection: app_language_rtl.$!
//           ? TextDirection.rtl
//           : TextDirection.ltr,
//       child: Scaffold(
//
//         appBar: customAppBar(context) as PreferredSizeWidget?,
//         bottomNavigationBar: buildBottomAppBar(context),
//         body: buildBody(context),
//       ),
//     );
//   }
//
//   RefreshIndicator buildBody(BuildContext context) {
//     return RefreshIndicator(
//       color: MyTheme.accent_color,
//       backgroundColor: Colors.white,
//       onRefresh: _onRefresh,
//       displacement: 0,
//       child: buildBodyChildren(context),
//     );
//   }
//
//   Widget buildBodyChildren(BuildContext context) {
//     return buildCartSellerList();
//   }
//
//   Widget buildShippingListBody(sellerIndex) {
//     switch (_sellerWiseShippingOption[sellerIndex].shippingOption) {
//       case ShippingOption.PickUpPoint:
//         return buildPickupPoint(sellerIndex);
//       case ShippingOption.Carrier:
//         return buildCarrierSection(sellerIndex);
//       default:
//         return Container();
//     }
//   }
//
//   Widget buildPickupPoint(sellerArrayIndex) {
//     if (!_isFetchDeliveryInfo) {
//       return buildCarrierShimmer();
//     } else if (_deliveryInfoList[sellerArrayIndex].pickupPoints!.isNotEmpty) {
//       return ListView.separated(
//         separatorBuilder: (context, index) => const SizedBox(height: 14),
//         itemCount: _deliveryInfoList[sellerArrayIndex].pickupPoints!.length,
//         physics: const NeverScrollableScrollPhysics(),
//         shrinkWrap: true,
//         itemBuilder: (context, index) {
//           return buildPickupPointItemCard(index, sellerArrayIndex);
//         },
//       );
//     } else {
//       return SizedBox(
//         height: 100,
//         child: Center(
//           child: Text(
//             AppLocalizations.of(context)!.pickup_point_is_unavailable_ucf,
//             style: TextStyle(color: MyTheme.font_grey),
//           ),
//         ),
//       );
//     }
//   }
//
//   GestureDetector buildPickupPointItemCard(pickupPointIndex, sellerArrayIndex) {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _sellerWiseShippingOption[sellerArrayIndex].shippingId =
//               _deliveryInfoList[sellerArrayIndex]
//                   .pickupPoints![pickupPointIndex]
//                   .id;
//         });
//         getSetShippingCost();
//       },
//       child: Container(
//         decoration: BoxDecorations.buildBoxDecoration_1(radius: 8).copyWith(
//           border:
//               _sellerWiseShippingOption[sellerArrayIndex].shippingId ==
//                   _deliveryInfoList[sellerArrayIndex]
//                       .pickupPoints![pickupPointIndex]
//                       .id
//               ? Border.all(color: MyTheme.accent_color, width: 1.0)
//               : Border.all(color: MyTheme.light_grey, width: 1.0),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: buildPickUpPointInfoItemChildren(
//             pickupPointIndex,
//             sellerArrayIndex,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Column buildPickUpPointInfoItemChildren(pickupPointIndex, sellerArrayIndex) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(bottom: 8.0),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               SizedBox(
//                 width: 75,
//                 child: Text(
//                   AppLocalizations.of(context)!.address_ucf,
//                   style: TextStyle(fontSize: 13, color: MyTheme.dark_font_grey),
//                 ),
//               ),
//               SizedBox(
//                 width: 175,
//                 child: Text(
//                   _deliveryInfoList[sellerArrayIndex]
//                       .pickupPoints![pickupPointIndex]
//                       .name!,
//                   maxLines: 2,
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: MyTheme.dark_grey,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//               const Spacer(),
//               buildShippingSelectMarkContainer(
//                 _sellerWiseShippingOption[sellerArrayIndex].shippingId ==
//                     _deliveryInfoList[sellerArrayIndex]
//                         .pickupPoints![pickupPointIndex]
//                         .id,
//               ),
//             ],
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.only(bottom: 8.0),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               SizedBox(
//                 width: 75,
//                 child: Text(
//                   AppLocalizations.of(context)!.phone_ucf,
//                   style: TextStyle(fontSize: 13, color: MyTheme.dark_font_grey),
//                 ),
//               ),
//               SizedBox(
//                 width: 200,
//                 child: Text(
//                   _deliveryInfoList[sellerArrayIndex]
//                       .pickupPoints![pickupPointIndex]
//                       .phone!,
//                   maxLines: 2,
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: MyTheme.dark_grey,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget buildCarrierSection(sellerArrayIndex) {
//     if (!_isFetchDeliveryInfo) {
//       return buildCarrierShimmer();
//     } else if (_deliveryInfoList[sellerArrayIndex].carriers!.data!.isNotEmpty) {
//       return buildCarrierListView(sellerArrayIndex);
//     } else {
//       return buildCarrierNoData();
//     }
//   }
//
//   SizedBox buildCarrierNoData() {
//     return SizedBox(
//       height: 100,
//       child: Center(
//         child: Text(
//           AppLocalizations.of(context)!.carrier_points_is_unavailable_ucf,
//           style: TextStyle(color: MyTheme.font_grey),
//         ),
//       ),
//     );
//   }
//
//   Widget buildCarrierListView(sellerArrayIndex) {
//     return ListView.separated(
//       itemCount: _deliveryInfoList[sellerArrayIndex].carriers!.data!.length,
//       separatorBuilder: (context, index) {
//         return const SizedBox(height: 14);
//       },
//       physics: const NeverScrollableScrollPhysics(),
//       shrinkWrap: true,
//       itemBuilder: (context, index) {
//         return buildCarrierItemCard(index, sellerArrayIndex);
//       },
//     );
//   }
//
//   Widget buildCarrierShimmer() {
//     return ShimmerHelper().buildListShimmer(itemCount: 2, itemHeight: 50.0);
//   }
//
//   GestureDetector buildCarrierItemCard(carrierIndex, sellerArrayIndex) {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _sellerWiseShippingOption[sellerArrayIndex].shippingId =
//               _deliveryInfoList[sellerArrayIndex]
//                   .carriers!
//                   .data![carrierIndex]
//                   .id;
//         });
//         getSetShippingCost();
//       },
//       child: Container(
//         decoration: BoxDecorations.buildBoxDecoration_1(radius: 8).copyWith(
//           border:
//               _sellerWiseShippingOption[sellerArrayIndex].shippingId ==
//                   _deliveryInfoList[sellerArrayIndex]
//                       .carriers!
//                       .data![carrierIndex]
//                       .id
//               ? Border.all(color: MyTheme.accent_color, width: 1.0)
//               : Border.all(color: MyTheme.light_grey, width: 1.0),
//         ),
//         child: buildCarrierInfoItemChildren(carrierIndex, sellerArrayIndex),
//       ),
//     );
//   }
//
//   Widget buildCarrierInfoItemChildren(carrierIndex, sellerArrayIndex) {
//     return Stack(
//       children: [
//         SizedBox(
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               SizedBox(width: 10),
//               SizedBox(
//                 height: 75.0,
//                 width: 75.0,
//                 child: FadeInImage.assetNetwork(
//                   placeholder: 'assets/placeholder.png',
//                   image: _deliveryInfoList[sellerArrayIndex]
//                       .carriers!
//                       .data![carrierIndex]
//                       .logo!,
//                   fit: BoxFit.fitWidth,
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(left: 20.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     SizedBox(
//                       width: DeviceInfo(context).width! / 3,
//                       child: Text(
//                         _deliveryInfoList[sellerArrayIndex]
//                             .carriers!
//                             .data![carrierIndex]
//                             .name!,
//                         maxLines: 2,
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: MyTheme.dark_font_grey,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.only(top: 10),
//                       child: Text(
//                         "${_deliveryInfoList[sellerArrayIndex].carriers!.data![carrierIndex].transitTime} ${LangText(context).local.day_ucf}",
//                         maxLines: 2,
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: MyTheme.dark_font_grey,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const Spacer(),
//               Text(
//                 _deliveryInfoList[sellerArrayIndex]
//                     .carriers!
//                     .data![carrierIndex]
//                     .transitPrice!,
//                 maxLines: 2,
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: MyTheme.dark_font_grey,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(width: 16),
//             ],
//           ),
//         ),
//         Positioned(
//           right: 16,
//           top: 10,
//           child: buildShippingSelectMarkContainer(
//             _sellerWiseShippingOption[sellerArrayIndex].shippingId ==
//                 _deliveryInfoList[sellerArrayIndex]
//                     .carriers!
//                     .data![carrierIndex]
//                     .id,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Container buildShippingSelectMarkContainer(bool check) {
//     return check
//         ? Container(
//             height: 16,
//             width: 16,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(16.0),
//               color: Colors.green,
//             ),
//             child: const Padding(
//               padding: EdgeInsets.all(3),
//               child: Icon(Icons.check, color: Colors.white, size: 10),
//             ),
//           )
//         : Container();
//   }
//
//   BottomAppBar buildBottomAppBar(BuildContext context) {
//     return BottomAppBar(
//       color: Colors.transparent,
//       elevation: 0,
//       child: SizedBox(
//         height: 50,
//         child: Btn.minWidthFixHeight(
//           minWidth: MediaQuery.of(context).size.width,
//           height: 50,
//           color: MyTheme.accent_color,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(0.0),
//           ),
//           child: Text(
//             AppLocalizations.of(context)!.proceed_to_checkout,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           onPressed: () {
//             onPressProceed(context);
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget customAppBar(BuildContext context) {
//     return AppBar(
//       elevation: 0,
//       backgroundColor: MyTheme.white,
//       automaticallyImplyLeading: false,
//       title: buildAppbarTitle(context),
//       leading: UsefulElements.backButton(context),
//     );
//   }
//
//   SizedBox buildAppbarTitle(BuildContext context) {
//     return SizedBox(
//       width: MediaQuery.of(context).size.width - 40,
//       child: Text(
//         "${AppLocalizations.of(context)!.shipping_cost_ucf} ${SystemConfig.systemCurrency != null ? _shippingCostString!.replaceAll(SystemConfig.systemCurrency!.code!, SystemConfig.systemCurrency!.symbol!) : _shippingCostString}",
//         style: TextStyle(
//           fontSize: 16,
//           color: MyTheme.dark_font_grey,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }
//
//   Widget buildChooseShippingOptions(BuildContext context, int sellerIndex) {
//     bool hasCarriers =
//         _deliveryInfoList[sellerIndex].carriers?.data?.isNotEmpty ?? false;
//
//     return Container(
//       color: MyTheme.white,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           hasCarriers
//               ? buildCarrierOption(context, sellerIndex)
//               : buildAddressOption(context, sellerIndex),
//           const SizedBox(width: 14),
//           if (pick_up_status.$) buildPickUpPointOption(context, sellerIndex),
//         ],
//       ),
//     );
//   }
//
//   Widget buildPickUpPointOption(BuildContext context, sellerIndex) {
//     return Btn.basic(
//       color:
//           _sellerWiseShippingOption[sellerIndex].shippingOption ==
//               ShippingOption.PickUpPoint
//           ? MyTheme.accent_color
//           : MyTheme.accent_color.withValues(alpha: 0.1),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(6),
//         side: const BorderSide(color: MyTheme.accent_color),
//       ),
//       padding: const EdgeInsets.only(right: 14),
//       onPressed: () {
//         changeShippingOption(ShippingOption.PickUpPoint, sellerIndex);
//       },
//       child: SizedBox(
//         height: 30,
//         child: Row(
//           children: [
//             RadioGroup<ShippingOption>(
//               groupValue: _sellerWiseShippingOption[sellerIndex].shippingOption,
//               onChanged: (ShippingOption? newOption) {
//                 if (newOption == null) return;
//                 changeShippingOption(newOption, sellerIndex);
//               },
//               child: Radio<ShippingOption>(
//                 materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                 fillColor: WidgetStateProperty.resolveWith((states) {
//                   return states.contains(WidgetState.selected)
//                       ? MyTheme.white
//                       : MyTheme.accent_color;
//                 }),
//                 value: ShippingOption.PickUpPoint,
//               ),
//             ),
//
//             Text(
//               AppLocalizations.of(context)!.pickup_point_ucf,
//               style: TextStyle(
//                 fontSize: 12,
//                 color:
//                     _sellerWiseShippingOption[sellerIndex].shippingOption ==
//                         ShippingOption.PickUpPoint
//                     ? MyTheme.white
//                     : MyTheme.accent_color,
//                 fontWeight:
//                     _sellerWiseShippingOption[sellerIndex].shippingOption ==
//                         ShippingOption.PickUpPoint
//                     ? FontWeight.w700
//                     : FontWeight.normal,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget buildAddressOption(BuildContext context, sellerIndex) {
//     return Btn.basic(
//       color:
//           _sellerWiseShippingOption[sellerIndex].shippingOption ==
//               ShippingOption.HomeDelivery
//           ? MyTheme.accent_color
//           : MyTheme.accent_color.withValues(alpha: 0.1),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(6),
//         side: const BorderSide(color: MyTheme.accent_color),
//       ),
//       padding: const EdgeInsets.only(right: 14),
//       onPressed: () {
//         changeShippingOption(ShippingOption.HomeDelivery, sellerIndex);
//       },
//       child: SizedBox(
//         height: 30,
//         child: Row(
//           children: [
//             RadioGroup<ShippingOption>(
//               groupValue: _sellerWiseShippingOption[sellerIndex].shippingOption,
//               onChanged: (ShippingOption? newOption) {
//                 if (newOption == null) return;
//                 changeShippingOption(newOption, sellerIndex);
//               },
//               child: Radio<ShippingOption>(
//                 materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                 fillColor: WidgetStateProperty.resolveWith((states) {
//                   return states.contains(WidgetState.selected)
//                       ? MyTheme.white
//                       : MyTheme.accent_color;
//                 }),
//                 value: ShippingOption.HomeDelivery,
//               ),
//             ),
//
//             Text(
//               AppLocalizations.of(context)!.home_delivery_ucf,
//               style: TextStyle(
//                 fontSize: 12,
//                 color:
//                     _sellerWiseShippingOption[sellerIndex].shippingOption ==
//                         ShippingOption.HomeDelivery
//                     ? MyTheme.white
//                     : MyTheme.accent_color,
//                 fontWeight:
//                     _sellerWiseShippingOption[sellerIndex].shippingOption ==
//                         ShippingOption.HomeDelivery
//                     ? FontWeight.w700
//                     : FontWeight.normal,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget buildCarrierOption(BuildContext context, sellerIndex) {
//     return Btn.basic(
//       color:
//           _sellerWiseShippingOption[sellerIndex].shippingOption ==
//               ShippingOption.Carrier
//           ? MyTheme.accent_color
//           : MyTheme.accent_color.withValues(alpha: 0.1),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(6),
//         side: const BorderSide(color: MyTheme.accent_color),
//       ),
//       padding: const EdgeInsets.only(right: 14),
//       onPressed: () {
//         changeShippingOption(ShippingOption.Carrier, sellerIndex);
//       },
//       child: SizedBox(
//         height: 30,
//         child: Row(
//           children: [
//             RadioGroup<ShippingOption>(
//               groupValue: _sellerWiseShippingOption[sellerIndex].shippingOption,
//               onChanged: (ShippingOption? newOption) {
//                 if (newOption == null) return;
//                 changeShippingOption(newOption, sellerIndex);
//               },
//               child: Radio<ShippingOption>(
//                 materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                 fillColor: WidgetStateProperty.resolveWith((states) {
//                   return states.contains(WidgetState.selected)
//                       ? MyTheme.white
//                       : MyTheme.accent_color;
//                 }),
//                 value: ShippingOption.Carrier,
//               ),
//             ),
//             Text(
//               AppLocalizations.of(context)!.carrier_ucf,
//               style: TextStyle(
//                 fontSize: 12,
//                 color:
//                     _sellerWiseShippingOption[sellerIndex].shippingOption ==
//                         ShippingOption.Carrier
//                     ? MyTheme.white
//                     : MyTheme.accent_color,
//                 fontWeight:
//                     _sellerWiseShippingOption[sellerIndex].shippingOption ==
//                         ShippingOption.Carrier
//                     ? FontWeight.w700
//                     : FontWeight.normal,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget buildCartSellerList() {
//     if (!_isFetchDeliveryInfo) {
//       return ShimmerHelper().buildListShimmer(itemCount: 1, itemHeight: 200.0);
//     } else if (_deliveryInfoList.isNotEmpty) {
//       return buildCartSellerListBody();
//     } else {
//       return SizedBox(
//         height: 100,
//         child: Center(
//           child: Text(
//             AppLocalizations.of(context)!.cart_is_empty,
//             style: TextStyle(color: MyTheme.font_grey),
//           ),
//         ),
//       );
//     }
//   }
//
//   SingleChildScrollView buildCartSellerListBody() {
//     return SingleChildScrollView(
//       controller: _mainScrollController,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 18.0),
//         child: ListView.separated(
//           padding: const EdgeInsets.only(bottom: 20, top: 10),
//           separatorBuilder: (context, index) => const SizedBox(height: 26),
//           itemCount: _deliveryInfoList.length,
//           physics: const NeverScrollableScrollPhysics(),
//           shrinkWrap: true,
//           itemBuilder: (context, index) {
//             return buildCartSellerListItem(index, context);
//           },
//         ),
//       ),
//     );
//   }
//
//   Column buildCartSellerListItem(int index, BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(bottom: 12.0),
//           child: Text(
//             _deliveryInfoList[index].name!,
//             style: const TextStyle(
//               color: MyTheme.accent_color,
//               fontWeight: FontWeight.w700,
//               fontSize: 16,
//             ),
//           ),
//         ),
//         buildCartSellerItemList(index),
//         if (!_sellerWiseShippingOption[index].isAllDigital)
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(top: 18.0),
//                 child: Text(
//                   LangText(context).local.choose_delivery_ucf,
//                   style: TextStyle(
//                     color: MyTheme.dark_font_grey,
//                     fontWeight: FontWeight.w700,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 5),
//               buildChooseShippingOptions(context, index),
//               const SizedBox(height: 10),
//               buildShippingListBody(index),
//             ],
//           ),
//       ],
//     );
//   }
//
//   SingleChildScrollView buildCartSellerItemList(sellerIndex) {
//     return SingleChildScrollView(
//       child: ListView.separated(
//         separatorBuilder: (context, index) => const SizedBox(height: 14),
//         itemCount: _deliveryInfoList[sellerIndex].cartItems!.length,
//         physics: const NeverScrollableScrollPhysics(),
//         shrinkWrap: true,
//         itemBuilder: (context, index) {
//           return buildCartSellerItemCard(index, sellerIndex);
//         },
//       ),
//     );
//   }
//
//   buildCartSellerItemCard(itemIndex, sellerIndex) {
//     return Container(
//       height: 80,
//       decoration: BoxDecorations.buildBoxDecoration_1(),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: <Widget>[
//           SizedBox(
//             width: DeviceInfo(context).width! / 4,
//             height: 120,
//             child: ClipRRect(
//               borderRadius: const BorderRadius.horizontal(
//                 left: Radius.circular(6),
//                 right: Radius.zero,
//               ),
//               child: FadeInImage.assetNetwork(
//                 placeholder: 'assets/placeholder.png',
//                 image: _deliveryInfoList[sellerIndex]
//                     .cartItems![itemIndex]
//                     .productThumbnailImage!,
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           const SizedBox(width: 10),
//           SizedBox(
//             width: DeviceInfo(context).width! / 2,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 10.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     _deliveryInfoList[sellerIndex]
//                         .cartItems![itemIndex]
//                         .productName!,
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 2,
//                     style: const TextStyle(
//                       color: MyTheme.font_grey,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w400,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Enum and Class definitions remain the same
// // ignore: constant_identifier_names
// enum ShippingOption { HomeDelivery, PickUpPoint, Carrier }
//
// class SellerWithShipping {
//   int? sellerId;
//   ShippingOption shippingOption;
//   int? shippingId;
//   bool isAllDigital;
//
//   SellerWithShipping(
//     this.sellerId,
//     this.shippingOption,
//     this.shippingId, {
//     this.isAllDigital = false,
//   });
//
//   Map toJson() => {
//     'seller_id': sellerId,
//     'shipping_type': shippingOption == ShippingOption.HomeDelivery
//         ? "home_delivery"
//         : shippingOption == ShippingOption.Carrier
//         ? "carrier"
//         : "pickup_point",
//     'shipping_id': shippingId,
//   };
// }
