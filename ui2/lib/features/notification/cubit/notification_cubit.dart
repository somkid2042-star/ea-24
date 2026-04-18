import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/core/constants/api_body_parameter_labels.dart';
import 'package:flutterquiz/core/constants/api_endpoints_constants.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';
import 'package:flutterquiz/core/constants/error_message_keys.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:http/http.dart' as http;

sealed class NotificationState {
  const NotificationState();
}

final class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

final class NotificationProgress extends NotificationState {
  const NotificationProgress();
}

final class NotificationSuccess extends NotificationState {
  const NotificationSuccess(
    this.notifications,
    this.totalData, {
    required this.hasMore,
  });

  final List<Map<String, dynamic>> notifications;
  final int totalData;
  final bool hasMore;
}

final class NotificationFailure extends NotificationState {
  const NotificationFailure(this.errorMessageCode);

  final String errorMessageCode;
}

final class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit() : super(const NotificationInitial());

  Future<({List<Map<String, dynamic>> data, int total})> _fetchData({
    String limit = '20',
    String offset = '',
  }) async {
    try {
      final body = <String, String>{limitKey: limit, offsetKey: offset};

      if (offset.isEmpty) body.remove(offset);

      final response = await http.post(
        Uri.parse(getNotificationUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        throw ApiException(responseJson['message'].toString());
      }

      return (
        total: int.parse(responseJson['total'] as String? ?? '0'),
        data: (responseJson['data'] as List).cast<Map<String, dynamic>>(),
      );
    } on SocketException catch (_) {
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  void fetchNotifications({String limit = '20'}) {
    emit(const NotificationProgress());

    _fetchData(limit: limit)
        .then((v) {
          emit(
            NotificationSuccess(
              v.data,
              v.total,
              hasMore: v.total > v.data.length,
            ),
          );
        })
        .catchError((Object e) {
          emit(NotificationFailure(e.toString()));
        });
  }

  void fetchMoreNotifications({String limit = '20'}) {
    _fetchData(
          limit: limit,
          offset: (state as NotificationSuccess).notifications.length
              .toString(),
        )
        .then((value) {
          final oldState = state as NotificationSuccess;
          final updatedUserDetails = oldState.notifications..addAll(value.data);

          emit(
            NotificationSuccess(
              updatedUserDetails,
              oldState.totalData,
              hasMore: oldState.totalData > updatedUserDetails.length,
            ),
          );
        })
        .catchError((Object e) {
          emit(NotificationFailure(e.toString()));
        });
  }

  bool get hasMore =>
      state is NotificationSuccess && (state as NotificationSuccess).hasMore;
}
