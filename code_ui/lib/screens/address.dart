// ignore_for_file: constant_identifier_names, use_build_context_synchronously

import 'dart:async';
import 'package:active_ecommerce_cms_demo_app/custom/box_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/lang_text.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/business_setting_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/city_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/country_response.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/state_response.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/other_config.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/address_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/business_setting_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map/map_picker.dart';
import 'package:flutter/gestures.dart';

class Address extends StatefulWidget {
  final bool fromShippingInfo;
  const Address({super.key, this.fromShippingInfo = false});
  @override
  State<Address> createState() => _AddressState();
}

class _AddressState extends State<Address> {
  final ScrollController _mainScrollController = ScrollController();
  bool _showStateField = true;
  int? _defaultShippingAddress = 0;
  City? _selectedCity;
  Country? _selectedCountry;
  MyState? _selectedState;
  City? _selectedArea;
  bool _isInitial = true;
  final List<dynamic> _shippingAddressList = [];
  bool _isAreaRequired = false;

  //controllers for add purpose
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  // map controllers for Add
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  LatLng? _pickedLocationForAdd;

  //for update purpose
  final List<TextEditingController> _addressControllerListForUpdate = [];
  final List<TextEditingController> _postalCodeControllerListForUpdate = [];
  final List<TextEditingController> _phoneControllerListForUpdate = [];
  final List<TextEditingController> _cityControllerListForUpdate = [];
  final List<TextEditingController> _stateControllerListForUpdate = [];
  final List<TextEditingController> _countryControllerListForUpdate = [];
  final List<TextEditingController> _areaControllerListForUpdate = [];

  // map-related
  final List<TextEditingController> _latitudeControllerListForUpdate = [];
  final List<TextEditingController> _longitudeControllerListForUpdate = [];
  final List<LatLng?> _pickedLocationForUpdate = [];
  bool _isGoogleMapEnabled = true;

  final List<City?> _selectedCityListForUpdate = [];
  final List<MyState?> _selectedStateListForUpdate = [];
  final List<Country> _selectedCountryListForUpdate = [];
  final List<City?> _selectedAreaListForUpdate = [];

  // backend default lat/lng (from business settings)
  double? _backendDefaultLat;
  double? _backendDefaultLng;

  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      fetchAll();
    }
    // load default lat/lng from business settings
    _loadBackendDefaultLocation();
  }

  Future<void> _loadBackendDefaultLocation() async {
    try {
      var settingsResponse = await BusinessSettingRepository()
          .getBusinessSettingList();
      var dataList = settingsResponse.data ?? [];

      // GOOGLE MAP ENABLE FLAG
      final googleMapSetting = dataList.firstWhere(
        (s) => s.type == 'google_map',
        orElse: () => Datum(type: null, value: "0"),
      );

      _isGoogleMapEnabled = googleMapSetting.value == "1";

      // LATITUDE
      final latSetting = dataList.firstWhere(
        (s) => s.type == 'google_map_latitude' || s.type == 'google_map_lat',
        orElse: () => Datum(type: null, value: null),
      );

      // LONGITUDE
      final lngSetting = dataList.firstWhere(
        (s) =>
            s.type == 'google_map_longtitude' ||
            s.type == 'google_map_longitude' ||
            s.type == 'google_map_lng',
        orElse: () => Datum(type: null, value: null),
      );

      if (latSetting.value != null && latSetting.value.toString().isNotEmpty) {
        _backendDefaultLat = double.tryParse(latSetting.value.toString());
      }

      if (lngSetting.value != null && lngSetting.value.toString().isNotEmpty) {
        _backendDefaultLng = double.tryParse(lngSetting.value.toString());
      }
    } catch (_) {}

    if (mounted) setState(() {});
  }

  fetchAll() {
    fetchShippingAddressList();
  }

  fetchShippingAddressList() async {
    var addressResponse = await AddressRepository().getAddressList();
    _shippingAddressList.addAll(addressResponse.addresses);
    _isInitial = false;
    if (_shippingAddressList.isNotEmpty) {
      _addressControllerListForUpdate.clear();
      _postalCodeControllerListForUpdate.clear();
      _phoneControllerListForUpdate.clear();
      _countryControllerListForUpdate.clear();
      _stateControllerListForUpdate.clear();
      _cityControllerListForUpdate.clear();
      _areaControllerListForUpdate.clear();
      _selectedCountryListForUpdate.clear();
      _selectedStateListForUpdate.clear();
      _selectedCityListForUpdate.clear();
      _selectedAreaListForUpdate.clear();

      // map-related lists
      _pickedLocationForUpdate.clear();
      _latitudeControllerListForUpdate.clear();
      _longitudeControllerListForUpdate.clear();

      for (var address in _shippingAddressList) {
        if (address.setDefault == 1) {
          _defaultShippingAddress = address.id;
        }
        _addressControllerListForUpdate.add(
          TextEditingController(text: address.address),
        );
        _postalCodeControllerListForUpdate.add(
          TextEditingController(text: address.postalCode),
        );
        _phoneControllerListForUpdate.add(
          TextEditingController(text: address.phone),
        );
        _countryControllerListForUpdate.add(
          TextEditingController(text: address.countryName),
        );
        _stateControllerListForUpdate.add(
          TextEditingController(text: address.stateName),
        );
        _cityControllerListForUpdate.add(
          TextEditingController(text: address.cityName),
        );
        _areaControllerListForUpdate.add(
          TextEditingController(text: address.areaName ?? ""),
        );

        _selectedCountryListForUpdate.add(
          Country(id: address.countryId, name: address.countryName),
        );
        _selectedStateListForUpdate.add(
          MyState(id: address.stateId, name: address.stateName),
        );
        _selectedCityListForUpdate.add(
          City(id: address.cityId, name: address.cityName),
        );
        _selectedAreaListForUpdate.add(
          City(id: address.areaId, name: address.areaName),
        );

        // parse lat/lng if available on address

        LatLng? loc;
        try {
          final latVal = address.lat;
          final lngVal = address.lng;

          if (latVal != null && lngVal != null) {
            loc = LatLng(latVal, lngVal);
          }
        } catch (e) {
          loc = null;
        }

        _pickedLocationForUpdate.add(loc);
        _latitudeControllerListForUpdate.add(
          TextEditingController(
            text: loc != null ? loc.latitude.toString() : "",
          ),
        );
        _longitudeControllerListForUpdate.add(
          TextEditingController(
            text: loc != null ? loc.longitude.toString() : "",
          ),
        );
      }
    }
    setState(() {});
  }

  reset() {
    _defaultShippingAddress = 0;
    _shippingAddressList.clear();
    _isInitial = true;
    _addressController.clear();
    _postalCodeController.clear();
    _phoneController.clear();
    _countryController.clear();
    _stateController.clear();
    _cityController.clear();
    _areaController.clear();
    _addressControllerListForUpdate.clear();
    _postalCodeControllerListForUpdate.clear();
    _phoneControllerListForUpdate.clear();
    _countryControllerListForUpdate.clear();
    _stateControllerListForUpdate.clear();
    _cityControllerListForUpdate.clear();
    _areaControllerListForUpdate.clear();
    _selectedCityListForUpdate.clear();
    _selectedStateListForUpdate.clear();
    _selectedCountryListForUpdate.clear();
    _selectedAreaListForUpdate.clear();

    // reset map stuff
    _pickedLocationForAdd = null;
    _latitudeController.text = "";
    _longitudeController.text = "";
    _latitudeControllerListForUpdate.clear();
    _longitudeControllerListForUpdate.clear();
    _pickedLocationForUpdate.clear();

    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    if (is_logged_in.$ == true) {
      fetchAll();
    }
  }

  onPopped(value) async {
    reset();
    fetchAll();
  }

  afterAddingAnAddress() {
    reset();
    fetchAll();
  }

  afterDeletingAnAddress() {
    reset();
    fetchAll();
  }

  afterUpdatingAnAddress() {
    reset();
    fetchAll();
  }

  onAddressSwitch(index) async {
    var addressMakeDefaultResponse = await AddressRepository()
        .getAddressMakeDefaultResponse(index);

    if (addressMakeDefaultResponse.result == false) {
      ToastComponent.showDialog(addressMakeDefaultResponse.message);
      return;
    }
    ToastComponent.showDialog(addressMakeDefaultResponse.message);
    setState(() {
      _defaultShippingAddress = index;
    });
  }

  onPressDelete(id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: EdgeInsets.only(
          top: 16.0,
          left: 2.0,
          right: 2.0,
          bottom: 2.0,
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            AppLocalizations.of(context)!.are_you_sure_to_remove_this_address,
            maxLines: 3,
            style: TextStyle(color: MyTheme.font_grey, fontSize: 14),
          ),
        ),
        actions: [
          Btn.basic(
            child: Text(
              AppLocalizations.of(context)!.cancel_ucf,
              style: TextStyle(color: MyTheme.medium_grey),
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
          ),
          Btn.basic(
            color: MyTheme.soft_accent_color,
            child: Text(
              AppLocalizations.of(context)!.confirm_ucf,
              style: TextStyle(color: MyTheme.dark_grey),
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              confirmDelete(id);
            },
          ),
        ],
      ),
    );
  }

  confirmDelete(id) async {
    var addressDeleteResponse = await AddressRepository()
        .getAddressDeleteResponse(id);

    if (addressDeleteResponse.result == false) {
      ToastComponent.showDialog(addressDeleteResponse.message);
      return;
    }
    ToastComponent.showDialog(addressDeleteResponse.message);
    afterDeletingAnAddress();
  }

  onAddressAdd(context) async {
    var address = _addressController.text.toString();
    var postalCode = _postalCodeController.text.toString();
    var phone = _phoneController.text.toString();

    if (address.isEmpty) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_address_ucf,
      );
      return;
    }

    if (_selectedCountry == null) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.select_a_country);
      return;
    }

    if (_showStateField && _selectedState == null) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.select_a_state);
      return;
    }

    if (_selectedCity == null) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.select_a_city);
      return;
    }

    if (_isAreaRequired && _selectedArea == null) {
      ToastComponent.showDialog("Please select an Area");
      return;
    }

    /// 1️⃣ CREATE ADDRESS
    var addressAddResponse = await AddressRepository().getAddressAddResponse(
      address: address,
      countryId: _selectedCountry!.id,
      stateId: _selectedState?.id ?? 0,
      cityId: _selectedCity!.id,
      areaId: _selectedArea?.id,
      postalCode: postalCode,
      phone: phone,
    );

    if (addressAddResponse.result != true) {
      ToastComponent.showDialog(addressAddResponse.message);
      return;
    }

    /// 2️⃣ LOCATION UPDATE (WORKAROUND)
    if (_pickedLocationForAdd != null) {
      try {
        /// Reload address list
        var addressListResponse = await AddressRepository().getAddressList();

        if (addressListResponse.addresses != null &&
            addressListResponse.addresses.isNotEmpty) {
          /// assume last address is newly added
          final lastAddress = addressListResponse.addresses.last;

          await AddressRepository().getAddressUpdateLocationResponse(
            lastAddress.id,
            _pickedLocationForAdd!.latitude,
            _pickedLocationForAdd!.longitude,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print("map_update_error: $e");
        }
      }
    }

    ToastComponent.showDialog(addressAddResponse.message);
    Navigator.of(context, rootNavigator: true).pop();
    afterAddingAnAddress();
  }

  onAddressUpdate(context, index, id) async {
    var address = _addressControllerListForUpdate[index].text.toString();
    var postalCode = _postalCodeControllerListForUpdate[index].text.toString();
    var phone = _phoneControllerListForUpdate[index].text.toString();

    if (address == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_address_ucf,
      );
      return;
    }

    if (_showStateField && _selectedStateListForUpdate[index] == null) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.select_a_state);
      return;
    }
    if (_selectedCityListForUpdate[index] == null) {
      ToastComponent.showDialog(AppLocalizations.of(context)!.select_a_city);
      return;
    }

    if (_isAreaRequired && _selectedAreaListForUpdate[index] == null) {
      ToastComponent.showDialog("Please select an Area");
      return;
    }

    var addressUpdateResponse = await AddressRepository()
        .getAddressUpdateResponse(
          id: id,
          address: address,
          countryId: _selectedCountryListForUpdate[index].id,
          stateId: _selectedStateListForUpdate[index]?.id ?? 0,
          cityId: _selectedCityListForUpdate[index]!.id,
          areaId: _selectedAreaListForUpdate[index]?.id,
          postalCode: postalCode,
          phone: phone,
        );

    if (addressUpdateResponse.result == false) {
      ToastComponent.showDialog(addressUpdateResponse.message);
      return;
    }

    try {
      final loc = (_pickedLocationForUpdate.length > index)
          ? _pickedLocationForUpdate[index]
          : null;
      if (loc != null) {
        await AddressRepository().getAddressUpdateLocationResponse(
          id,
          loc.latitude,
          loc.longitude,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('map_error:$e');
      }
    }

    ToastComponent.showDialog(addressUpdateResponse.message);
    Navigator.of(context, rootNavigator: true).pop();
    afterUpdatingAnAddress();
  }

  onSelectCityDuringAdd(city, setModalState) async {
    if (_selectedCity != null && city.id == _selectedCity!.id) {
      setModalState(() {
        _cityController.text = city.name;
      });
      return;
    }
    _selectedCity = city;
    _selectedArea = null;

    var areaResponse = await AddressRepository().getAriaListByCity(
      cityId: _selectedCity!.id,
    );
    _isAreaRequired = areaResponse.cities.isNotEmpty;

    setModalState(() {
      _cityController.text = city.name;
      _areaController.text = "";
    });
  }

  onSelectCityDuringUpdate(index, city, setModalState) async {
    if (_selectedCityListForUpdate[index] != null &&
        city.id == _selectedCityListForUpdate[index]!.id) {
      setModalState(() {
        _cityControllerListForUpdate[index].text = city.name;
      });
      return;
    }
    _selectedCityListForUpdate[index] = city;
    _selectedAreaListForUpdate[index] = null;

    var areaResponse = await AddressRepository().getAriaListByCity(
      cityId: city.id,
    );
    _isAreaRequired = areaResponse.cities.isNotEmpty;

    setModalState(() {
      _cityControllerListForUpdate[index].text = city.name;
      _areaControllerListForUpdate[index].text = "";
    });
  }

  onSelectCountryDuringAdd(country, setModalState) {
    if (_selectedCountry != null && country.id == _selectedCountry!.id) {
      setModalState(() => _countryController.text = country.name);
      return;
    }
    _selectedCountry = country;
    _selectedState = null;
    _selectedCity = null;
    _selectedArea = null;
    _isAreaRequired = false;
    setState(() {});

    setModalState(() {
      _countryController.text = country.name;
      _stateController.text = "";
      _cityController.text = "";
      _areaController.text = "";
    });
  }

  onSelectStateDuringAdd(state, setModalState) {
    if (_selectedState != null && state.id == _selectedState!.id) {
      setModalState(() => _stateController.text = state.name);
      return;
    }
    _selectedState = state;
    _selectedCity = null;
    _selectedArea = null;
    _isAreaRequired = false;
    setState(() {});
    setModalState(() {
      _stateController.text = state.name;
      _cityController.text = "";
      _areaController.text = "";
    });
  }

  onSelectAreaDuringAdd(area, setModalState) {
    if (_selectedArea != null && area.id == _selectedArea!.id) {
      setModalState(() => _areaController.text = area.name);
      return;
    }
    _selectedArea = area;
    setModalState(() => _areaController.text = area.name);
  }

  onSelectCountryDuringUpdate(index, country, setModalState) {
    if (country.id == _selectedCountryListForUpdate[index].id) {
      setModalState(
        () => _countryControllerListForUpdate[index].text = country.name,
      );
      return;
    }
    _selectedCountryListForUpdate[index] = country;
    _selectedStateListForUpdate[index] = null;
    _selectedCityListForUpdate[index] = null;
    _selectedAreaListForUpdate[index] = null;
    _isAreaRequired = false;
    setState(() {});

    setModalState(() {
      _countryControllerListForUpdate[index].text = country.name;
      _stateControllerListForUpdate[index].text = "";
      _cityControllerListForUpdate[index].text = "";
      _areaControllerListForUpdate[index].text = "";
    });
  }

  onSelectStateDuringUpdate(index, state, setModalState) {
    if (_selectedStateListForUpdate[index] != null &&
        state.id == _selectedStateListForUpdate[index]!.id) {
      setModalState(
        () => _stateControllerListForUpdate[index].text = state.name,
      );
      return;
    }
    _selectedStateListForUpdate[index] = state;
    _selectedCityListForUpdate[index] = null;
    _selectedAreaListForUpdate[index] = null;
    _isAreaRequired = false;
    setState(() {});
    setModalState(() {
      _stateControllerListForUpdate[index].text = state.name;
      _cityControllerListForUpdate[index].text = "";
      _areaControllerListForUpdate[index].text = "";
    });
  }

  onSelectAreaDuringUpdate(index, area, setModalState) {
    if (_selectedAreaListForUpdate[index] != null &&
        area.id == _selectedAreaListForUpdate[index]!.id) {
      setModalState(() => _areaControllerListForUpdate[index].text = area.name);
      return;
    }
    _selectedAreaListForUpdate[index] = area;
    setModalState(() => _areaControllerListForUpdate[index].text = area.name);
  }

  _handleAddressAction({required BuildContext context, int? listIndex}) async {
    _showLoadingDialog(context); // 🔥 SHOW LOADER

    try {
      var countryResponse = await AddressRepository().getCountryList(name: "");

      if (!context.mounted) return;

      var settingsResponse = await BusinessSettingRepository()
          .getBusinessSettingList();

      var hasStateDataList = (settingsResponse.data ?? [])
          .where((setting) => setting.type == "has_state")
          .toList();

      Datum? hasStateData = hasStateDataList.isNotEmpty
          ? hasStateDataList.first
          : null;

      bool showStateField = hasStateData?.value == "1";

      setState(() {
        _showStateField = showStateField;
      });

      _isAreaRequired = false;

      bool showCountryField = countryResponse.countries.length != 1;

      /// ADD
      if (listIndex == null) {
        _addressController.clear();
        _postalCodeController.clear();
        _phoneController.clear();

        _countryController.clear();
        _selectedCountry = null;

        _stateController.clear();
        _selectedState = null;

        _cityController.clear();
        _selectedCity = null;

        _areaController.clear();
        _selectedArea = null;

        _pickedLocationForAdd = null;
        _latitudeController.text = "";
        _longitudeController.text = "";

        if (!showCountryField && countryResponse.countries.isNotEmpty) {
          final singleCountry = countryResponse.countries.first;
          _selectedCountry = singleCountry;
          _countryController.text = singleCountry.name;
        }

        _hideLoadingDialog(context);
        buildShowAddFormDialog(context, showCountryField);
      } else {
        var city = _selectedCityListForUpdate[listIndex];
        if (city != null) {
          var areaResponse = await AddressRepository().getAriaListByCity(
            cityId: city.id,
          );
          if (context.mounted) {
            setState(() {
              _isAreaRequired = areaResponse.cities.isNotEmpty;
            });
          }
        }

        _hideLoadingDialog(context);
        buildShowUpdateFormDialog(context, listIndex, showCountryField);
      }
    } catch (e) {
      _hideLoadingDialog(context);
      if (kDebugMode) {
        print("address_action_error: $e");
      }
    }
  }

  _tabOption(int index, listIndex) {
    switch (index) {
      case 0:
        _handleAddressAction(context: context, listIndex: listIndex);
        break;
      case 1:
        onPressDelete(_shippingAddressList[listIndex].id);
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapPlacePickerNoHeader(
              googleApiKey: OtherConfig.GOOGLE_MAP_API_KEY,
              address: _shippingAddressList[listIndex],
            ),
          ),
        ).then((value) {
          if (value != null &&
              value is Map &&
              value['ok'] == true &&
              value['lat'] != null &&
              value['lng'] != null) {
            final double lat = value['lat'];
            final double lng = value['lng'];
            final LatLng newLoc = LatLng(lat, lng);

            //  update picked location
            if (_pickedLocationForUpdate.length > listIndex) {
              _pickedLocationForUpdate[listIndex] = newLoc;
            } else {
              while (_pickedLocationForUpdate.length <= listIndex) {
                _pickedLocationForUpdate.add(null);
              }
              _pickedLocationForUpdate[listIndex] = newLoc;
            }

            //  update text fields
            _latitudeControllerListForUpdate[listIndex].text = lat
                .toStringAsFixed(6);
            _longitudeControllerListForUpdate[listIndex].text = lng
                .toStringAsFixed(6);

            setState(() {});
          }
        });
        break;
      case 3:
        // Make Default Shipping
        _onMakeDefaultAction(
          _shippingAddressList[listIndex].id,
          isShipping: true,
        );
        break;
      case 4:
        // Make Default Billing
        _onMakeDefaultAction(
          _shippingAddressList[listIndex].id,
          isBilling: true,
        );
        break;
    }
  }

  _onMakeDefaultAction(
    int id, {
    bool isShipping = false,
    bool isBilling = false,
  }) async {
    _showLoadingDialog(context);

    var addressMakeDefaultResponse = await AddressRepository()
        .getAddressMakeDefaultResponse(
          id,
          isDefaultShipping: isShipping,
          isDefaultBilling: isBilling,
        );

    _hideLoadingDialog(context);

    if (addressMakeDefaultResponse.result == false) {
      ToastComponent.showDialog(addressMakeDefaultResponse.message);
      return;
    }

    ToastComponent.showDialog(addressMakeDefaultResponse.message);

    // UI রিফ্রেশ করার জন্য
    reset();
    if (is_logged_in.$ == true) {
      fetchAll();
    }
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _areaController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();

    for (var c in _addressControllerListForUpdate) {
      c.dispose();
    }
    for (var c in _postalCodeControllerListForUpdate) {
      c.dispose();
    }
    for (var c in _phoneControllerListForUpdate) {
      c.dispose();
    }
    for (var c in _cityControllerListForUpdate) {
      c.dispose();
    }
    for (var c in _stateControllerListForUpdate) {
      c.dispose();
    }
    for (var c in _countryControllerListForUpdate) {
      c.dispose();
    }
    for (var c in _areaControllerListForUpdate) {
      c.dispose();
    }
    for (var c in _latitudeControllerListForUpdate) {
      c.dispose();
    }
    for (var c in _longitudeControllerListForUpdate) {
      c.dispose();
    }

    super.dispose();
  }

  // LOCATION HELPERS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.mainColor,
      appBar: buildAppBar(context),
      bottomNavigationBar: buildBottomAppBar(context),
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onRefresh,
        displacement: 0,
        child: CustomScrollView(
          controller: _mainScrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 05, 20, 16),
                  child: Btn.minWidthFixHeight(
                    minWidth: MediaQuery.of(context).size.width - 16,
                    height: 90,
                    color: MyTheme.accent_color.withValues(alpha: .12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: MyTheme.accent_color, width: 1.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.add_new_address,
                          style: TextStyle(
                            fontSize: 13,
                            color: MyTheme.dark_font_grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Icon(
                          Icons.add_circle_outline,
                          color: MyTheme.accent_color,
                          size: 30,
                        ),
                      ],
                    ),
                    onPressed: () {
                      _handleAddressAction(context: context);
                    },
                  ),
                ),
                //address List
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: buildAddressList(),
                ),
                SizedBox(height: 100),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Future buildShowAddFormDialog(BuildContext context, bool showCountryField) {
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: EdgeInsets.symmetric(horizontal: 10),
              contentPadding: EdgeInsets.only(
                top: 23.0,
                left: 20.0,
                right: 20.0,
                bottom: 2.0,
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ADDRESS INPUTS (same as previous)
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          "${AppLocalizations.of(context)!.address_ucf} *",
                          style: TextStyle(
                            color: Color(0xff3E4447),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _addressController,
                            autofocus: false,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: buildAddressInputDecoration(
                              context,
                              AppLocalizations.of(context)!.enter_address_ucf,
                            ),
                          ),
                        ),
                      ),

                      if (showCountryField) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            "${AppLocalizations.of(context)!.country_ucf} *",
                            style: TextStyle(
                              color: Color(0xff3E4447),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: SizedBox(
                            height: 40,
                            child: TypeAheadField(
                              controller: _countryController,
                              builder: (context, controller, focusNode) {
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: buildAddressInputDecoration(
                                    context,
                                    AppLocalizations.of(
                                      context,
                                    )!.enter_country_ucf,
                                  ),
                                );
                              },
                              suggestionsCallback: (name) async {
                                var countryResponse = await AddressRepository()
                                    .getCountryList(name: name);
                                return countryResponse.countries;
                              },
                              loadingBuilder: (context) => Center(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.loading_countries_ucf,
                                ),
                              ),
                              itemBuilder: (context, dynamic country) {
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    country.name,
                                    style: TextStyle(color: MyTheme.font_grey),
                                  ),
                                );
                              },
                              onSelected: (value) {
                                onSelectCountryDuringAdd(value, setModalState);
                              },
                            ),
                          ),
                        ),
                      ],

                      Visibility(
                        visible: _showStateField,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                "${AppLocalizations.of(context)!.state_ucf} *",
                                style: TextStyle(
                                  color: Color(0xff3E4447),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: SizedBox(
                                height: 40,
                                child: TypeAheadField(
                                  builder: (context, controller, focusNode) {
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: buildAddressInputDecoration(
                                        context,
                                        AppLocalizations.of(
                                          context,
                                        )!.enter_state_ucf,
                                      ),
                                    );
                                  },
                                  controller: _stateController,
                                  suggestionsCallback: (name) async {
                                    if (_selectedCountry == null) {
                                      return [];
                                    }
                                    var stateResponse =
                                        await AddressRepository()
                                            .getStateListByCountry(
                                              countryId: _selectedCountry!.id,
                                              name: name,
                                            );
                                    return stateResponse.states;
                                  },
                                  loadingBuilder: (context) => Center(
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.loading_states_ucf,
                                    ),
                                  ),
                                  itemBuilder: (context, dynamic state) {
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        state.name,
                                        style: TextStyle(
                                          color: MyTheme.font_grey,
                                        ),
                                      ),
                                    );
                                  },
                                  onSelected: (value) {
                                    onSelectStateDuringAdd(
                                      value,
                                      setModalState,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // CITY
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "${AppLocalizations.of(context)!.city_ucf} *",
                          style: TextStyle(
                            color: Color(0xff3E4447),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: SizedBox(
                          height: 40,
                          child: TypeAheadField(
                            controller: _cityController,
                            builder: (context, controller, focusNode) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: buildAddressInputDecoration(
                                  context,
                                  AppLocalizations.of(context)!.enter_city_ucf,
                                ),
                              );
                            },
                            suggestionsCallback: (name) async {
                              if (_showStateField) {
                                if (_selectedState == null) return [];
                                var cityResponse = await AddressRepository()
                                    .getCityListByState(
                                      stateId: _selectedState!.id,
                                      name: name,
                                    );
                                return cityResponse.cities;
                              } else {
                                if (_selectedCountry == null) return [];
                                var cityResponse = await AddressRepository()
                                    .getCityListByCountry(
                                      countryId: _selectedCountry!.id!,
                                      name: name,
                                    );
                                return cityResponse.cities;
                              }
                            },
                            loadingBuilder: (context) => Center(
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.loading_cities_ucf,
                              ),
                            ),
                            itemBuilder: (context, dynamic city) {
                              return ListTile(
                                dense: true,
                                title: Text(
                                  city.name,
                                  style: TextStyle(color: MyTheme.font_grey),
                                ),
                              );
                            },
                            onSelected: (value) {
                              onSelectCityDuringAdd(value, setModalState);
                            },
                          ),
                        ),
                      ),

                      Visibility(
                        visible: _isAreaRequired,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                "Area *",
                                style: TextStyle(
                                  color: Color(0xff3E4447),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: SizedBox(
                                height: 40,
                                child: TypeAheadField(
                                  controller: _areaController,
                                  builder: (context, controller, focusNode) {
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: buildAddressInputDecoration(
                                        context,
                                        "Enter Area",
                                      ),
                                    );
                                  },
                                  suggestionsCallback: (name) async {
                                    if (_selectedCity == null) {
                                      return [];
                                    }
                                    var areaResponse = await AddressRepository()
                                        .getAriaListByCity(
                                          cityId: _selectedCity!.id,
                                          name: name,
                                        );
                                    return areaResponse.cities;
                                  },
                                  loadingBuilder: (context) =>
                                      Center(child: Text("Loading Areas...")),
                                  itemBuilder: (context, dynamic area) {
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        area.name,
                                        style: TextStyle(
                                          color: MyTheme.font_grey,
                                        ),
                                      ),
                                    );
                                  },
                                  onSelected: (value) {
                                    onSelectAreaDuringAdd(value, setModalState);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          AppLocalizations.of(context)!.postal_code,
                          style: TextStyle(
                            color: Color(0xff3E4447),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _postalCodeController,
                            decoration: buildAddressInputDecoration(
                              context,
                              AppLocalizations.of(
                                context,
                              )!.enter_postal_code_ucf,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          AppLocalizations.of(context)!.phone_ucf,
                          style: TextStyle(
                            color: Color(0xff3E4447),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _phoneController,
                            decoration: buildAddressInputDecoration(
                              context,
                              AppLocalizations.of(context)!.enter_phone_number,
                            ),
                          ),
                        ),
                      ),

                      // MAP PREVIEW FOR ADD
                      if (_isGoogleMapEnabled) ...[
                        const SizedBox(height: 8),

                        Text(
                          "Location",
                          style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: GoogleMap(
                              key: ValueKey(
                                _pickedLocationForAdd?.toString() ?? 'add_map',
                              ),

                              liteModeEnabled: false,

                              gestureRecognizers: {
                                Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                                ),
                              },

                              initialCameraPosition: CameraPosition(
                                target:
                                    _pickedLocationForAdd ??
                                    (_backendDefaultLat != null &&
                                            _backendDefaultLng != null
                                        ? LatLng(
                                            _backendDefaultLat!,
                                            _backendDefaultLng!,
                                          )
                                        : const LatLng(0, 0)),
                                zoom: _pickedLocationForAdd != null
                                    ? 16
                                    : (_backendDefaultLat != null ? 14 : 1),
                              ),

                              markers: {
                                if (_pickedLocationForAdd != null)
                                  Marker(
                                    markerId: const MarkerId('add_preview'),
                                    position: _pickedLocationForAdd!,
                                  )
                                else if (_backendDefaultLat != null &&
                                    _backendDefaultLng != null)
                                  Marker(
                                    markerId: const MarkerId('backend_default'),
                                    position: LatLng(
                                      _backendDefaultLat!,
                                      _backendDefaultLng!,
                                    ),
                                  ),
                              },

                              onTap: (pos) {
                                setModalState(() {
                                  _pickedLocationForAdd = pos;
                                  _latitudeController.text = pos.latitude
                                      .toStringAsFixed(6);
                                  _longitudeController.text = pos.longitude
                                      .toStringAsFixed(6);
                                });
                              },

                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              compassEnabled: false,
                              mapToolbarEnabled: false,
                              rotateGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: Btn.minWidthFixHeight(
                                minWidth: 120,
                                height: 40,
                                color: MyTheme.accent_color,
                                child: const Text(
                                  "Pick from map",
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MapPlacePickerNoHeader(
                                        googleApiKey:
                                            OtherConfig.GOOGLE_MAP_API_KEY,
                                        address: null,
                                      ),
                                    ),
                                  );

                                  if (result != null &&
                                      result is Map &&
                                      result['ok'] == true &&
                                      result['lat'] != null &&
                                      result['lng'] != null) {
                                    setModalState(() {
                                      _pickedLocationForAdd = LatLng(
                                        result['lat'],
                                        result['lng'],
                                      );
                                      _latitudeController.text = result['lat']
                                          .toStringAsFixed(6);
                                      _longitudeController.text = result['lng']
                                          .toStringAsFixed(6);
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    _pickedLocationForAdd = null;
                                    _latitudeController.text = "";
                                    _longitudeController.text = "";
                                  });
                                },
                                child: Container(
                                  width: 120,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: MyTheme.light_grey,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Clear",
                                      style: TextStyle(
                                        color: MyTheme.accent_color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      "Longitude",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xff6B7377),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 40,
                                    child: TextField(
                                      controller: _longitudeController,
                                      readOnly: true,
                                      decoration: buildAddressInputDecoration(
                                        context,
                                        "Longitude",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      "Latitude",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xff6B7377),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 40,
                                    child: TextField(
                                      controller: _latitudeController,
                                      readOnly: true,
                                      decoration: buildAddressInputDecoration(
                                        context,
                                        "Latitude",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                      ],

                      // END MAP PREVIEW FOR ADD
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Btn.minWidthFixHeight(
                        minWidth: 75,
                        height: 40,
                        color: Color.fromRGBO(253, 253, 253, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                          side: BorderSide(color: MyTheme.light_grey, width: 1),
                        ),
                        child: Text(
                          LangText(context).local.close_ucf,
                          style: TextStyle(
                            color: MyTheme.accent_color,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Btn.minWidthFixHeight(
                        minWidth: 75,
                        height: 40,
                        color: MyTheme.accent_color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          LangText(context).local.add_ucf,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          onAddressAdd(context);
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

  InputDecoration buildAddressInputDecoration(BuildContext context, hintText) {
    return InputDecoration(
      filled: true,
      fillColor: Color(0xffF6F7F8),
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 12.0, color: Color(0xff999999)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: MyTheme.noColor, width: 0.5),
        borderRadius: const BorderRadius.all(Radius.circular(6.0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: MyTheme.noColor, width: 1.0),
        borderRadius: const BorderRadius.all(Radius.circular(6.0)),
      ),
      contentPadding: EdgeInsets.only(left: 8.0, top: 6.0, bottom: 6.0),
    );
  }

  Future buildShowUpdateFormDialog(
    BuildContext context,
    int index,
    bool showCountryField,
  ) {
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              insetPadding: EdgeInsets.symmetric(horizontal: 10),
              contentPadding: EdgeInsets.only(
                top: 36.0,
                left: 20.0,
                right: 20.0,
                bottom: 2.0,
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // address update fields
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "${AppLocalizations.of(context)!.address_ucf} *",
                          style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: SizedBox(
                          height: 55,
                          child: TextField(
                            controller: _addressControllerListForUpdate[index],
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: buildAddressInputDecoration(
                              context,
                              AppLocalizations.of(context)!.enter_address_ucf,
                            ),
                          ),
                        ),
                      ),

                      if (showCountryField) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            "${AppLocalizations.of(context)!.country_ucf} *",
                            style: TextStyle(
                              color: MyTheme.font_grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: SizedBox(
                            height: 40,
                            child: TypeAheadField(
                              controller:
                                  _countryControllerListForUpdate[index],
                              builder: (context, controller, focusNode) {
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: buildAddressInputDecoration(
                                    context,
                                    AppLocalizations.of(
                                      context,
                                    )!.enter_country_ucf,
                                  ),
                                );
                              },
                              suggestionsCallback: (name) async {
                                var countryResponse = await AddressRepository()
                                    .getCountryList(name: name);
                                return countryResponse.countries;
                              },
                              loadingBuilder: (context) => Center(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.loading_countries_ucf,
                                ),
                              ),
                              itemBuilder: (context, dynamic country) {
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    country.name,
                                    style: TextStyle(color: MyTheme.font_grey),
                                  ),
                                );
                              },
                              onSelected: (value) {
                                onSelectCountryDuringUpdate(
                                  index,
                                  value,
                                  setModalState,
                                );
                              },
                            ),
                          ),
                        ),
                      ],

                      Visibility(
                        visible: _showStateField,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                "${AppLocalizations.of(context)!.state_ucf} *",
                                style: TextStyle(
                                  color: MyTheme.font_grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: SizedBox(
                                height: 40,
                                child: TypeAheadField(
                                  controller:
                                      _stateControllerListForUpdate[index],
                                  builder: (context, controller, focusNode) {
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: buildAddressInputDecoration(
                                        context,
                                        AppLocalizations.of(
                                          context,
                                        )!.enter_state_ucf,
                                      ),
                                    );
                                  },
                                  suggestionsCallback: (name) async {
                                    var stateResponse = await AddressRepository()
                                        .getStateListByCountry(
                                          countryId:
                                              _selectedCountryListForUpdate[index]
                                                  .id,
                                          name: name,
                                        );
                                    return stateResponse.states;
                                  },
                                  loadingBuilder: (context) => Center(
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.loading_states_ucf,
                                    ),
                                  ),
                                  itemBuilder: (context, dynamic state) {
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        state.name,
                                        style: TextStyle(
                                          color: MyTheme.font_grey,
                                        ),
                                      ),
                                    );
                                  },
                                  onSelected: (value) {
                                    onSelectStateDuringUpdate(
                                      index,
                                      value,
                                      setModalState,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // CITY field ...
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "${AppLocalizations.of(context)!.city_ucf} *",
                          style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: SizedBox(
                          height: 40,
                          child: TypeAheadField(
                            controller: _cityControllerListForUpdate[index],
                            builder: (context, controller, focusNode) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: buildAddressInputDecoration(
                                  context,
                                  AppLocalizations.of(context)!.enter_city_ucf,
                                ),
                              );
                            },
                            suggestionsCallback: (name) async {
                              if (_selectedStateListForUpdate[index] == null) {
                                return [];
                              }
                              var cityResponse = await AddressRepository()
                                  .getCityListByState(
                                    stateId:
                                        _selectedStateListForUpdate[index]!.id,
                                    name: name,
                                  );
                              return cityResponse.cities;
                            },
                            loadingBuilder: (context) => Center(
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.loading_cities_ucf,
                              ),
                            ),
                            itemBuilder: (context, dynamic city) {
                              return ListTile(
                                dense: true,
                                title: Text(
                                  city.name,
                                  style: TextStyle(color: MyTheme.font_grey),
                                ),
                              );
                            },
                            onSelected: (value) {
                              onSelectCityDuringUpdate(
                                index,
                                value,
                                setModalState,
                              );
                            },
                          ),
                        ),
                      ),

                      Visibility(
                        visible: _isAreaRequired,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                "Area *",
                                style: TextStyle(
                                  color: MyTheme.font_grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: SizedBox(
                                height: 40,
                                child: TypeAheadField(
                                  controller:
                                      _areaControllerListForUpdate[index],
                                  builder: (context, controller, focusNode) {
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: buildAddressInputDecoration(
                                        context,
                                        "Enter Area",
                                      ),
                                    );
                                  },
                                  suggestionsCallback: (name) async {
                                    if (_selectedCityListForUpdate[index] ==
                                        null) {
                                      return [];
                                    }
                                    var areaResponse = await AddressRepository()
                                        .getAriaListByCity(
                                          cityId:
                                              _selectedCityListForUpdate[index]!
                                                  .id,
                                          name: name,
                                        );
                                    return areaResponse.cities;
                                  },
                                  loadingBuilder: (context) =>
                                      Center(child: Text("Loading Areas...")),
                                  itemBuilder: (context, dynamic area) {
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        area.name,
                                        style: TextStyle(
                                          color: MyTheme.font_grey,
                                        ),
                                      ),
                                    );
                                  },
                                  onSelected: (value) {
                                    onSelectAreaDuringUpdate(
                                      index,
                                      value,
                                      setModalState,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // postal and phone ...
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          AppLocalizations.of(context)!.postal_code,
                          style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller:
                                _postalCodeControllerListForUpdate[index],
                            decoration: buildAddressInputDecoration(
                              context,
                              AppLocalizations.of(
                                context,
                              )!.enter_postal_code_ucf,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          AppLocalizations.of(context)!.phone_ucf,
                          style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _phoneControllerListForUpdate[index],
                            decoration: buildAddressInputDecoration(
                              context,
                              AppLocalizations.of(context)!.enter_phone_number,
                            ),
                          ),
                        ),
                      ),

                      // MAP PREVIEW FOR UPDATE
                      if (_isGoogleMapEnabled) ...[
                        const SizedBox(height: 8),

                        Text(
                          "Location",
                          style: TextStyle(
                            color: MyTheme.font_grey,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: GoogleMap(
                              key: ValueKey(
                                '${index}_${_pickedLocationForUpdate.length > index ? _pickedLocationForUpdate[index]?.toString() : 'null'}',
                              ),

                              liteModeEnabled: false,

                              gestureRecognizers: {
                                Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                                ),
                              },

                              initialCameraPosition: CameraPosition(
                                target:
                                    (_pickedLocationForUpdate.length > index &&
                                        _pickedLocationForUpdate[index] != null)
                                    ? _pickedLocationForUpdate[index]!
                                    : (_backendDefaultLat != null &&
                                              _backendDefaultLng != null
                                          ? LatLng(
                                              _backendDefaultLat!,
                                              _backendDefaultLng!,
                                            )
                                          : const LatLng(0, 0)),
                                zoom:
                                    (_pickedLocationForUpdate.length > index &&
                                        _pickedLocationForUpdate[index] != null)
                                    ? 16
                                    : (_backendDefaultLat != null ? 14 : 1),
                              ),

                              markers: {
                                if (_pickedLocationForUpdate.length > index &&
                                    _pickedLocationForUpdate[index] != null)
                                  Marker(
                                    markerId: const MarkerId('update_preview'),
                                    position: _pickedLocationForUpdate[index]!,
                                  )
                                else if (_backendDefaultLat != null &&
                                    _backendDefaultLng != null)
                                  Marker(
                                    markerId: const MarkerId('backend_default'),
                                    position: LatLng(
                                      _backendDefaultLat!,
                                      _backendDefaultLng!,
                                    ),
                                  ),
                              },

                              onTap: (pos) {
                                setModalState(() {
                                  while (_pickedLocationForUpdate.length <=
                                      index) {
                                    _pickedLocationForUpdate.add(null);
                                  }

                                  _pickedLocationForUpdate[index] = pos;

                                  _latitudeControllerListForUpdate[index].text =
                                      pos.latitude.toStringAsFixed(6);

                                  _longitudeControllerListForUpdate[index]
                                      .text = pos.longitude.toStringAsFixed(
                                    6,
                                  );
                                });
                              },

                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              compassEnabled: false,
                              mapToolbarEnabled: false,
                              rotateGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: Btn.minWidthFixHeight(
                                minWidth: 120,
                                height: 40,
                                color: MyTheme.accent_color,
                                child: const Text(
                                  "Pick on map",
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MapPlacePickerNoHeader(
                                        googleApiKey:
                                            OtherConfig.GOOGLE_MAP_API_KEY,
                                        address: _shippingAddressList[index],
                                      ),
                                    ),
                                  );

                                  if (result != null &&
                                      result is Map &&
                                      result['ok'] == true &&
                                      result['lat'] != null &&
                                      result['lng'] != null) {
                                    setModalState(() {
                                      while (_pickedLocationForUpdate.length <=
                                          index) {
                                        _pickedLocationForUpdate.add(null);
                                      }

                                      _pickedLocationForUpdate[index] = LatLng(
                                        result['lat'],
                                        result['lng'],
                                      );

                                      _latitudeControllerListForUpdate[index]
                                          .text = result['lat'].toStringAsFixed(
                                        6,
                                      );

                                      _longitudeControllerListForUpdate[index]
                                          .text = result['lng'].toStringAsFixed(
                                        6,
                                      );
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    if (_pickedLocationForUpdate.length >
                                        index) {
                                      _pickedLocationForUpdate[index] = null;
                                    }
                                    _latitudeControllerListForUpdate[index]
                                            .text =
                                        "";
                                    _longitudeControllerListForUpdate[index]
                                            .text =
                                        "";
                                  });
                                },
                                child: Container(
                                  width: 120,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: MyTheme.light_grey,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Clear",
                                      style: TextStyle(
                                        color: MyTheme.accent_color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      "Longitude",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xff6B7377),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 40,
                                    child: TextField(
                                      controller:
                                          _longitudeControllerListForUpdate[index],
                                      readOnly: true,
                                      decoration: buildAddressInputDecoration(
                                        context,
                                        "Longitude",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      "Latitude",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xff6B7377),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 40,
                                    child: TextField(
                                      controller:
                                          _latitudeControllerListForUpdate[index],
                                      readOnly: true,
                                      decoration: buildAddressInputDecoration(
                                        context,
                                        "Latitude",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],

                      SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Btn.minWidthFixHeight(
                        minWidth: 75,
                        height: 40,
                        color: Color.fromRGBO(253, 253, 253, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                          side: BorderSide(
                            color: MyTheme.light_grey,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.close_all_capital,
                          style: TextStyle(
                            color: MyTheme.accent_color,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Btn.minWidthFixHeight(
                        minWidth: 75,
                        height: 40,
                        color: MyTheme.accent_color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.update_all_capital,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          onAddressUpdate(
                            context,
                            index,
                            _shippingAddressList[index].id,
                          );
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

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_font_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.addresses_of_user,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xff3E4447),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "* ${AppLocalizations.of(context)!.double_tap_on_an_address_to_make_it_default}",
            style: TextStyle(fontSize: 12, color: Color(0xff6B7377)),
          ),
        ],
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  buildAddressList() {
    if (!is_logged_in.$) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.you_need_to_log_in,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    } else if (_isInitial && _shippingAddressList.isEmpty) {
      return SingleChildScrollView(
        child: ShimmerHelper().buildListShimmer(
          itemCount: 5,
          itemHeight: 100.0,
        ),
      );
    } else if (_shippingAddressList.isNotEmpty) {
      return ListView.separated(
        separatorBuilder: (context, index) => SizedBox(height: 16),
        itemCount: _shippingAddressList.length,
        scrollDirection: Axis.vertical,
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return buildAddressItemCard(index);
        },
      );
    } else {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_address_is_added,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    }
  }

  GestureDetector buildAddressItemCard(int index) {
    return GestureDetector(
      onDoubleTap: () {

        if (_shippingAddressList[index].setDefault != 1) {
          _onMakeDefaultAction(_shippingAddressList[index].id, isShipping: true);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecorations.buildBoxDecoration_1().copyWith(
          border: Border.all(

            color: _shippingAddressList[index].setDefault == 1
                ? MyTheme.accent_color
                : MyTheme.light_grey,
            width: _shippingAddressList[index].setDefault == 1 ? 1.0 : 0.0,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_shippingAddressList[index].setDefault == 1 || _shippingAddressList[index].setBilling == 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5.0, right: 30.0),
                      child: buildDefaultBadges(index),
                    ),
                  buildAddressInfoRow(
                    AppLocalizations.of(context)!.address_ucf,
                    _shippingAddressList[index].address ?? "",
                  ),
                  if (_shippingAddressList[index].areaName != null &&
                      _shippingAddressList[index].areaName.isNotEmpty)
                    buildAddressInfoRow(
                      "Area",
                      _shippingAddressList[index].areaName ?? "",
                    ),
                  buildAddressInfoRow(
                    AppLocalizations.of(context)!.city_ucf,
                    _shippingAddressList[index].cityName ?? "",
                  ),
                  if (_shippingAddressList[index].stateName != null &&
                      _shippingAddressList[index].stateName.isNotEmpty)
                    buildAddressInfoRow(
                      AppLocalizations.of(context)!.state_ucf,
                      _shippingAddressList[index].stateName ?? "",
                    ),
                  buildAddressInfoRow(
                    AppLocalizations.of(context)!.country_ucf,
                    _shippingAddressList[index].countryName ?? "",
                  ),
                  buildAddressInfoRow(
                    AppLocalizations.of(context)!.postal_code,
                    _shippingAddressList[index].postalCode ?? "",
                  ),
                  buildAddressInfoRow(
                    AppLocalizations.of(context)!.phone_ucf,
                    _shippingAddressList[index].phone ?? "",
                    isLast: true,
                  ),
                ],
              ),
            ),
            Positioned(
              right: app_language_rtl.$! ? null : 0.0,
              left: app_language_rtl.$! ? 0.0 : null,
              top: 10.0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                //  buildDefaultBadges(index),
                  showOptions(listIndex: index),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDefaultBadges(int index) {
    bool isDefaultShipping = _shippingAddressList[index].setDefault == 1;
    bool isDefaultBilling = _shippingAddressList[index].setBilling == 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDefaultShipping)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          //  margin: const EdgeInsets.only(right: 0),
            decoration: BoxDecoration(
              color: const Color(0xff1A1A1A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Default Shipping",
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        SizedBox(width: 5,),
        if (isDefaultBilling)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
           // margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: const Color(0xff007BFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Default Billing",
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget buildAddressInfoRow(
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff6B7377),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: MyTheme.dark_grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BottomAppBar buildBottomAppBar(BuildContext context) {
    return BottomAppBar(
      color: Colors.transparent,
      elevation: 0.0,
      child: Visibility(
        visible: widget.fromShippingInfo,
        child: SizedBox(
          height: 50,
          child: Btn.minWidthFixHeight(
            minWidth: MediaQuery.of(context).size.width,
            height: 50,
            color: MyTheme.accent_color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0.0),
            ),
            child: Text(
              AppLocalizations.of(context)!.back_to_shipping_info,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  Widget showOptions({required int listIndex}) {
    return SizedBox(
      width: 25,
      child: PopupMenuButton<MenuOptions>(color: Colors.white,
        offset: const Offset(-25, 0),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Container(
            width: 25,
            padding: const EdgeInsets.only(right: 12),
            alignment: Alignment.topRight,
            child: Image.asset(
              "assets/more.png",
              width: 4,
              height: 16,
              fit: BoxFit.contain,
              color: MyTheme.grey_153,
            ),
          ),
        ),
        onSelected: (MenuOptions result) {
          _tabOption(result.index, listIndex);
        },
        itemBuilder: (BuildContext context) {

          List<PopupMenuEntry<MenuOptions>> menuItems = [
            PopupMenuItem<MenuOptions>(
              value: MenuOptions.Edit,
              child: Text(AppLocalizations.of(context)!.edit_ucf),
            ),
            PopupMenuItem<MenuOptions>(
              value: MenuOptions.Delete,
              child: Text(AppLocalizations.of(context)!.delete_ucf),
            ),
            PopupMenuItem<MenuOptions>(
              value: MenuOptions.AddLocation,
              child: Text(AppLocalizations.of(context)!.add_location_ucf),
            ),
          ];

          if (_shippingAddressList[listIndex].setDefault != 1) {
            menuItems.add(
              const PopupMenuItem<MenuOptions>(
                value: MenuOptions.MakeDefaultShipping,
                child: Text("Make this default shipping"),
              ),
            );
          }

          if (_shippingAddressList[listIndex].setBilling != 1) {
            menuItems.add(
              const PopupMenuItem<MenuOptions>(
                value: MenuOptions.MakeDefaultBilling,
                child: Text("Make this default billing"),
              ),
            );
          }

          return menuItems;
        },
      ),
    );
  }
}

void _showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: .25),
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: MyTheme.accent_color),
    ),
  );
}

void _hideLoadingDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}

enum MenuOptions {
  Edit,
  Delete,
  AddLocation,
  MakeDefaultShipping,
  MakeDefaultBilling,
}
