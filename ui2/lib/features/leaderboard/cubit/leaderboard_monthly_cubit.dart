import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';
import 'package:flutterquiz/core/constants/constants.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:http/http.dart' as http;

sealed class LeaderBoardMonthlyState {
  const LeaderBoardMonthlyState();
}

final class LeaderBoardMonthlyInitial extends LeaderBoardMonthlyState {
  const LeaderBoardMonthlyInitial();
}

final class LeaderBoardMonthlyProgress extends LeaderBoardMonthlyState {
  const LeaderBoardMonthlyProgress();
}

final class LeaderBoardMonthlySuccess extends LeaderBoardMonthlyState {
  const LeaderBoardMonthlySuccess(
    this.leaderBoardDetails,
    this.totalData, {
    required this.hasMore,
  });

  final List<Map<String, dynamic>> leaderBoardDetails;
  final int totalData;
  final bool hasMore;
}

final class LeaderBoardMonthlyFailure extends LeaderBoardMonthlyState {
  const LeaderBoardMonthlyFailure(this.errorMessage);

  final String errorMessage;
}

final class LeaderBoardMonthlyCubit extends Cubit<LeaderBoardMonthlyState> {
  LeaderBoardMonthlyCubit() : super(const LeaderBoardMonthlyInitial());

  static late String profileM;
  static late String nameM;
  static late String scoreM;
  static late String rankM;

  Future<({int total, List<Map<String, dynamic>> otherUsersRanks})> _fetchData({
    required String limit,
    String? offset,
  }) async {
    try {
      final body = <String, String>{limitKey: limit, offsetKey: offset ?? ''};
      if (offset == null) {
        body.remove(offset);
      }
      final response = await http.post(
        Uri.parse(getMonthlyLeaderboardUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        throw ApiException(responseJson['message'].toString());
      }

      final total = int.parse(responseJson['total'] as String? ?? '0');
      final data = responseJson['data'] as Map<String, dynamic>;

      if (total != 0) {
        final myRank = data['my_rank'] as Map<String, dynamic>;

        nameM = myRank[nameKey].toString();
        rankM = myRank[userRankKey].toString();
        profileM = myRank[profileKey].toString();
        scoreM = myRank[scoreKey].toString();
      } else {
        nameM = '';
        rankM = '';
        profileM = '';
        scoreM = '0';
      }

      return (
        total: total,
        otherUsersRanks: (data['other_users_rank'] as List)
            .cast<Map<String, dynamic>>(),
      );
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  void fetchLeaderBoard(String limit) {
    emit(const LeaderBoardMonthlyProgress());
    _fetchData(limit: limit)
        .then((v) {
          emit(
            LeaderBoardMonthlySuccess(
              v.otherUsersRanks,
              v.total,
              hasMore: v.total > v.otherUsersRanks.length,
            ),
          );
        })
        .catchError((dynamic e) {
          emit(LeaderBoardMonthlyFailure(e.toString()));
        });
  }

  void fetchMoreLeaderBoardData(String limit) {
    _fetchData(
          limit: limit,
          offset: (state as LeaderBoardMonthlySuccess).leaderBoardDetails.length
              .toString(),
        )
        .then((v) {
          final oldState = state as LeaderBoardMonthlySuccess;

          final updatedUserDetails = oldState.leaderBoardDetails
            ..addAll(v.otherUsersRanks);

          emit(
            LeaderBoardMonthlySuccess(
              updatedUserDetails,
              oldState.totalData,
              hasMore: oldState.totalData > updatedUserDetails.length,
            ),
          );
        })
        .catchError((dynamic e) {
          emit(LeaderBoardMonthlyFailure(e.toString()));
        });
  }

  //
  // ignore: avoid_bool_literals_in_conditional_expressions
  bool hasMoreData() => state is LeaderBoardMonthlySuccess
      ? (state as LeaderBoardMonthlySuccess).hasMore
      : false;
}
