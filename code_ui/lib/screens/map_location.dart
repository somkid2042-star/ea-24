library;

import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/other_config.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/address_repository.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';

class MapLocation extends StatefulWidget {
  final dynamic address;
  const MapLocation({super.key, this.address});
  @override
  State<MapLocation> createState() => MapLocationState();
}

class MapLocationState extends State<MapLocation>
    with SingleTickerProviderStateMixin {
  PickResult? selectedPlace;
  static LatLng kInitialPosition = LatLng(
    51.52034098371205,
    -0.12637399200000668,
  );

  @override
  void initState() {
    super.initState();

    if (widget.address.location_available) {
      setInitialLocation();
    } else {
      setDummyInitialLocation();
    }
  }

  setInitialLocation() {
    kInitialPosition = LatLng(widget.address.lat, widget.address.lang);
    setState(() {});
  }

  setDummyInitialLocation() {
    kInitialPosition = LatLng(51.52034098371205, -0.12637399200000668);
    setState(() {});
  }

  onTapPickHere(selectedPlace) async {
    var addressUpdateLocationResponse = await AddressRepository()
        .getAddressUpdateLocationResponse(
          widget.address.id,
          selectedPlace.geometry.location.lat,
          selectedPlace.geometry.location.lng,
        );

    if (addressUpdateLocationResponse.result == false) {
      ToastComponent.showDialog(addressUpdateLocationResponse.message);
      return;
    }

    ToastComponent.showDialog(addressUpdateLocationResponse.message);
  }

  @override
  Widget build(BuildContext context) {
    return PlacePicker(
      hintText: AppLocalizations.of(context)!.your_delivery_location,
      apiKey: OtherConfig.GOOGLE_MAP_API_KEY,
      initialPosition: kInitialPosition,
      useCurrentLocation: false,

      onPlacePicked: (result) {
        selectedPlace = result;

        setState(() {});
      },

      selectedPlaceWidgetBuilder:
          (_, selectedPlace, state, isSearchBarFocused) {
            return isSearchBarFocused
                ? Container()
                : FloatingCard(
                    height: 50,
                    bottomPosition: 120.0,

                    leftPosition: 0.0,
                    rightPosition: 0.0,
                    width: 500,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      bottomLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0),
                    ),
                    child: state == SearchingState.Searching
                        ? Center(
                            child: Text(
                              AppLocalizations.of(context)!.calculating,
                              style: TextStyle(color: MyTheme.font_grey),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 2.0,
                                        right: 2.0,
                                      ),
                                      child: Text(
                                        selectedPlace!.formattedAddress!,
                                        maxLines: 2,
                                        style: TextStyle(
                                          color: MyTheme.medium_grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Btn.basic(
                                    color: MyTheme.accent_color,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4.0),
                                        bottomLeft: Radius.circular(4.0),
                                        topRight: Radius.circular(4.0),
                                        bottomRight: Radius.circular(4.0),
                                      ),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.pick_here,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onPressed: () {
                                      onTapPickHere(selectedPlace);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                  );
          },
      pinBuilder: (context, state) {
        if (state == PinState.Idle) {
          return Image.asset('assets/delivery_map_icon.png', height: 60);
        } else {
          return Image.asset('assets/delivery_map_icon.png', height: 80);
        }
      },
    );
  }
}
