import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';
import 'package:flutterquiz/core/constants/constants.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:http/http.dart' as http;

sealed class LeaderBoardAllTimeState {
  const LeaderBoardAllTimeState();
}

final class LeaderBoardAllTimeInitial extends LeaderBoardAllTimeState {
  const LeaderBoardAllTimeInitial();
}

final class LeaderBoardAllTimeProgress extends LeaderBoardAllTimeState {
  const LeaderBoardAllTimeProgress();
}

final class LeaderBoardAllTimeSuccess extends LeaderBoardAllTimeState {
  const LeaderBoardAllTimeSuccess(
    this.leaderBoardDetails,
    this.totalData, {
    required this.hasMore,
  });

  final List<Map<String, dynamic>> leaderBoardDetails;
  final int totalData;
  final bool hasMore;
}

final class LeaderBoardAllTimeFailure extends LeaderBoardAllTimeState {
  const LeaderBoardAllTimeFailure(this.errorMessage);

  final String errorMessage;
}

final class LeaderBoardAllTimeCubit extends Cubit<LeaderBoardAllTimeState> {
  LeaderBoardAllTimeCubit() : super(const LeaderBoardAllTimeInitial());

  static late String profileA;
  static late String nameA;
  static late String scoreA;
  static late String rankA;

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
        Uri.parse(getAllTimeLeaderboardUrl),
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

        nameA = myRank['name'].toString();
        rankA = myRank['user_rank'].toString();
        profileA = myRank['profile'].toString();
        scoreA = myRank['score'].toString();
      } else {
        nameA = '';
        rankA = '';
        profileA = '';
        scoreA = '0';
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
    emit(const LeaderBoardAllTimeProgress());
    _fetchData(limit: limit)
        .then((v) {
          emit(
            LeaderBoardAllTimeSuccess(
              v.otherUsersRanks,
              v.total,
              hasMore: v.total > v.otherUsersRanks.length,
            ),
          );
        })
        .catchError((dynamic e) {
          emit(LeaderBoardAllTimeFailure(e.toString()));
        });
  }

  void fetchMoreLeaderBoardData(String limit) {
    _fetchData(
          limit: limit,
          offset: (state as LeaderBoardAllTimeSuccess).leaderBoardDetails.length
              .toString(),
        )
        .then((v) {
          final oldState = state as LeaderBoardAllTimeSuccess;

          final updatedUserDetails = oldState.leaderBoardDetails
            ..addAll(v.otherUsersRanks);

          emit(
            LeaderBoardAllTimeSuccess(
              updatedUserDetails,
              oldState.totalData,
              hasMore: oldState.totalData > updatedUserDetails.length,
            ),
          );
        })
        .catchError((e) {
          emit(const LeaderBoardAllTimeFailure(errorCodeDefaultMessage));
        });
  }

  bool hasMoreData() =>
      state is LeaderBoardAllTimeSuccess &&
      (state as LeaderBoardAllTimeSuccess).hasMore;
}
