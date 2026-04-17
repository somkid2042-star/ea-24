import 'dart:async';
import 'dart:convert';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/address_repository.dart';

class MapPlacePickerNoHeader extends StatefulWidget {
  final dynamic address;
  final String googleApiKey;

  const MapPlacePickerNoHeader({
    super.key,
    required this.googleApiKey,
    this.address,
  });

  @override
  State<MapPlacePickerNoHeader> createState() => _MapPlacePickerNoHeaderState();
}

class _MapPlacePickerNoHeaderState extends State<MapPlacePickerNoHeader> {
  final Completer<GoogleMapController> _mapController = Completer();

  LatLng _defaultLatLng = const LatLng(23.8103, 90.4125);
  LatLng? _pickedLatLng;

  bool _loading = true;
  bool _saving = false;
  bool _showAddButton = false;

  final String autoUrl =
      "https://maps.googleapis.com/maps/api/place/autocomplete/json";
  final String detailsUrl =
      "https://maps.googleapis.com/maps/api/place/details/json";

  @override
  void initState() {
    super.initState();
    loadInitialLocation();
  }

  Future<void> loadInitialLocation() async {
    try {
      if (widget.address != null &&
          widget.address.lat != null &&
          widget.address.lng != null) {
        _defaultLatLng = LatLng(widget.address.lat, widget.address.lng);
        _pickedLatLng = _defaultLatLng;
      } else {
        final pos = await Geolocator.getCurrentPosition();
        _defaultLatLng = LatLng(pos.latitude, pos.longitude);
        _pickedLatLng = _defaultLatLng;
      }
    } catch (_) {
      _defaultLatLng = const LatLng(23.8103, 90.4125);
      _pickedLatLng = _defaultLatLng;
    }

    setState(() => _loading = false);
  }

  //  Autocomplete
  Future<List<dynamic>> searchAutocomplete(String input) async {
    if (input.isEmpty) return [];

    final url = "$autoUrl?input=$input&key=${widget.googleApiKey}&language=en";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return [];

    final json = jsonDecode(response.body);
    if (json["status"] != "OK") return [];

    return json["predictions"];
  }

  //  Place → LatLng
  Future<LatLng?> getLatLng(String placeId) async {
    final url =
        "$detailsUrl?place_id=$placeId&key=${widget.googleApiKey}&fields=geometry";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body);
    if (json["status"] != "OK") return null;

    final loc = json["result"]["geometry"]["location"];
    return LatLng(loc["lat"], loc["lng"]);
  }

  Future<void> moveCamera(LatLng target) async {
    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 16)),
    );
  }

  // Save location
  Future<void> saveLocation() async {
    if (_pickedLatLng == null) return;

    setState(() => _saving = true);

    try {
      final id = widget.address?.id;

      await AddressRepository().getAddressUpdateLocationResponse(
        id,
        _pickedLatLng!.latitude,
        _pickedLatLng!.longitude,
      );

      if (!mounted) return;
      Navigator.pop(context, {
        "ok": true,
        "lat": _pickedLatLng!.latitude,
        "lng": _pickedLatLng!.longitude,
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update location")),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pick Location",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: MyTheme.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),

      // ADD BUTTON (BOTTOM)
      floatingActionButton: _showAddButton
          ? SizedBox(
              width: MediaQuery.of(context).size.width * .9,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyTheme.accent_color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _saving ? null : saveLocation,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Add this location",
                        style: TextStyle(
                          fontSize: 16,
                          color: MyTheme.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔎 SEARCH
                // Padding(
                //   padding: const EdgeInsets.all(10),
                //   child: TypeAheadField(
                //     controller: _searchController,
                //     suggestionsCallback: searchAutocomplete,
                //     builder: (context, controller, focusNode) {
                //       return TextField(
                //         controller: controller,
                //         focusNode: focusNode,
                //         decoration: const InputDecoration(
                //           prefixIcon: Icon(Icons.search),
                //           hintText: "Search location",
                //           border: OutlineInputBorder(),
                //         ),
                //       );
                //     },
                //     itemBuilder: (context, suggestion) {
                //       return ListTile(title: Text(suggestion["description"]));
                //     },
                //     onSelected: (suggestion) async {
                //       final latLng = await getLatLng(suggestion["place_id"]);
                //       if (latLng != null) {
                //         setState(() {
                //           _pickedLatLng = latLng;
                //           _showAddButton = true;
                //         });
                //         moveCamera(latLng);
                //       }
                //     },
                //   ),
                // ),

                // 🗺 MAP
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _defaultLatLng,
                      zoom: 15,
                    ),
                    onTap: (pos) {
                      setState(() {
                        _pickedLatLng = pos;
                        _showAddButton = true;
                      });
                    },
                    onMapCreated: (controller) {
                      if (!_mapController.isCompleted) {
                        _mapController.complete(controller);
                      }
                    },
                    markers: _pickedLatLng == null
                        ? {}
                        : {
                            Marker(
                              markerId: const MarkerId("picked_location"),
                              position: _pickedLatLng!,
                            ),
                          },
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    zoomControlsEnabled: false,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
              ],
            ),
    );
  }
}
