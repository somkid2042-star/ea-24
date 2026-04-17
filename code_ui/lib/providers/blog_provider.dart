import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/blog_mode.dart'; // ধরে নিচ্ছি BlogModel
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BlogProvider with ChangeNotifier {
  List<BlogModel> _blogs = [];
  bool _isInitialLoading = true;

  List<BlogModel> get blogs => _blogs;
  bool get isInitialLoading => _isInitialLoading;
  Future<void> fetchBlogs() async {
    _isInitialLoading = true;
    notifyListeners();

    final url = "${AppConfig.BASE_URL}/blog-list";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "System-Key": AppConfig.system_key,
        },
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        final List<BlogModel> loadedBlogs = [];
        for (var blogData in jsonData['blogs']['data']) {
          loadedBlogs.add(BlogModel.fromJson(blogData));
        }
        _blogs = loadedBlogs;
      } else {
        _blogs = [];
      }
    } catch (e) {
      _blogs = [];
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }
  void resetAndFetch() {
    _blogs = [];
    _isInitialLoading = true;
    notifyListeners();
    fetchBlogs();
  }
}