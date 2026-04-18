import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/core/constants/constants.dart';
import 'package:flutterquiz/features/battle_room/battle_room_repository.dart';
import 'package:flutterquiz/features/battle_room/models/battle_room.dart';
import 'package:flutterquiz/features/quiz/models/question.dart';
import 'package:flutterquiz/features/quiz/models/user_battle_room_details.dart';
import 'package:flutterquiz/features/system_config/model/room_code_char_type.dart';

sealed class MultiUserBattleRoomState {
  const MultiUserBattleRoomState();
}

final class MultiUserBattleRoomInitial extends MultiUserBattleRoomState {
  const MultiUserBattleRoomInitial();
}

final class MultiUserBattleRoomInProgress extends MultiUserBattleRoomState {
  const MultiUserBattleRoomInProgress();
}

final class MultiUserBattleRoomSuccess extends MultiUserBattleRoomState {
  const MultiUserBattleRoomSuccess({
    required this.battleRoom,
    required this.isRoomExist,
    required this.questions,
  });

  final BattleRoom battleRoom;
  final bool isRoomExist;
  final List<Question> questions;
}

final class MultiUserBattleRoomFailure extends MultiUserBattleRoomState {
  const MultiUserBattleRoomFailure(this.errorMessageCode);

  final String errorMessageCode;
}

/// Manages group battle rooms with up to 4 players.
///
/// Handles:
/// - Creating group battle rooms with room codes
/// - Joining existing group battles via room code
/// - Real-time room state synchronization for all players
/// - Question management and answer submission for multiple users
/// - Player tracking and removal (up to 4 players)
final class MultiUserBattleRoomCubit extends Cubit<MultiUserBattleRoomState> {
  MultiUserBattleRoomCubit(this._battleRoomRepository)
    : super(const MultiUserBattleRoomInitial());

  final BattleRoomRepository _battleRoomRepository;
  StreamSubscription<DocumentSnapshot>? _battleRoomStreamSubscription;
  final _rnd = Random.secure();

  void reset({bool cancelSubscription = true}) {
    if (cancelSubscription) {
      _battleRoomStreamSubscription?.cancel();
    }
    emit(const MultiUserBattleRoomInitial());
  }

  /// Subscribes to real-time group battle room updates.
  ///
  /// Monitors all player actions, room deletion by owner, and game state changes.
  void subscribeToMultiUserBattleRoom(
    String battleRoomDocumentId,
    List<Question> questions,
  ) {
    _battleRoomStreamSubscription = _battleRoomRepository
        .subscribeToBattleRoom(battleRoomDocumentId, forMultiUser: true)
        .listen(
          (event) {
            if (event.exists) {
              emit(
                MultiUserBattleRoomSuccess(
                  battleRoom: BattleRoom.fromDocumentSnapshot(event),
                  isRoomExist: true,
                  questions: questions,
                ),
              );
            } else {
              // Room was deleted by owner
              emit(
                MultiUserBattleRoomSuccess(
                  battleRoom: (state as MultiUserBattleRoomSuccess).battleRoom,
                  isRoomExist: false,
                  questions: (state as MultiUserBattleRoomSuccess).questions,
                ),
              );
            }
          },
          onError: (e) {
            emit(const MultiUserBattleRoomFailure(errorCodeDefaultMessage));
          },
          cancelOnError: true,
        );
  }

  /// Creates a new group battle room for up to 4 players.
  ///
  /// Generates a 6-character room code for friends to join.
  /// The room creator becomes user1 and can start the game once ready.
  Future<void> createRoom({
    required String categoryId,
    required String categoryName,
    required String categoryImage,
    required RoomCodeCharType charType,
    String? name,
    String? profileUrl,
    String? uid,
    String? roomType,
    int? entryFee,
    String? questionLanguageId,
  }) async {
    emit(const MultiUserBattleRoomInProgress());
    try {
      final roomCode = generateRoomCode(charType, 6);

      final documentSnapshot = await _battleRoomRepository
          .createMultiUserBattleRoom(
            categoryId: categoryId,
            categoryName: categoryName,
            categoryImage: categoryImage,
            name: name,
            profileUrl: profileUrl,
            uid: uid,
            roomCode: roomCode,
            roomType: 'public',
            entryFee: entryFee,
            questionLanguageId: questionLanguageId,
          );

      final questions = await _battleRoomRepository.getQuestions(
        categoryId: '',
        forMultiUser: true,
        matchId: roomCode,
        roomDocumentId: documentSnapshot.id,
        roomCreator: true,
        languageId: questionLanguageId!,
        entryCoin: entryFee,
      );

      subscribeToMultiUserBattleRoom(documentSnapshot.id, questions);
    } on Exception catch (e) {
      emit(MultiUserBattleRoomFailure(e.toString()));
    }
  }

  /// Joins an existing group battle room using a room code.
  ///
  /// Players are assigned to the first available slot (user2, user3, or user4).
  Future<void> joinRoom({
    required String currentCoin,
    String? name,
    String? profileUrl,
    String? uid,
    String? roomCode,
  }) async {
    emit(const MultiUserBattleRoomInProgress());
    try {
      final (:roomId, :questions) = await _battleRoomRepository
          .joinMultiUserBattleRoom(
            name: name,
            profileUrl: profileUrl,
            roomCode: roomCode,
            uid: uid,
            currentCoin: int.parse(currentCoin),
          );

      subscribeToMultiUserBattleRoom(roomId, questions);
    } on Exception catch (e) {
      emit(MultiUserBattleRoomFailure(e.toString()));
    }
  }

  /// Updates local question state with user's submitted answer.
  ///
  /// This is for local UI state only. The actual answer submission to
  /// Firebase happens in [submitAnswer].
  void updateQuestionAnswer(String questionId, String submittedAnswerId) {
    if (state is MultiUserBattleRoomSuccess) {
      final updatedQuestions = (state as MultiUserBattleRoomSuccess).questions;
      final questionIndex = updatedQuestions.indexWhere(
        (element) => element.id == questionId,
      );

      updatedQuestions[questionIndex] = updatedQuestions[questionIndex]
          .updateQuestionWithAnswer(submittedAnswerId: submittedAnswerId);

      emit(
        MultiUserBattleRoomSuccess(
          isRoomExist: (state as MultiUserBattleRoomSuccess).isRoomExist,
          battleRoom: (state as MultiUserBattleRoomSuccess).battleRoom,
          questions: updatedQuestions,
        ),
      );
    }
  }

  /// Deletes the entire battle room (called when room owner quits or game ends).
  void deleteMultiUserBattleRoom() {
    if (state is MultiUserBattleRoomSuccess) {
      _battleRoomRepository.deleteBattleRoom(
        (state as MultiUserBattleRoomSuccess).battleRoom.roomId,
        isGroupBattle: true,
        roomCode: (state as MultiUserBattleRoomSuccess).battleRoom.roomCode,
      );
    }
  }

  /// Removes a specific user from the room when they leave mid-game.
  ///
  /// Identifies the user's slot (1-4) and removes them from that position.
  void deleteUserFromRoom(String userId) {
    if (state is MultiUserBattleRoomSuccess) {
      final battleRoom = (state as MultiUserBattleRoomSuccess).battleRoom;

      if (userId == battleRoom.user1!.uid) {
        _battleRoomRepository.deleteUserFromMultiUserRoom(1, battleRoom);
      } else if (userId == battleRoom.user2!.uid) {
        _battleRoomRepository.deleteUserFromMultiUserRoom(2, battleRoom);
      } else if (userId == battleRoom.user3!.uid) {
        _battleRoomRepository.deleteUserFromMultiUserRoom(3, battleRoom);
      } else {
        _battleRoomRepository.deleteUserFromMultiUserRoom(4, battleRoom);
      }
    }
  }

  /// Starts the quiz game (only room creator/user1 can call this).
  void startGame() {
    if (state is MultiUserBattleRoomSuccess) {
      _battleRoomRepository.startMultiUserQuiz(
        (state as MultiUserBattleRoomSuccess).battleRoom.roomId,
        isMultiUserRoom: true,
      );
    }
  }

  /// Submits answer to Firebase and updates user's score in real-time.
  ///
  /// Identifies which user slot (1-4) the current user occupies and
  /// submits their answer to that position. Prevents duplicate submissions.
  void submitAnswer(
    String currentUserId,
    String submittedAnswer, {
    required String questionId,
    required bool isCorrectAnswer,
  }) {
    if (state is MultiUserBattleRoomSuccess) {
      final battleRoom = (state as MultiUserBattleRoomSuccess).battleRoom;
      final questions = (state as MultiUserBattleRoomSuccess).questions;

      // Identify which user slot the current user occupies
      late final String userNo;
      late final UserBattleRoomDetails user;

      if (currentUserId == battleRoom.user1!.uid) {
        userNo = '1';
        user = battleRoom.user1!;
      } else if (currentUserId == battleRoom.user2!.uid) {
        userNo = '2';
        user = battleRoom.user2!;
      } else if (currentUserId == battleRoom.user3!.uid) {
        userNo = '3';
        user = battleRoom.user3!;
      } else {
        userNo = '4';
        user = battleRoom.user4!;
      }

      // Prevent duplicate submissions after all questions are answered
      if (user.answers.length != questions.length) {
        _battleRoomRepository.submitAnswerForMultiUserBattleRoom(
          battleRoomDocumentId: battleRoom.roomId,
          correctAnswers: isCorrectAnswer
              ? (user.correctAnswers + 1)
              : user.correctAnswers,
          userNumber: userNo,
          submittedAnswer: List.from(user.answers)
            ..add({'answer': submittedAnswer, 'id': questionId}),
        );
      }
    }
  }

  List<Question> getQuestions() {
    if (state is MultiUserBattleRoomSuccess) {
      return (state as MultiUserBattleRoomSuccess).questions;
    }
    return [];
  }

  BattleRoom? get battleRoom {
    if (state is MultiUserBattleRoomSuccess) {
      return (state as MultiUserBattleRoomSuccess).battleRoom;
    }
    return null;
  }

  String getRoomCode() {
    if (state is MultiUserBattleRoomSuccess) {
      return (state as MultiUserBattleRoomSuccess).battleRoom.roomCode!;
    }
    return '';
  }

  String getRoomId() {
    if (state is MultiUserBattleRoomSuccess) {
      return (state as MultiUserBattleRoomSuccess).battleRoom.roomId!;
    }
    return '';
  }

  int getEntryFee() {
    if (state is MultiUserBattleRoomSuccess) {
      return (state as MultiUserBattleRoomSuccess).battleRoom.entryFee!;
    }
    return 0;
  }

  String get categoryName => state is MultiUserBattleRoomSuccess
      ? (state as MultiUserBattleRoomSuccess).battleRoom.categoryName!
      : '';

  String get categoryImage => state is MultiUserBattleRoomSuccess
      ? (state as MultiUserBattleRoomSuccess).battleRoom.categoryImage!
      : '';

  /// Returns all active users in the room (filters out empty slots).
  List<UserBattleRoomDetails?> getUsers() {
    if (state is MultiUserBattleRoomSuccess) {
      final users = <UserBattleRoomDetails?>[];
      final battleRoom = (state as MultiUserBattleRoomSuccess).battleRoom;

      if (battleRoom.user1!.uid.isNotEmpty) {
        users.add(battleRoom.user1);
      }
      if (battleRoom.user2!.uid.isNotEmpty) {
        users.add(battleRoom.user2);
      }
      if (battleRoom.user3!.uid.isNotEmpty) {
        users.add(battleRoom.user3);
      }
      if (battleRoom.user4!.uid.isNotEmpty) {
        users.add(battleRoom.user4);
      }

      return users;
    }
    return [];
  }

  /// Returns true if the current user is the only one remaining in the room.
  bool isCurrentUserAloneInRoom(String currentUserId) {
    final activeUsers = getUsers();
    return activeUsers.length == 1 && activeUsers.single!.uid == currentUserId;
  }

  /// Gets details of a specific user by their user ID.
  UserBattleRoomDetails? getUser(String userId) {
    final users = getUsers();
    return users[users.indexWhere((element) => element!.uid == userId)];
  }

  /// Returns all opponent users (excludes the current user).
  List<UserBattleRoomDetails?> getOpponentUsers(String userId) {
    return getUsers()..removeWhere((e) => e!.uid == userId);
  }

  /// Generates a random room code for group battles.
  String generateRoomCode(RoomCodeCharType charType, int length) =>
      String.fromCharCodes(
        Iterable.generate(
          length,
          (_) => charType.value.codeUnitAt(_rnd.nextInt(charType.value.length)),
        ),
      );

  @override
  Future<void> close() async {
    await _battleRoomStreamSubscription?.cancel();
    return super.close();
  }
}
