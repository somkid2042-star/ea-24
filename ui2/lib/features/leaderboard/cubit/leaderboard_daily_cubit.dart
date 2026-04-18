import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';
import 'package:flutterquiz/core/constants/constants.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:http/http.dart' as http;

sealed class LeaderBoardDailyState {
  const LeaderBoardDailyState();
}

final class LeaderBoardDailyInitial extends LeaderBoardDailyState {
  const LeaderBoardDailyInitial();
}

final class LeaderBoardDailyProgress extends LeaderBoardDailyState {
  const LeaderBoardDailyProgress();
}

final class LeaderBoardDailySuccess extends LeaderBoardDailyState {
  const LeaderBoardDailySuccess(
    this.leaderBoardDetails,
    this.totalData, {
    required this.hasMore,
  });

  final List<Map<String, dynamic>> leaderBoardDetails;
  final int totalData;
  final bool hasMore;
}

final class LeaderBoardDailyFailure extends LeaderBoardDailyState {
  const LeaderBoardDailyFailure(this.errorMessage);

  final String errorMessage;
}

final class LeaderBoardDailyCubit extends Cubit<LeaderBoardDailyState> {
  LeaderBoardDailyCubit() : super(const LeaderBoardDailyInitial());

  static late String profileD;
  static late String nameD;
  static late String scoreD;
  static late String rankD;

  Future<({int total, List<Map<String, dynamic>> otherUsersRanks})> _fetchData({
    required String limit,
    String? offset,
  }) async {
    try {
      final body = <String, String>{limitKey: limit, offsetKey: offset ?? ''};

      if (offset == null) body.remove(offset);

      final response = await http.post(
        Uri.parse(getDailyLeaderboardUrl),
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

        nameD = myRank['name'].toString();
        rankD = myRank['user_rank'].toString();
        profileD = myRank[profileKey].toString();
        scoreD = myRank['score'].toString();
      } else {
        nameD = '';
        rankD = '';
        profileD = '';
        scoreD = '0';
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
    emit(const LeaderBoardDailyProgress());
    _fetchData(limit: limit)
        .then((v) {
          emit(
            LeaderBoardDailySuccess(
              v.otherUsersRanks,
              v.total,
              hasMore: v.total > v.otherUsersRanks.length,
            ),
          );
        })
        .catchError((dynamic e) {
          emit(LeaderBoardDailyFailure(e.toString()));
        });
  }

  void fetchMoreLeaderBoardData(String limit) {
    _fetchData(
          limit: limit,
          offset: (state as LeaderBoardDailySuccess).leaderBoardDetails.length
              .toString(),
        )
        .then((v) {
          final oldState = state as LeaderBoardDailySuccess;
          final updatedUserDetails = oldState.leaderBoardDetails
            ..addAll(v.otherUsersRanks);

          emit(
            LeaderBoardDailySuccess(
              updatedUserDetails,
              oldState.totalData,
              hasMore: oldState.totalData > updatedUserDetails.length,
            ),
          );
        })
        .catchError((dynamic e) {
          emit(LeaderBoardDailyFailure(e.toString()));
        });
  }

  bool hasMoreData() =>
      state is LeaderBoardDailySuccess &&
      (state as LeaderBoardDailySuccess).hasMore;
}
