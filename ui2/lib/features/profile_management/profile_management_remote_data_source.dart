import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';
import 'package:flutterquiz/core/constants/constants.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:http/http.dart' as http;

final class ProfileManagementRemoteDataSource {
  Future<Map<String, dynamic>> getUserDetailsById() async {
    try {
      final response = await http.post(
        Uri.parse(getUserDetailsByIdUrl),
        headers: await ApiUtils.getHeaders(),
      );

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        throw ApiException(responseJson['message'].toString());
      }
      return responseJson['data'] as Map<String, dynamic>;
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  Future<Map<String, dynamic>> addProfileImage(File? images) async {
    try {
      final fileList = <String, File?>{imageKey: images};
      final response = await postApiFile(Uri.parse(uploadProfileUrl), fileList);
      final res = json.decode(response) as Map<String, dynamic>;
      if (res['error'] as bool) {
        throw ApiException(res['message'].toString());
      }

      return res['data'] as Map<String, dynamic>;
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  Future<String> postApiFile(Uri url, Map<String, File?> fileList) async {
    try {
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(await ApiUtils.getHeaders());

      for (final key in fileList.keys.toList()) {
        final pic = await http.MultipartFile.fromPath(key, fileList[key]!.path);
        request.files.add(pic);
      }
      final res = await request.send();
      final responseData = await res.stream.toBytes();
      final response = String.fromCharCodes(responseData);
      if (res.statusCode == 200) {
        return response;
      } else {
        throw const ApiException(errorCodeDefaultMessage);
      }
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  Future<Map<String, dynamic>> updateCoins({
    required String coins,
    required String title,
    String? type, //dashing_debut, clash_winner
  }) async {
    try {
      final body = <String, String>{
        coinsKey: coins,
        titleKey: title,
        typeKey: type ?? '',
      };
      if (body[typeKey]!.isEmpty) {
        body.remove(typeKey);
      }

      final response = await http.post(
        Uri.parse(updateUserCoinsAndScoreUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        throw ApiException(responseJson['message'].toString());
      }
      return responseJson['data'] as Map<String, dynamic>;
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  Future<void> removeAdsForUser({required bool status}) async {
    try {
      final body = <String, String>{removeAdsKey: status ? '1' : '0'};

      final rawRes = await http.post(
        Uri.parse(updateProfileUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final resJson = jsonDecode(rawRes.body) as Map<String, dynamic>;
      if (resJson['error'] as bool) {
        throw ApiException(resJson['message'].toString());
      }
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  Future<void> updateLanguage(String languageName) async {
    try {
      final body = {'app_language': languageName};

      var token = <String, String>{};

      try {
        token = await ApiUtils.getHeaders();
      } on Exception catch (_) {}

      if (token.isEmpty) {
        return;
      }

      final rawRes = await http.post(
        Uri.parse(updateProfileUrl),
        body: body,
        headers: token,
      );

      final resJson = jsonDecode(rawRes.body) as Map<String, dynamic>;
      if (resJson['error'] as bool) {
        throw ApiException(resJson['message'].toString());
      }
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  Future<void> updateProfile({
    required String email,
    required String name,
    required String mobile,
  }) async {
    try {
      final body = <String, String>{
        emailKey: email,
        nameKey: name,
        mobileKey: mobile,
      };

      final response = await http.post(
        Uri.parse(updateProfileUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
      if (responseJson['error'] as bool) {
        throw ApiException(responseJson['message'].toString());
      }
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      await FirebaseAuth.instance.currentUser?.delete();

      final response = await http.post(
        Uri.parse(deleteUserAccountUrl),
        headers: await ApiUtils.getHeaders(),
      );

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        throw ApiException(responseJson['message'].toString());
      }
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on FirebaseAuthException catch (e) {
      throw ApiException(firebaseErrorCodeToNumber(e.code));
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  Future<bool> watchedDailyAd() async {
    try {
      final rawRes = await http.post(
        Uri.parse(watchedDailyAdUrl),
        headers: await ApiUtils.getHeaders(),
      );

      final jsonRes = jsonDecode(rawRes.body) as Map<String, dynamic>;

      if (jsonRes['error'] as bool) {
        throw ApiException(jsonRes['message'].toString());
      }

      return jsonRes['message'] == errorCodeDataUpdateSuccess;
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on FirebaseAuthException catch (e) {
      throw ApiException(firebaseErrorCodeToNumber(e.code));
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }
}
