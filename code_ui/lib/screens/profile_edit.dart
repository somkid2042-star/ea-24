import 'dart:convert';

import 'package:active_ecommerce_cms_demo_app/custom/box_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/custom/btn.dart';
import 'package:active_ecommerce_cms_demo_app/custom/input_decorations.dart';
import 'package:active_ecommerce_cms_demo_app/custom/lang_text.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/file_helper.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/profile_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileEdit extends StatefulWidget {
  const ProfileEdit({super.key});

  @override
  State<ProfileEdit> createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  final ScrollController _mainScrollController = ScrollController();

  final TextEditingController _nameController = TextEditingController(
    text: "${user_name.$}",
  );

  final TextEditingController _phoneController = TextEditingController(
    text: user_phone.$,
  );

  final TextEditingController _emailController = TextEditingController(
    text: user_email.$,
  );
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  //for image uploading
  final ImagePicker _picker = ImagePicker();
  XFile? _file;
  chooseAndUploadImage(context) async {
    bool? userAgreed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.photo_permission_ucf),
        // This is the most important part for Google's policy.
        content: Text(
          "To set your profile picture, this app needs to collect your image from the gallery.",
        ),
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
    if (userAgreed == null || !userAgreed) {
      ToastComponent.showDialog("Permission denied to access photos.");
      return;
    }
    _file = await _picker.pickImage(source: ImageSource.gallery);

    if (_file == null) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.no_file_is_chosen,
      );
      return;
    }
    String base64Image = FileHelper.getBase64FormateFile(_file!.path);
    String fileName = _file!.path.split("/").last;

    var profileImageUpdateResponse = await ProfileRepository()
        .getProfileImageUpdateResponse(base64Image, fileName);

    if (profileImageUpdateResponse.result == false) {
      ToastComponent.showDialog(profileImageUpdateResponse.message);
      return;
    } else {
      ToastComponent.showDialog(profileImageUpdateResponse.message);

      avatar_original.$ = profileImageUpdateResponse.path;
      setState(() {});
    }
  }

  Future<void> _onPageRefresh() async {}

  onPressUpdate() async {
    var name = _nameController.text.toString();
    var phone = _phoneController.text.toString();

    if (name == "") {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_your_name);
      return;
    }
    if (phone == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.enter_phone_number,
      );
      return;
    }

    var postBody = jsonEncode({"name": name, "phone": phone});

    var profileUpdateResponse = await ProfileRepository()
        .getProfileUpdateResponse(postBody: postBody);

    if (profileUpdateResponse.result == false) {
      ToastComponent.showDialog(profileUpdateResponse.message);
    } else {
      ToastComponent.showDialog(profileUpdateResponse.message);

      user_name.$ = name;
      user_phone.$ = phone;
      setState(() {});
    }
  }

  onPressUpdatePassword() async {
    var password = _passwordController.text.toString();
    var passwordConfirm = _passwordConfirmController.text.toString();

    var changePassword = password != "" || passwordConfirm != "";

    if (!changePassword && password == "") {
      ToastComponent.showDialog(AppLocalizations.of(context)!.enter_password);
      return;
    }
    if (!changePassword && passwordConfirm == "") {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.confirm_your_password,
      );
      return;
    }
    if (changePassword && password.length < 6) {
      ToastComponent.showDialog(
        AppLocalizations.of(
          context,
        )!.password_must_contain_at_least_6_characters,
      );
      return;
    }
    if (changePassword && password != passwordConfirm) {
      ToastComponent.showDialog(
        AppLocalizations.of(context)!.passwords_do_not_match,
      );
      return;
    }

    var postBody = jsonEncode({"password": password});

    var profileUpdateResponse = await ProfileRepository()
        .getProfileUpdateResponse(postBody: postBody);

    if (profileUpdateResponse.result == false) {
      ToastComponent.showDialog(profileUpdateResponse.message);
    } else {
      ToastComponent.showDialog(profileUpdateResponse.message);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.mainColor,
        appBar: buildAppBar(context),
        body: buildBody(context),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.mainColor,
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.edit_profile_ucf,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xff3E4447),
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  buildBody(context) {
    if (is_logged_in.$ == false) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.please_log_in_to_see_the_profile,
            style: TextStyle(color: MyTheme.font_grey),
          ),
        ),
      );
    } else {
      return RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        displacement: 10,
        child: CustomScrollView(
          controller: _mainScrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                buildTopSection(),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0)),
                buildProfileForm(context),
              ]),
            ),
          ],
        ),
      );
    }
  }

  buildTopSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 0.0, bottom: 8.0),
          child: Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  boxShadow: [MyTheme.commonShadow()],
                  borderRadius: BorderRadius.circular(100),
                ),
                child: ClipRRect(
                  clipBehavior: Clip.hardEdge,
                  borderRadius: const BorderRadius.all(Radius.circular(100.0)),
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/placeholder.png',
                    image: "${avatar_original.$}",
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              Positioned(
                right: 2,
                bottom: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    boxShadow: [MyTheme.commonShadow()],
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Btn.basic(
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      chooseAndUploadImage(context);
                    },
                    shape: const CircleBorder(),
                    color: const Color(0xffDBDFE2),
                    child: const Icon(
                      Icons.edit,
                      color: Color(0xff3E4447),
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  buildProfileForm(context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        bottom: 8.0,
        left: 16.0,
        right: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [buildBasicInfo(context), buildChangePassword(context)],
      ),
    );
  }

  Column buildChangePassword(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 22.0, bottom: 10),
          child: Center(
            child: Text(
              LangText(context).local.password_changes_ucf,
              style: const TextStyle(
                fontFamily: 'Public Sans',
                fontSize: 16,
                color: MyTheme.accent_color,
                fontWeight: FontWeight.bold,
              ),
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
              ),
              textAlign: TextAlign.center,
              softWrap: false,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            AppLocalizations.of(context)!.new_password_ucf,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff3E4447),
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecorations.buildBoxDecorationWithShadow(),
                height: 40,
                child: TextField(
                  style: const TextStyle(fontSize: 12),
                  controller: _passwordController,
                  autofocus: false,
                  obscureText: !_showPassword,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration:
                      InputDecorations.buildInputDecoration_1(
                        hintText: "• • • • • • • •",
                      ).copyWith(
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: MyTheme.accent_color),
                        ),
                        suffixIcon: InkWell(
                          onTap: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                          child: Icon(
                            _showPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: MyTheme.accent_color,
                          ),
                        ),
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  AppLocalizations.of(
                    context,
                  )!.password_must_contain_at_least_6_characters,
                  style: const TextStyle(
                    color: Color(0xffE62E04),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            AppLocalizations.of(context)!.retype_password_ucf,
            style: TextStyle(
              fontSize: 12,
              color: MyTheme.dark_font_grey,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
            decoration: BoxDecorations.buildBoxDecorationWithShadow(),
            height: 40,
            child: TextField(
              controller: _passwordConfirmController,
              autofocus: false,
              obscureText: !_showConfirmPassword,
              enableSuggestions: false,
              autocorrect: false,
              decoration:
                  InputDecorations.buildInputDecoration_1(
                    hintText: "• • • • • • • •",
                  ).copyWith(
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: MyTheme.accent_color),
                    ),
                    suffixIcon: InkWell(
                      onTap: () {
                        setState(() {
                          _showConfirmPassword = !_showConfirmPassword;
                        });
                      },
                      child: Icon(
                        _showConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: MyTheme.accent_color,
                      ),
                    ),
                  ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              onPressUpdatePassword();
            },
            child: Container(
              alignment: Alignment.center,
              width: 129,
              height: 42,
              decoration: BoxDecoration(
                color: MyTheme.accent_color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Save Changes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Column buildBasicInfo(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 13.0),
          child: Text(
            AppLocalizations.of(context)!.basic_information_ucf,
            style: const TextStyle(
              color: Color(0xff6B7377),
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            AppLocalizations.of(context)!.name_ucf,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff3E4447),
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [MyTheme.commonShadow()],
            ),
            height: 40,
            child: TextField(
              controller: _nameController,
              autofocus: false,
              style: const TextStyle(color: Color(0xff999999), fontSize: 12),
              decoration:
                  InputDecorations.buildInputDecoration_1(
                    hintText: "John Doe",
                  ).copyWith(
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: MyTheme.accent_color),
                    ),
                  ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            AppLocalizations.of(context)!.phone_ucf,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff3E4447),
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [MyTheme.commonShadow()],
            ),
            height: 40,
            child: TextField(
              controller: _phoneController,
              autofocus: false,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Color(0xff999999), fontSize: 12),
              decoration:
                  InputDecorations.buildInputDecoration_1(
                    hintText: "+01xxxxxxxxxx",
                  ).copyWith(
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: MyTheme.accent_color),
                    ),
                  ),
            ),
          ),
        ),
        Visibility(
          visible: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  AppLocalizations.of(context)!.email_ucf,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff3E4447),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [MyTheme.commonShadow()],
                  ),
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _emailController.text,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff999999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              onPressUpdate();
            },
            child: Container(
              alignment: Alignment.center,
              width: 129,
              height: 42,
              decoration: BoxDecoration(
                color: MyTheme.accent_color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Update Profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
