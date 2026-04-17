import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ea24_mobile/repositories/address_repository.dart';
import 'package:ea24_mobile/repositories/shipping_repository.dart';
import 'package:ea24_mobile/repositories/cart_repository.dart';
import 'package:ea24_mobile/repositories/payment_repository.dart';
import 'package:ea24_mobile/repositories/business_setting_repository.dart';
import 'package:ea24_mobile/repositories/coupon_repository.dart';
import 'package:ea24_mobile/custom/toast_component.dart';
import 'package:ea24_mobile/screens/orders/order_list.dart';
import '../helpers/shared_value_helper.dart';
import '../repositories/guest_checkout_repository.dart';

enum ShippingOption { HomeDelivery, PickUpPoint, Carrier }

class SellerWithShipping {
  int? sellerId;
  ShippingOption shippingOption;
  int? shippingId;
  SellerWithShipping(this.sellerId, this.shippingOption, this.shippingId);
}

class CheckoutProvider extends ChangeNotifier {
  // --- Guest SHIPPING Controllers ---
  TextEditingController guestNameController = TextEditingController();
  TextEditingController guestEmailController = TextEditingController();
  TextEditingController guestAddressController = TextEditingController();
  TextEditingController guestPostalCodeController = TextEditingController();
  TextEditingController guestPhoneController = TextEditingController();

  // --- COUPON CONTROLLER ---
  TextEditingController couponController = TextEditingController();

  FocusNode guestEmailFocusNode = FocusNode();
  String? emailErrorText;
  String? nameErrorText;
  String? addressErrorText;
  String? phoneErrorText;

  // --- Guest BILLING Controllers ---
  TextEditingController guestBillingNameController = TextEditingController();
  TextEditingController guestBillingAddressController = TextEditingController();
  TextEditingController guestBillingPostalCodeController =
      TextEditingController();
  TextEditingController guestBillingPhoneController = TextEditingController();

  String? billingNameErrorText;
  String? billingAddressErrorText;
  String? billingPhoneErrorText;

  // --- Settings ---
  bool _isBillingAddressRequired = false;
  bool get isBillingAddressRequired => _isBillingAddressRequired;

  bool _isCouponSystemActive = false;
  bool get isCouponSystemActive => _isCouponSystemActive;
  bool _couponApplied = false;
  bool get couponApplied => _couponApplied;
  String _appliedCouponCode = "";
  String get appliedCouponCode => _appliedCouponCode;

  // --- Dropdown states ---
  List<dynamic> _countryList = [];
  List<dynamic> _stateList = [];
  List<dynamic> _cityList = [];
  List<dynamic> _areaList = [];

  dynamic _selectedCountry;
  dynamic _selectedState;
  dynamic _selectedCity;
  dynamic _selectedArea;

  bool _isCityLoading = false;
  bool _isAreaLoading = false;

  // --- Billing Dropdown states ---
  List<dynamic> _billingStateList = [];
  List<dynamic> _billingCityList = [];
  List<dynamic> _billingAreaList = [];

  dynamic _selectedBillingCountry;
  dynamic _selectedBillingState;
  dynamic _selectedBillingCity;
  dynamic _selectedBillingArea;

  bool _isBillingCityLoading = false;
  bool _isBillingAreaLoading = false;

  // --- Summary Data ---
  String _subTotal = "...";
  String _shippingCost = "...";
  String _tax = "...";
  String _gst = '...';
  String _grandTotal = "...";
  String _discount = '...';

  // --- COUNTERS  ---
  int _totalItemCount = 0;
  int _totalClubPoint = 0;

  bool _deliverySectionVisited = false;
  bool get deliverySectionVisited => _deliverySectionVisited;

  // Method to set visited to true
  void setDeliverySectionVisited() {
    _deliverySectionVisited = true;
    notifyListeners();
  }
  // ------------------------------------------

  // Getters
  List<dynamic> get countryList => _countryList;
  List<dynamic> get stateList => _stateList;
  List<dynamic> get cityList => _cityList;
  List<dynamic> get areaList => _areaList;
  dynamic get selectedCountry => _selectedCountry;
  dynamic get selectedState => _selectedState;
  dynamic get selectedCity => _selectedCity;
  dynamic get selectedArea => _selectedArea;
  bool get isCityLoading => _isCityLoading;
  bool get isAreaLoading => _isAreaLoading;

  List<dynamic> get billingStateList => _billingStateList;
  List<dynamic> get billingCityList => _billingCityList;
  List<dynamic> get billingAreaList => _billingAreaList;
  dynamic get selectedBillingCountry => _selectedBillingCountry;
  dynamic get selectedBillingState => _selectedBillingState;
  dynamic get selectedBillingCity => _selectedBillingCity;
  dynamic get selectedBillingArea => _selectedBillingArea;
  bool get isBillingCityLoading => _isBillingCityLoading;
  bool get isBillingAreaLoading => _isBillingAreaLoading;

  dynamic get selectedBillingAddressData => _selectedBillingAddressData;
  int? get selectedBillingAddressId => _selectedBillingAddressId;
  bool get isBillingSameAsShipping => _isBillingSameAsShipping;
  int get activeStep => _activeStep;
  List<dynamic> get shippingAddressList => _shippingAddressList;
  List<dynamic> get deliveryInfoList => _deliveryInfoList;
  List<dynamic> get paymentTypeList => _paymentTypeList;
  List<SellerWithShipping> get sellerWiseShippingOption =>
      _sellerWiseShippingOption;
  dynamic get selectedAddressData => _selectedAddressData;
  int? get selectedAddressId => _selectedAddressId;
  String? get selectedPaymentMethodKey => _selectedPaymentMethodKey;
  bool get isAddressLoading => _isAddressLoading;
  bool get isDeliveryLoading => _isDeliveryLoading;
  bool get isPaymentLoading => _isPaymentLoading;
  String get subTotal => _subTotal;
  String get shippingCost => _shippingCost;
  String get tax => _tax;
  String get gst => _gst;
  String get grandTotal => _grandTotal;
  String get discount => _discount;
  int get totalItemCount => _totalItemCount;
  int get totalClubPoint => _totalClubPoint;

  // Variables for internal logic
  dynamic _selectedBillingAddressData;
  int? _selectedBillingAddressId;
  bool _isBillingSameAsShipping = true;
  int _activeStep = 0;
  List<dynamic> _shippingAddressList = [];
  List<dynamic> _deliveryInfoList = [];
  List<dynamic> _paymentTypeList = [];
  final List<SellerWithShipping> _sellerWiseShippingOption = [];
  dynamic _selectedAddressData;
  int? _selectedAddressId;
  String? _selectedPaymentMethodKey = "";
  bool _isAddressLoading = true;
  bool _isDeliveryLoading = false;
  bool _isPaymentLoading = false;

  void resetCheckout() {
    _activeStep = 0;
    _selectedAddressId = null;
    _selectedAddressData = null;
    _selectedBillingAddressId = null;
    _selectedBillingAddressData = null;
    _isBillingSameAsShipping = true;
    _selectedPaymentMethodKey = "";
    _deliveryInfoList = [];
    _paymentTypeList = [];
    _sellerWiseShippingOption.clear();
    _subTotal = "...";
    _shippingCost = "...";
    _tax = "...";
    _grandTotal = "...";
    _discount = "...";

    // Reset Coupon & Counts
    couponController.clear();
    _couponApplied = false;
    _appliedCouponCode = "";
    _totalItemCount = 0;
    _totalClubPoint = 0;
    _deliverySectionVisited = false;
    emailErrorText = null;
    nameErrorText = null;
    addressErrorText = null;
    phoneErrorText = null;
    billingNameErrorText = null;
    billingAddressErrorText = null;
    billingPhoneErrorText = null;
    notifyListeners();
  }

  Future<void> fetchBusinessSettings() async {
    try {
      var settingsResponse = await BusinessSettingRepository()
          .getBusinessSettingList();
      var billingSetting = (settingsResponse.data ?? [])
          .where((s) => s.type == "billing_address_required")
          .toList();
      if (billingSetting.isNotEmpty) {
        _isBillingAddressRequired = (billingSetting.first.value == "1");
      }
      var couponSetting = (settingsResponse.data ?? [])
          .where((s) => s.type == "coupon_system")
          .toList();
      if (couponSetting.isNotEmpty) {
        _isCouponSystemActive = (couponSetting.first.value == "1");
      }
    } catch (e) {
      _isBillingAddressRequired = false;
      _isCouponSystemActive = false;
    }
    notifyListeners();
  }

  Future<void> initAddressEditData(dynamic addressData) async {
    _selectedCountry = null;
    _selectedState = null;
    _selectedCity = null;
    _selectedArea = null;
    _countryList = [];
    _stateList = [];
    _cityList = [];
    _areaList = [];
    notifyListeners();
    await fetchCountries();
    try {
      _selectedCountry = _countryList.firstWhere(
        (c) => c.id == addressData.countryId,
      );
    } catch (e) {
      _selectedCountry = null;
    }
    if (_selectedCountry != null) {
      await fetchStates(_selectedCountry.id);
      try {
        _selectedState = _stateList.firstWhere(
          (s) => s.id == addressData.stateId,
        );
      } catch (e) {
        _selectedState = null;
      }
    }
    if (_selectedState != null) {
      await fetchCities(_selectedState.id);
      try {
        _selectedCity = _cityList.firstWhere((c) => c.id == addressData.cityId);
      } catch (e) {
        _selectedCity = null;
      }
    }
    if (_selectedCity != null) {
      await fetchAreas(_selectedCity.id);
      try {
        _selectedArea = _areaList.firstWhere((a) => a.id == addressData.areaId);
      } catch (e) {
        _selectedArea = null;
      }
    }
    notifyListeners();
  }

  void validateEmailOnFocusLoss() {
    String value = guestEmailController.text.trim();
    if (value.isNotEmpty) {
      final bool emailValid = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      ).hasMatch(value);
      emailErrorText = emailValid ? null : "Please enter a valid email address";
    } else {
      emailErrorText = null;
    }
    notifyListeners();
  }

  Future<void> applyCoupon() async {
    String code = couponController.text.trim();
    if (code.isEmpty) {
      ToastComponent.showDialog("Please enter a coupon code");
      return;
    }
    var response = await CouponRepository().getCouponApplyResponse(code);
    if (response.result == true) {
      ToastComponent.showDialog(response.message);
      fetchSummary();
    } else {
      ToastComponent.showDialog(response.message);
    }
  }

  Future<void> removeCoupon() async {
    var response = await CouponRepository().getCouponRemoveResponse();
    if (response.result == true) {
      ToastComponent.showDialog(response.message);
      couponController.clear();
      fetchSummary();
    } else {
      ToastComponent.showDialog(response.message);
    }
  }

  Future<void> fetchCountries() async {
    var res = await AddressRepository().getCountryList();
    _countryList = res.countries;
    if (_countryList.length == 1) {
      _selectedCountry = _countryList[0];
      fetchStates(_selectedCountry.id);
      _selectedBillingCountry = _countryList[0];
      fetchBillingStates(_selectedCountry.id);
    }
    notifyListeners();
  }

  Future<void> fetchStates(int countryId) async {
    _stateList = [];
    _selectedState = null;
    var res = await AddressRepository().getStateListByCountry(
      countryId: countryId,
    );
    _stateList = res.states;
    notifyListeners();
  }

  Future<void> fetchCities(int stateId) async {
    _isCityLoading = true;
    notifyListeners();
    var res = await AddressRepository().getCityListByState(stateId: stateId);
    _cityList = res?.cities ?? [];
    _isCityLoading = false;
    notifyListeners();
  }

  Future<void> fetchAreas(int cityId) async {
    _isAreaLoading = true;
    notifyListeners();
    try {
      var res = await AddressRepository().getAriaListByCity(cityId: cityId);
      if (res != null) {
        if (res is List) {
          _areaList = res;
        } else {
          try {
            _areaList = res.data ?? [];
          } catch (e) {}
          if (_areaList.isEmpty) {
            try {
              _areaList = res.areas ?? [];
            } catch (e) {}
          }
          if (_areaList.isEmpty) {
            try {
              _areaList = res.cities ?? [];
            } catch (e) {}
          }
        }
      } else {
        _areaList = [];
      }
    } catch (e) {
      _areaList = [];
    }
    _isAreaLoading = false;
    notifyListeners();
  }

  void onCountryChange(val) {
    _selectedCountry = val;
    fetchStates(val.id);
    notifyListeners();
  }

  void onStateChange(val) {
    _selectedState = val;
    _cityList = [];
    _selectedCity = null;
    _areaList = [];
    _selectedArea = null;
    fetchCities(val.id);
    notifyListeners();
  }

  Future<void> onCityChange(val) async {
    _selectedCity = val;
    _areaList = [];
    _selectedArea = null;
    notifyListeners();
    await fetchAreas(val.id);
    if (_areaList.isEmpty) {
      _updateShippingAndSummaryBackground();
    }
  }

  void onAreaChange(val) {
    _selectedArea = val;
    notifyListeners();
    _updateShippingAndSummaryBackground();
  }

  Future<void> fetchBillingStates(int countryId) async {
    _billingStateList = [];
    _selectedBillingState = null;
    var res = await AddressRepository().getStateListByCountry(
      countryId: countryId,
    );
    _billingStateList = res.states;
    notifyListeners();
  }

  Future<void> fetchBillingCities(int stateId) async {
    _isBillingCityLoading = true;
    notifyListeners();
    var res = await AddressRepository().getCityListByState(stateId: stateId);
    _billingCityList = res?.cities ?? [];
    _isBillingCityLoading = false;
    notifyListeners();
  }

  Future<void> fetchBillingAreas(int cityId) async {
    _isBillingAreaLoading = true;
    notifyListeners();
    try {
      var res = await AddressRepository().getAriaListByCity(cityId: cityId);
      if (res != null) {
        if (res is List) {
          _billingAreaList = res;
        } else {
          try {
            _billingAreaList = res.data ?? [];
          } catch (e) {}
          if (_billingAreaList.isEmpty) {
            try {
              _billingAreaList = res.areas ?? [];
            } catch (e) {}
          }
          if (_billingAreaList.isEmpty) {
            try {
              _billingAreaList = res.cities ?? [];
            } catch (e) {}
          }
        }
      } else {
        _billingAreaList = [];
      }
    } catch (e) {
      _billingAreaList = [];
    }
    _isBillingAreaLoading = false;
    notifyListeners();
  }

  void onBillingCountryChange(val) {
    _selectedBillingCountry = val;
    fetchBillingStates(val.id);
    notifyListeners();
  }

  void onBillingStateChange(val) {
    _selectedBillingState = val;
    _billingCityList = [];
    _selectedBillingCity = null;
    _billingAreaList = [];
    _selectedBillingArea = null;
    fetchBillingCities(val.id);
    notifyListeners();
  }

  void onBillingCityChange(val) {
    _selectedBillingCity = val;
    _billingAreaList = [];
    _selectedBillingArea = null;
    fetchBillingAreas(val.id);
    notifyListeners();
  }

  void onBillingAreaChange(val) {
    _selectedBillingArea = val;
    notifyListeners();
  }

  void setBillingSameAsShipping(bool value) {
    _isBillingSameAsShipping = value;
    if (value && is_logged_in.$) {
      _selectedBillingAddressId = _selectedAddressId;
      _selectedBillingAddressData = _selectedAddressData;
      updateAddressInCart(_selectedAddressId);
    }
    notifyListeners();
  }

  void setSelectedBillingAddress(dynamic address) {
    _selectedBillingAddressData = address;
    _selectedBillingAddressId = address.id;
    notifyListeners();
  }

  void setActiveStep(int step) {
    _activeStep = step;
    notifyListeners();
  }

  void setSelectedPaymentMethod(String? key) {
    _selectedPaymentMethodKey = key;
    notifyListeners();
  }

  Future<void> onShippingOptionChange(
    int sellerIndex,
    ShippingOption option, {
    int? pickupPointId,
  }) async {
    _sellerWiseShippingOption[sellerIndex].shippingOption = option;
    if (option == ShippingOption.PickUpPoint) {
      _sellerWiseShippingOption[sellerIndex].shippingId = pickupPointId;
    } else {
      _sellerWiseShippingOption[sellerIndex].shippingId = 0;
    }
    notifyListeners();
    var shipping_type_data = [
      {
        "seller_id": _deliveryInfoList[sellerIndex].ownerId,
        "shipping_type": option == ShippingOption.PickUpPoint
            ? "pickup_point"
            : "home_delivery",
        "shipping_id": pickupPointId ?? 0,
      },
    ];
    var response = await AddressRepository().getShippingCostResponse(
      shippingType: shipping_type_data,
    );
    if (response.result == true) await fetchSummary();
  }

  Future<void> fetchAddresses() async {
    if (is_logged_in.$ == false) {
      _shippingAddressList = [];
      _selectedAddressData = null;
      _selectedAddressId = null;
      _selectedBillingAddressData = null;
      _selectedBillingAddressId = null;
      _isAddressLoading = false;
      notifyListeners();
      return;
    }
    _isAddressLoading = true;
    notifyListeners();
    var response = await AddressRepository().getAddressList();
    if (response != null &&
        response.addresses != null &&
        response.addresses.isNotEmpty) {
      _shippingAddressList = response.addresses;
      dynamic selectedAddr;
      for (var addr in _shippingAddressList) {
        if (addr.setDefault == 1) {
          selectedAddr = addr;
          break;
        }
      }
      _selectedAddressData = selectedAddr ?? _shippingAddressList[0];
      _selectedAddressId = _selectedAddressData.id;
      dynamic billingAddr;
      for (var addr in _shippingAddressList) {
        if (addr.setBilling == 1) {
          billingAddr = addr;
          break;
        }
      }
      _selectedBillingAddressData = billingAddr ?? _selectedAddressData;
      _selectedBillingAddressId = _selectedBillingAddressData.id;
      _isBillingSameAsShipping =
          (_selectedAddressId == _selectedBillingAddressId);
      _isAddressLoading = false;
      notifyListeners();
      await updateAddressInCart(_selectedAddressId);
    } else {
      _shippingAddressList = [];
      _selectedAddressData = null;
      _selectedAddressId = null;
      _selectedBillingAddressData = null;
      _selectedBillingAddressId = null;
      _isAddressLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAddressInCart(int? addressId) async {
    if (addressId == null) return;
    int? billingId;
    if (_isBillingAddressRequired) {
      billingId = _isBillingSameAsShipping
          ? addressId
          : (_selectedBillingAddressId ?? addressId);
    } else {
      billingId = addressId;
    }
    var response = await AddressRepository().getAddressUpdateInCartResponse(
      addressId: addressId,
      billingAddressId: billingId,
    );
    if (response.result == true) await fetchSummary();
  }

  Future<void> fetchDeliveryInfo() async {
    _isDeliveryLoading = true;
    notifyListeners();
    dynamic response;
    if (guest_checkout_status.$ && !is_logged_in.$) {
      var addressMap = {
        "name": guestNameController.text.trim().isNotEmpty
            ? guestNameController.text.trim()
            : "Guest",
        "email": guestEmailController.text.trim().isNotEmpty
            ? guestEmailController.text.trim()
            : "guest@temp.com",
        "address": guestAddressController.text.trim().isNotEmpty
            ? guestAddressController.text.trim()
            : "N/A",
        "country_id": "${_selectedCountry?.id ?? ''}",
        "state_id": "${_selectedState?.id ?? 0}",
        "city_id": "${_selectedCity?.id ?? ''}",
        "area_id": _selectedArea != null ? "${_selectedArea.id}" : null,
        "postal_code": guestPostalCodeController.text.trim().isNotEmpty
            ? guestPostalCodeController.text.trim()
            : "0000",
        "phone": guestPhoneController.text.trim().isNotEmpty
            ? guestPhoneController.text.trim()
            : "00000000000",
        "longitude": "",
        "latitude": "",
      };
      response = await ShippingRepository().getDeliveryInfo(
        guestAddress: jsonEncode(addressMap),
      );
    } else {
      response = await ShippingRepository().getDeliveryInfo();
    }
    _deliveryInfoList = response is List
        ? response
        : (response.data ?? response);

    _sellerWiseShippingOption.clear();
    var shipping_type_data = [];
    for (var element in _deliveryInfoList) {
      _sellerWiseShippingOption.add(
        SellerWithShipping(element.ownerId, ShippingOption.HomeDelivery, 0),
      );
      shipping_type_data.add({
        "seller_id": element.ownerId,
        "shipping_type": "home_delivery",
        "shipping_id": 0,
      });
    }
    if (shipping_type_data.isNotEmpty) {
      await AddressRepository().getShippingCostResponse(
        shippingType: shipping_type_data,
      );
      await fetchSummary();
    }
    _isDeliveryLoading = false;
    notifyListeners();
  }

  Future<void> fetchPaymentMethods() async {
    _isPaymentLoading = true;
    notifyListeners();
    var response = await PaymentRepository().getPaymentResponseList(
      mode: "order",
    );
    _paymentTypeList = response;
    if (_paymentTypeList.isNotEmpty) {
      _selectedPaymentMethodKey = _paymentTypeList[0].paymentTypeKey;
    }
    _isPaymentLoading = false;
    notifyListeners();
  }

  Future<void> fetchSummary() async {
    var response = await CartRepository().getCartSummaryResponse();
    if (response != null) {
      _subTotal = response.subTotal ?? "0.00";
      _tax = response.tax ?? "0.00";
      _gst = response.gst ?? response.tax ?? "0.00";
      _shippingCost = response.shippingCost ?? "0.00";
      _grandTotal = response.grandTotal.toString();
      _discount = response.discount ?? "0.00";
      _couponApplied = response.couponApplied ?? false;
      _appliedCouponCode = response.couponCode ?? "";

      _totalItemCount = response.totalProduct ?? 0;
      _totalClubPoint = response.clubPoint ?? 0;

      notifyListeners();
    }
  }

  Future<void> _updateShippingAndSummaryBackground() async {
    if (!(guest_checkout_status.$ && !is_logged_in.$)) return;
    if (_selectedCity == null) return;
    var postBodyMap = {
      "temp_user_id": temp_user_id.$,
      "address": {
        "name": guestNameController.text.trim().isNotEmpty
            ? guestNameController.text.trim()
            : "Guest",
        "email": guestEmailController.text.trim().isNotEmpty
            ? guestEmailController.text.trim()
            : "guest@example.com",
        "address": guestAddressController.text.trim().isNotEmpty
            ? guestAddressController.text.trim()
            : "N/A",
        "country_id": "${_selectedCountry?.id ?? ''}",
        "state_id": "${_selectedState?.id ?? 0}",
        "city_id": "${_selectedCity?.id ?? ''}",
        "area_id": _selectedArea != null ? "${_selectedArea.id}" : null,
        "postal_code": guestPostalCodeController.text.trim().isNotEmpty
            ? guestPostalCodeController.text.trim()
            : "0000",
        "phone": guestPhoneController.text.trim().isNotEmpty
            ? guestPhoneController.text.trim()
            : "00000000000",
        "longitude": "",
        "latitude": "",
      },
    };
    if (_isBillingAddressRequired && !_isBillingSameAsShipping) {
      postBodyMap["billing_address"] = {
        "name": guestBillingNameController.text.trim().isNotEmpty
            ? guestBillingNameController.text.trim()
            : "Guest",
        "email": guestEmailController.text.trim().isNotEmpty
            ? guestEmailController.text.trim()
            : "guest@example.com",
        "address": guestBillingAddressController.text.trim().isNotEmpty
            ? guestBillingAddressController.text.trim()
            : "N/A",
        "country_id": "${_selectedBillingCountry?.id ?? ''}",
        "state_id": "${_selectedBillingState?.id ?? 0}",
        "city_id": "${_selectedBillingCity?.id ?? ''}",
        "area_id": _selectedBillingArea != null
            ? "${_selectedBillingArea.id}"
            : null,
        "postal_code": guestBillingPostalCodeController.text.trim().isNotEmpty
            ? guestBillingPostalCodeController.text.trim()
            : "0000",
        "phone": guestBillingPhoneController.text.trim().isNotEmpty
            ? guestBillingPhoneController.text.trim()
            : "00000000000",
        "longitude": "",
        "latitude": "",
      };
    }
    try {
      var saveResponse = await GuestCheckoutRepository().guestCustomerInfoCheck(
        jsonEncode(postBodyMap),
      );
      if (saveResponse.result == true) {
        await fetchDeliveryInfo();
      }
    } catch (e) {}
  }

  Future<bool> submitGuestAddress(BuildContext context) async {
    bool isValid = true;
    if (guestNameController.text.trim().isEmpty) {
      nameErrorText = "This field is required";
      isValid = false;
    } else {
      nameErrorText = null;
    }
    if (guestEmailController.text.trim().isEmpty) {
      emailErrorText = "This field is required";
      isValid = false;
    } else {
      final bool emailValid = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      ).hasMatch(guestEmailController.text.trim());
      if (!emailValid) {
        emailErrorText = "Please enter a valid email address";
        isValid = false;
      } else {
        emailErrorText = null;
      }
    }
    if (guestAddressController.text.trim().isEmpty) {
      addressErrorText = "This field is required";
      isValid = false;
    } else {
      addressErrorText = null;
    }
    if (guestPhoneController.text.trim().isEmpty) {
      phoneErrorText = "This field is required";
      isValid = false;
    } else {
      phoneErrorText = null;
    }
    if (_selectedCountry == null || _selectedCity == null) {
      ToastComponent.showDialog("Please select Shipping Country and City");
      isValid = false;
    }
    if (_areaList.isNotEmpty && _selectedArea == null) {
      ToastComponent.showDialog("Please select a Shipping Area");
      isValid = false;
    }
    if (_isBillingAddressRequired && !_isBillingSameAsShipping) {
      if (guestBillingNameController.text.trim().isEmpty) {
        billingNameErrorText = "This field is required";
        isValid = false;
      } else {
        billingNameErrorText = null;
      }
      if (guestBillingAddressController.text.trim().isEmpty) {
        billingAddressErrorText = "This field is required";
        isValid = false;
      } else {
        billingAddressErrorText = null;
      }
      if (guestBillingPhoneController.text.trim().isEmpty) {
        billingPhoneErrorText = "This field is required";
        isValid = false;
      } else {
        billingPhoneErrorText = null;
      }
      if (_selectedBillingCountry == null || _selectedBillingCity == null) {
        ToastComponent.showDialog("Please select Billing Country and City");
        isValid = false;
      }
      if (_billingAreaList.isNotEmpty && _selectedBillingArea == null) {
        ToastComponent.showDialog("Please select a Billing Area");
        isValid = false;
      }
    }
    notifyListeners();
    if (!isValid) return false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    var postBodyMap = {
      "temp_user_id": temp_user_id.$,
      "address": {
        "name": guestNameController.text.trim(),
        "email": guestEmailController.text.trim(),
        "address": guestAddressController.text.trim(),
        "country_id": "${_selectedCountry?.id ?? ''}",
        "state_id": "${_selectedState?.id ?? 0}",
        "city_id": "${_selectedCity?.id ?? ''}",
        "area_id": _selectedArea != null ? "${_selectedArea.id}" : null,
        "postal_code": guestPostalCodeController.text.trim(),
        "phone": guestPhoneController.text.trim(),
        "longitude": "",
        "latitude": "",
      },
    };
    if (_isBillingAddressRequired && !_isBillingSameAsShipping) {
      postBodyMap["billing_address"] = {
        "name": guestBillingNameController.text.trim(),
        "email": guestEmailController.text.trim(),
        "address": guestBillingAddressController.text.trim(),
        "country_id": "${_selectedBillingCountry?.id ?? ''}",
        "state_id": "${_selectedBillingState?.id ?? 0}",
        "city_id": "${_selectedBillingCity?.id ?? ''}",
        "area_id": _selectedBillingArea != null
            ? "${_selectedBillingArea.id}"
            : null,
        "postal_code": guestBillingPostalCodeController.text.trim(),
        "phone": guestBillingPhoneController.text.trim(),
        "longitude": "",
        "latitude": "",
      };
    }
    var response = await GuestCheckoutRepository().guestCustomerInfoCheck(
      jsonEncode(postBodyMap),
    );
    if (!context.mounted) return false;
    Navigator.of(context, rootNavigator: true).pop();
    if (response.result == true) {
      return true;
    } else {
      ToastComponent.showDialog("Something went wrong!");
      return false;
    }
  }

  Future<void> confirmOrder(BuildContext context) async {
    if (_selectedPaymentMethodKey == "") {
      ToastComponent.showDialog("Please select a payment method");
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    if (guest_checkout_status.$ && !is_logged_in.$) {
      bool success = await submitGuestAddress(context);
      if (!success) return;
      Map<String, dynamic> postBodyMap = {
        "name": guestNameController.text.trim(),
        "email": guestEmailController.text.trim(),
        "phone": guestPhoneController.text.trim(),
        "temp_user_id": temp_user_id.$,
        "address": guestAddressController.text.trim(),
        "country_id": "${_selectedCountry?.id ?? ''}",
        "state_id": "${_selectedState?.id ?? 0}",
        "city_id": "${_selectedCity?.id ?? ''}",
        "area_id": _selectedArea != null ? "${_selectedArea.id}" : null,
        "postal_code": guestPostalCodeController.text.trim(),
      };
      if (_isBillingAddressRequired) {
        if (_isBillingSameAsShipping) {
          postBodyMap["set_billing"] = "1";
        } else {
          postBodyMap["billing_name"] = guestBillingNameController.text.trim();
          postBodyMap["billing_phone"] = guestBillingPhoneController.text
              .trim();
          postBodyMap["billing_address"] = guestBillingAddressController.text
              .trim();
          postBodyMap["billing_country_id"] =
              "${_selectedBillingCountry?.id ?? ''}";
          postBodyMap["billing_state_id"] = "${_selectedBillingState?.id ?? 0}";
          postBodyMap["billing_city_id"] = "${_selectedBillingCity?.id ?? ''}";
          postBodyMap["billing_area_id"] = _selectedBillingArea != null
              ? "${_selectedBillingArea.id}"
              : null;
          postBodyMap["billing_postal_code"] = guestBillingPostalCodeController
              .text
              .trim();
        }
      }
      var loginResponse = await GuestCheckoutRepository()
          .guestUserAccountCreate(jsonEncode(postBodyMap));
      if (loginResponse.result == true) {
        is_logged_in.$ = true;
        is_logged_in.save();
        access_token.$ = loginResponse.access_token;
        access_token.save();
        user_id.$ = loginResponse.user.id;
        user_id.save();
      } else {
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        ToastComponent.showDialog(
          loginResponse.message ?? "Could not create guest account",
        );
        return;
      }
    }
    var orderCreateResponse = await PaymentRepository()
        .getOrderCreateResponseFromCod(_selectedPaymentMethodKey);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (orderCreateResponse.result == true) {
      ToastComponent.showDialog(orderCreateResponse.message);
      resetCheckout();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => OrderList(fromCheckout: true),
            ),
            (route) => false,
          );
        }
      });
    } else {
      ToastComponent.showDialog(orderCreateResponse.message);
    }
  }
}
