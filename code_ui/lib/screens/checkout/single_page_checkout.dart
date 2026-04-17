import 'package:active_ecommerce_cms_demo_app/custom/dash_divider.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/address_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/main_helpers.dart';
import '../../providers/checkout_provider.dart';
import 'package:active_ecommerce_cms_demo_app/screens/address.dart'
    as address_ui;

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var provider = Provider.of<CheckoutProvider>(context, listen: false);
      provider.resetCheckout();
      provider.fetchBusinessSettings();
      provider.fetchAddresses();
      provider.fetchSummary();
      provider.fetchDeliveryInfo();

      if (guest_checkout_status.$ && !is_logged_in.$) {
        provider.fetchCountries();
      }
      provider.guestEmailFocusNode.addListener(() {
        if (!provider.guestEmailFocusNode.hasFocus) {
          provider.validateEmailOnFocusLoss();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutProvider>(
      builder: (context, provider, child) {
        bool isGuest = guest_checkout_status.$ && !is_logged_in.$;

        return Scaffold(
          backgroundColor: const Color(0xffF2F1F6),
          appBar: AppBar(
            title: const Text(
              "Checkout",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          bottomNavigationBar: buildBottomAction(provider),
          body: SingleChildScrollView(
            child: Column(
              children: [
                buildExpandableSection(
                  context,
                  provider,
                  0,
                  "Shipping Info",
                  isGuest
                      ? provider.deliveryInfoList.isNotEmpty
                      : provider.selectedAddressId != null,
                  buildSelectedAddressSection(provider),
                ),
                buildExpandableSection(
                  context,
                  provider,
                  1,
                  "Delivery Info",
                  provider.deliveryInfoList.isNotEmpty &&
                      provider.deliverySectionVisited,
                  buildDeliverySection(provider),
                ),

                buildExpandableSection(
                  context,
                  provider,
                  2,
                  "Payment Method",
                  provider.selectedPaymentMethodKey != "",
                  buildPaymentSection(provider),
                ),
                const SizedBox(height: 20),
                buildOrderSummary(provider),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildOrderSummary(CheckoutProvider provider) {
    double discountValue = 0.0;
    try {
      String cleanDiscount = provider.discount.toString().replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );
      discountValue = double.tryParse(cleanDiscount) ?? 0.0;
    } catch (e) {
      discountValue = 0.0;
    }

    bool isClubPointActive = club_point_addon_installed.$ == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 45,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: MyTheme.accent_color,
                      borderRadius: isClubPointActive
                          ? const BorderRadius.only(topLeft: Radius.circular(8))
                          : const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Total Products  ${provider.totalItemCount.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (isClubPointActive)
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Total Clubpoint  ${provider.totalClubPoint}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                summaryRow(
                  "Subtotal (${provider.totalItemCount.toString().padLeft(2, '0')} Products)",
                  convertPrice(provider.subTotal),
                ),
                summaryRow(
                  "Total Shipping",
                  convertPrice(provider.shippingCost),
                ),
                gst_addon_installed.$ == true
                    ? summaryRow("GST", convertPrice(provider.gst))
                    : summaryRow("Tax", convertPrice(provider.tax)),
                if (discountValue > 0)
                  summaryRow(
                    "Coupon Discount",
                    convertPrice(provider.discount),
                  ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TOTAL",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      convertPrice(provider.grandTotal),
                      style: TextStyle(
                        color: MyTheme.accent_color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (provider.isCouponSystemActive)
                  Row(
                    children: [
                      Expanded(
                        child: provider.couponApplied
                            ? Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.grey.shade50,
                                ),
                                child: Text(
                                  provider.appliedCouponCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: 40,
                                child: TextField(
                                  controller: provider.couponController,
                                  decoration: InputDecoration(
                                    hintText: "Enter Coupon Code",
                                    hintStyle: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 0,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: MyTheme.accent_color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MyTheme.accent_color,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () {
                            if (provider.couponApplied) {
                              provider.removeCoupon();
                            } else {
                              provider.applyCoupon();
                            }
                          },
                          child: Text(
                            provider.couponApplied ? "Change Coupon" : "Apply",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration guestInputDecoration(String hint, {String? errorText}) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      errorStyle: const TextStyle(fontSize: 11, color: Colors.red),
      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: MyTheme.accent_color, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  Widget summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // buildExpandableSection ---
  Widget buildExpandableSection(
    BuildContext context,
    CheckoutProvider provider,
    int stepIndex,
    String title,
    bool isDone,
    Widget bodyContent,
  ) {
    bool isOpen = provider.activeStep == stepIndex;
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 12, right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            onTap: () async {
              if (provider.activeStep == stepIndex) {
                provider.setActiveStep(-1);
                return;
              }
              bool isGuest = guest_checkout_status.$ && !is_logged_in.$;

              if (stepIndex == 1) {
                // DELIVERY STEP
                if (isGuest) {
                  bool success = await provider.submitGuestAddress(context);
                  if (!success) return;
                } else {
                  if (provider.selectedAddressId == null) {
                    ToastComponent.showDialog(
                      "Please select a shipping address",
                    );
                    return;
                  }
                }
                if (provider.deliveryInfoList.isEmpty) {
                  await provider.fetchDeliveryInfo();
                }

                provider.setDeliverySectionVisited();
              }

              if (stepIndex == 2) {
                // PAYMENT STEP
                if (isGuest) {
                  bool success = await provider.submitGuestAddress(context);
                  if (!success) return;
                } else {
                  if (provider.selectedAddressId == null) {
                    ToastComponent.showDialog(
                      "Please select a shipping address",
                    );
                    return;
                  }
                }
                if (provider.deliveryInfoList.isEmpty) {
                  ToastComponent.showDialog("Please select delivery info");
                  return;
                }
                if (provider.paymentTypeList.isEmpty) {
                  await provider.fetchPaymentMethods();
                }

                provider.setDeliverySectionVisited();
              }
              provider.setActiveStep(stepIndex);
            },
            leading: Icon(
              isDone ? Icons.check_circle : Icons.circle_outlined,
              color: isDone ? Colors.green : Colors.grey,
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            trailing: Icon(
              isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  bodyContent,
                ],
              ),
            ),
        ],
      ),
    );
  }

  //  Proceed Button in Shipping Section ---
  Widget buildSelectedAddressSection(CheckoutProvider provider) {
    if (guest_checkout_status.$ && !is_logged_in.$) {
      return buildGuestAddressContainer(provider);
    }
    if (provider.isAddressLoading) {
      return ShimmerHelper().buildListShimmer(itemCount: 1);
    }
    if (provider.selectedAddressData == null) {
      return GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => address_ui.Address()),
          );
          provider.fetchAddresses();
        },
        child: Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: MyTheme.accent_color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: MyTheme.accent_color),
              const SizedBox(width: 10),
              Text(
                "Add new address",
                style: TextStyle(color: MyTheme.accent_color),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Shipping address",
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            InkWell(
              onTap: () => showEditAddressDialog(provider.selectedAddressData),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: MyTheme.accent_color,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Change",
                      style: TextStyle(
                        color: MyTheme.accent_color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: MyTheme.accent_color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        addressBox(provider.selectedAddressData),
        if (provider.isBillingAddressRequired) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 24,
                child: Checkbox(
                  value: provider.isBillingSameAsShipping,
                  activeColor: MyTheme.accent_color,
                  onChanged: (bool? value) =>
                      provider.setBillingSameAsShipping(value ?? true),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Use this as billing address",
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          if (!provider.isBillingSameAsShipping) ...[
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Billing address",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () => showEditAddressDialog(
                        provider.selectedBillingAddressData,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: MyTheme.accent_color,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Change",
                              style: TextStyle(
                                color: MyTheme.accent_color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: MyTheme.accent_color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                addressBox(provider.selectedBillingAddressData),
              ],
            ),
          ],
        ],
      ],

      // --- Proceed Button  ---
    );
  }

  Widget buildGuestAddressContainer(CheckoutProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Guest Shipping Information",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 15),
        buildAddressFields(provider, isBilling: false),
        if (provider.isBillingAddressRequired) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 24,
                child: Checkbox(
                  value: provider.isBillingSameAsShipping,
                  activeColor: MyTheme.accent_color,
                  onChanged: (bool? value) =>
                      provider.setBillingSameAsShipping(value ?? true),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Use this as billing address",
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          if (!provider.isBillingSameAsShipping) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              "Guest Billing Information",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 15),
            buildAddressFields(provider, isBilling: true),
          ],
        ],
      ],
    );
  }

  Widget buildAddressFields(
    CheckoutProvider provider, {
    required bool isBilling,
  }) {
    bool showAreaDropdown = isBilling
        ? (provider.billingAreaList.isNotEmpty || provider.isBillingAreaLoading)
        : (provider.areaList.isNotEmpty || provider.isAreaLoading);
    var cityList = isBilling ? provider.billingCityList : provider.cityList;
    var isCityLoading = isBilling
        ? provider.isBillingCityLoading
        : provider.isCityLoading;
    var selectedState = isBilling
        ? provider.selectedBillingState
        : provider.selectedState;
    return Column(
      children: [
        TextField(
          controller: isBilling
              ? provider.guestBillingNameController
              : provider.guestNameController,
          onChanged: (val) {
            if (isBilling) {
              if (provider.billingNameErrorText != null) {
                provider.billingNameErrorText = null;
                provider.notifyListeners();
              }
            } else {
              if (provider.nameErrorText != null) {
                provider.nameErrorText = null;
                provider.notifyListeners();
              }
            }
          },
          decoration: guestInputDecoration(
            "Name *",
            errorText: isBilling
                ? provider.billingNameErrorText
                : provider.nameErrorText,
          ),
        ),
        const SizedBox(height: 10),
        if (!isBilling) ...[
          TextField(
            controller: provider.guestEmailController,
            focusNode: provider.guestEmailFocusNode,
            keyboardType: TextInputType.emailAddress,
            onChanged: (val) {
              if (provider.emailErrorText != null) {
                provider.emailErrorText = null;
                provider.notifyListeners();
              }
            },
            decoration: guestInputDecoration(
              "Email *",
              errorText: provider.emailErrorText,
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: isBilling
              ? provider.guestBillingAddressController
              : provider.guestAddressController,
          onChanged: (val) {
            if (isBilling) {
              if (provider.billingAddressErrorText != null) {
                provider.billingAddressErrorText = null;
                provider.notifyListeners();
              }
            } else {
              if (provider.addressErrorText != null) {
                provider.addressErrorText = null;
                provider.notifyListeners();
              }
            }
          },
          decoration: guestInputDecoration(
            "Address *",
            errorText: isBilling
                ? provider.billingAddressErrorText
                : provider.addressErrorText,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<dynamic>(
          dropdownColor: Colors.white,
          isExpanded: true,
          decoration: guestInputDecoration("Select Country *"),
          hint: const Text(
            "Select Country *",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          value: isBilling
              ? provider.selectedBillingCountry
              : provider.selectedCountry,
          items: provider.countryList
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c.name,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => isBilling
              ? provider.onBillingCountryChange(val)
              : provider.onCountryChange(val),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<dynamic>(
          dropdownColor: Colors.white,
          isExpanded: true,
          decoration: guestInputDecoration("Select State"),
          hint: const Text(
            "Select State",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          value: isBilling
              ? provider.selectedBillingState
              : provider.selectedState,
          items: (isBilling ? provider.billingStateList : provider.stateList)
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s.name,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => isBilling
              ? provider.onBillingStateChange(val)
              : provider.onStateChange(val),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<dynamic>(
          dropdownColor: Colors.white,
          isExpanded: true,
          decoration: guestInputDecoration("Select City *"),
          hint: const Text(
            "Select City *",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          value: isBilling
              ? provider.selectedBillingCity
              : provider.selectedCity,
          items: selectedState == null
              ? null
              : (isCityLoading
                    ? [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            "Loading cities...",
                            style: TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        ),
                      ]
                    : (cityList.isEmpty
                          ? [
                              const DropdownMenuItem(
                                value: null,
                                child: Text(
                                  "No cities available",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ]
                          : cityList
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                )
                                .toList())),
          onChanged:
              (selectedState == null || isCityLoading || cityList.isEmpty)
              ? null
              : (val) => isBilling
                    ? provider.onBillingCityChange(val)
                    : provider.onCityChange(val),
        ),
        const SizedBox(height: 10),
        if (showAreaDropdown) ...[
          DropdownButtonFormField<dynamic>(
            dropdownColor: Colors.white,
            isExpanded: true,
            decoration: guestInputDecoration("Select Area *"),
            hint: Text(
              (isBilling
                      ? provider.isBillingAreaLoading
                      : provider.isAreaLoading)
                  ? "Loading Areas..."
                  : "Select Area *",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            value: isBilling
                ? provider.selectedBillingArea
                : provider.selectedArea,
            items: (isBilling ? provider.billingAreaList : provider.areaList)
                .map(
                  (a) => DropdownMenuItem(
                    value: a,
                    child: Text(
                      a.name,
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) => isBilling
                ? provider.onBillingAreaChange(val)
                : provider.onAreaChange(val),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: isBilling
              ? provider.guestBillingPostalCodeController
              : provider.guestPostalCodeController,
          decoration: guestInputDecoration("Postal Code"),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: isBilling
              ? provider.guestBillingPhoneController
              : provider.guestPhoneController,
          keyboardType: TextInputType.phone,
          onChanged: (val) {
            if (isBilling) {
              if (provider.billingPhoneErrorText != null) {
                provider.billingPhoneErrorText = null;
                provider.notifyListeners();
              }
            } else {
              if (provider.phoneErrorText != null) {
                provider.phoneErrorText = null;
                provider.notifyListeners();
              }
            }
          },
          decoration: guestInputDecoration(
            "Phone Number *",
            errorText: isBilling
                ? provider.billingPhoneErrorText
                : provider.phoneErrorText,
          ),
        ),
      ],
    );
  }

  Widget addressBox(dynamic addressData) {
    if (addressData == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: MyTheme.accent_color),
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Text("No address available"),
      );
    }
    List<String> parts = [];
    if (addressData.address != null &&
        addressData.address.toString().isNotEmpty) {
      parts.add(addressData.address);
    }
    if (addressData.cityName != null &&
        addressData.cityName.toString().isNotEmpty) {
      parts.add(addressData.cityName);
    }
    if (addressData.stateName != null &&
        addressData.stateName.toString().isNotEmpty) {
      parts.add(addressData.stateName);
    }
    if (addressData.countryName != null &&
        addressData.countryName.toString().isNotEmpty) {
      parts.add(addressData.countryName);
    }
    if (addressData.postalCode != null &&
        addressData.postalCode.toString().isNotEmpty) {
      parts.add(addressData.postalCode);
    }
    String fullAddress = parts.join(", ");
    if (addressData.phone != null && addressData.phone.toString().isNotEmpty) {
      fullAddress += "\n${addressData.phone}";
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: MyTheme.accent_color),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 2, right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MyTheme.accent_color, width: 2),
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MyTheme.accent_color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: Text(
                fullAddress,
                style: const TextStyle(fontSize: 13, height: 1.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDeliverySection(CheckoutProvider provider) {
    if (provider.isDeliveryLoading) {
      return ShimmerHelper().buildListShimmer(itemCount: 1);
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.deliveryInfoList.length,
      itemBuilder: (context, index) {
        var seller = provider.deliveryInfoList[index];
        var currentOption =
            provider.sellerWiseShippingOption[index].shippingOption;
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                seller.name ?? "Store Name",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Padding(padding: .symmetric(vertical: 8), child: DashedDivider()),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(
                      seller.cartItems[0].productThumbnailImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      seller.cartItems[0].productName,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "Choose Delivery Type",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  buildDeliveryTypeButton(
                    index,
                    ShippingOption.HomeDelivery,
                    "Home Delivery",
                    Icons.home_outlined,
                    provider,
                  ),
                  const SizedBox(width: 10),
                  buildDeliveryTypeButton(
                    index,
                    ShippingOption.PickUpPoint,
                    "Local Pickup",
                    Icons.location_on_outlined,
                    provider,
                  ),
                ],
              ),
              if (currentOption == ShippingOption.PickUpPoint)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    const Text(
                      "Select Pickup Point",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...seller.pickupPoints.map<Widget>((point) {
                      bool isThisPointSelected =
                          provider.sellerWiseShippingOption[index].shippingId ==
                          point.id;
                      return GestureDetector(
                        onTap: () => provider.onShippingOptionChange(
                          index,
                          ShippingOption.PickUpPoint,
                          pickupPointId: point.id,
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isThisPointSelected
                                  ? MyTheme.accent_color
                                  : Colors.grey.shade300,
                              width: isThisPointSelected ? 2 : 1,
                            ),
                            color: isThisPointSelected
                                ? MyTheme.accent_color.withValues(alpha: 0.05)
                                : Colors.white,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_city,
                                size: 20,
                                color: isThisPointSelected
                                    ? MyTheme.accent_color
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      point.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isThisPointSelected
                                            ? MyTheme.accent_color
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Address: ${point.address}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      "Phone: ${point.phone}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isThisPointSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: MyTheme.accent_color,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget buildDeliveryTypeButton(
    int index,
    ShippingOption option,
    String title,
    IconData icon,
    CheckoutProvider provider,
  ) {
    bool isSelected =
        provider.sellerWiseShippingOption[index].shippingOption == option;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.onShippingOptionChange(index, option),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? MyTheme.accent_color : Colors.white,
            border: Border.all(
              color: isSelected ? MyTheme.accent_color : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPaymentSection(CheckoutProvider provider) {
    if (provider.isPaymentLoading) {
      return ShimmerHelper().buildListShimmer(itemCount: 3);
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.paymentTypeList.length,
      itemBuilder: (context, index) {
        var pay = provider.paymentTypeList[index];
        bool isSelected =
            provider.selectedPaymentMethodKey == pay.paymentTypeKey;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isSelected ? MyTheme.accent_color : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            onTap: () => provider.setSelectedPaymentMethod(pay.paymentTypeKey),
            leading: Image.network(pay.image, width: 80),
            title: Text(pay.title),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
        );
      },
    );
  }

  Widget buildBottomAction(CheckoutProvider provider) {
    String btnText = provider.activeStep == 0
        ? "Proceed to Delivery"
        : (provider.activeStep == 1 ? "Proceed to Payment" : "Confirm Order");

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () async {
              bool isGuest = guest_checkout_status.$ && !is_logged_in.$;
              if (provider.activeStep == 0) {
                if (isGuest) {
                  bool success = await provider.submitGuestAddress(context);
                  if (success) {
                    provider.setActiveStep(1);
                    if (provider.deliveryInfoList.isEmpty) {
                      provider.fetchDeliveryInfo();
                    }

                    provider.setDeliverySectionVisited();
                  }
                } else {
                  if (provider.selectedAddressId == null) {
                    ToastComponent.showDialog(
                      "Please select a shipping address",
                    );
                    return;
                  }
                  provider.setActiveStep(1);
                  if (provider.deliveryInfoList.isEmpty) {
                    provider.fetchDeliveryInfo();
                  }

                  provider.setDeliverySectionVisited();
                }
              } else if (provider.activeStep == 1) {
                if (provider.deliveryInfoList.isEmpty) {
                  ToastComponent.showDialog("Please select delivery info");
                  return;
                }
                provider.setActiveStep(2);
                if (provider.paymentTypeList.isEmpty) {
                  provider.fetchPaymentMethods();
                }
              } else if (provider.activeStep == 2) {
                if (provider.selectedPaymentMethodKey == "") {
                  ToastComponent.showDialog("Please select a payment method");
                  return;
                }
                provider.confirmOrder(context);
              }
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: MyTheme.accent_color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  btnText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  showEditAddressDialog(dynamic addressData) {
    var provider = Provider.of<CheckoutProvider>(context, listen: false);
    provider.initAddressEditData(addressData);
    TextEditingController addressController = TextEditingController(
      text: addressData.address,
    );
    TextEditingController phoneController = TextEditingController(
      text: addressData.phone,
    );
    TextEditingController postalCodeController = TextEditingController(
      text: addressData.postalCode,
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer<CheckoutProvider>(
          builder: (context, checkoutProvider, child) {
            return AlertDialog(
              backgroundColor: MyTheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Edit Address",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      editLabel("Address"),
                      TextField(
                        controller: addressController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: editInputDecoration(),
                      ),
                      const SizedBox(height: 10),
                      if (checkoutProvider.countryList.length > 1)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            editLabel("Country"),
                            DropdownButtonFormField<dynamic>(
                              dropdownColor: Colors.white,
                              isExpanded: true,
                              decoration: editInputDecoration(),
                              hint: const Text(
                                "Select Country",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey,
                              ),
                              value: checkoutProvider.selectedCountry,
                              items: checkoutProvider.countryList
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  checkoutProvider.onCountryChange(val),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      editLabel("State"),
                      DropdownButtonFormField<dynamic>(
                        dropdownColor: Colors.white,
                        isExpanded: true,
                        decoration: editInputDecoration(),
                        hint: const Text(
                          "Select State",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey,
                        ),
                        value: checkoutProvider.selectedState,
                        items: checkoutProvider.stateList
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => checkoutProvider.onStateChange(val),
                      ),
                      const SizedBox(height: 10),
                      editLabel("City"),
                      DropdownButtonFormField<dynamic>(
                        dropdownColor: Colors.white,
                        isExpanded: true,
                        decoration: editInputDecoration(),
                        hint: const Text(
                          "Select City",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey,
                        ),
                        value: checkoutProvider.selectedCity,
                        items: checkoutProvider.selectedState == null
                            ? null
                            : (checkoutProvider.isCityLoading
                                  ? [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text(
                                          "Loading cities...",
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ]
                                  : (checkoutProvider.cityList.isEmpty
                                        ? [
                                            const DropdownMenuItem(
                                              value: null,
                                              child: Text(
                                                "No City Available",
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ]
                                        : checkoutProvider.cityList
                                              .map(
                                                (ct) => DropdownMenuItem(
                                                  value: ct,
                                                  child: Text(
                                                    ct.name,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList())),
                        onChanged:
                            (checkoutProvider.selectedState == null ||
                                checkoutProvider.isCityLoading ||
                                checkoutProvider.cityList.isEmpty)
                            ? null
                            : (val) => checkoutProvider.onCityChange(val),
                      ),
                      const SizedBox(height: 10),
                      if (checkoutProvider.areaList.isNotEmpty ||
                          checkoutProvider.isAreaLoading) ...[
                        editLabel("Area"),
                        DropdownButtonFormField<dynamic>(
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          decoration: editInputDecoration(),
                          hint: Text(
                            checkoutProvider.isAreaLoading
                                ? "Loading Areas..."
                                : "Select Area",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey,
                          ),
                          value: checkoutProvider.selectedArea,
                          items: checkoutProvider.areaList
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(
                                    a.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              checkoutProvider.onAreaChange(val),
                        ),
                        const SizedBox(height: 10),
                      ],
                      editLabel("Postal Code"),
                      TextField(
                        controller: postalCodeController,
                        decoration: editInputDecoration(),
                      ),
                      const SizedBox(height: 10),
                      editLabel("Phone"),
                      TextField(
                        controller: phoneController,
                        decoration: editInputDecoration(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyTheme.accent_color,
                    ),
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );
                      var response = await AddressRepository()
                          .getAddressUpdateResponse(
                            id: addressData.id,
                            address: addressController.text,
                            countryId:
                                checkoutProvider.selectedCountry?.id ??
                                addressData.countryId,
                            stateId:
                                checkoutProvider.selectedState?.id ??
                                addressData.stateId,
                            cityId:
                                checkoutProvider.selectedCity?.id ??
                                addressData.cityId,
                            areaId:
                                checkoutProvider.selectedArea?.id ??
                                addressData.areaId ??
                                0,
                            postalCode: postalCodeController.text,
                            phone: phoneController.text,
                          );
                      Navigator.pop(context);
                      if (response.result == true) {
                        Navigator.pop(context);
                        ToastComponent.showDialog(response.message);
                        await checkoutProvider.fetchAddresses();
                        await checkoutProvider.fetchDeliveryInfo();
                      } else {
                        ToastComponent.showDialog(response.message);
                      }
                    },
                    child: const Text(
                      "Save",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration editInputDecoration() => InputDecoration(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(color: MyTheme.accent_color, width: 1),
    ),
  );
  Widget editLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4.0),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    ),
  );
}
