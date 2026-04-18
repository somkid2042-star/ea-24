import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutterquiz/core/constants/api_exception.dart';
import 'package:flutterquiz/core/constants/constants.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:http/http.dart' as http;

final class BookmarkRemoteDataSource {
  Future<List<Map<String, dynamic>>> getBookmark(String type) async {
    try {
      //type is 1 - Quiz zone 3- Guess the word 4 - Audio question
      final body = <String, String>{typeKey: type};

      final response = await http.post(
        Uri.parse(getBookmarkUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      log(name: 'Bookmarks', responseJson.toString());

      if (responseJson['error'] as bool) {
        throw ApiException(responseJson['message'].toString());
      }

      return (responseJson['data'] as List).cast<Map<String, dynamic>>();
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  Future<void> updateBookmark(
    String questionId,
    String status,
    String type,
  ) async {
    try {
      final body = {
        statusKey: status,
        questionIdKey: questionId,
        typeKey: type, //1 - Quiz zone 3 - Guess the word 4 - Audio questions
      };
      final response = await http.post(
        Uri.parse(updateBookmarkUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      log(name: 'Update Bookmark', responseJson.toString());

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
}
