import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/core/constants/constants.dart';
import 'package:flutterquiz/core/routes/routes.dart';
import 'package:flutterquiz/features/battle_room/battle_room_repository.dart';
import 'package:flutterquiz/features/battle_room/models/battle_room.dart';
import 'package:flutterquiz/features/quiz/models/question.dart';
import 'package:flutterquiz/features/quiz/models/user_battle_room_details.dart';
import 'package:flutterquiz/features/system_config/model/room_code_char_type.dart';

sealed class BattleRoomState {
  const BattleRoomState();
}

final class BattleRoomInitial extends BattleRoomState {
  const BattleRoomInitial();
}

final class BattleRoomSearchInProgress extends BattleRoomState {
  const BattleRoomSearchInProgress();
}

final class BattleRoomDeleted extends BattleRoomState {
  const BattleRoomDeleted();
}

final class BattleRoomJoining extends BattleRoomState {
  const BattleRoomJoining();
}

final class BattleRoomCreating extends BattleRoomState {
  const BattleRoomCreating();
}

final class BattleRoomCreated extends BattleRoomState {
  const BattleRoomCreated(this.battleRoom);

  final BattleRoom battleRoom;
}

final class BattleRoomUserFound extends BattleRoomState {
  const BattleRoomUserFound({
    required this.battleRoom,
    required this.hasLeft,
    required this.questions,
    required this.isRoomExist,
  });

  final BattleRoom battleRoom;
  final bool hasLeft;
  final bool isRoomExist;
  final List<Question> questions;
}

final class BattleRoomFailure extends BattleRoomState {
  const BattleRoomFailure(this.errorMessageCode);

  final String errorMessageCode;
}

/// Manages 1v1 battle room lifecycle and real-time synchronization.
///
/// Handles:
/// - Creating rooms (random matchmaking or friend battles with room codes)
/// - Joining rooms (matchmaking or via room code)
/// - Real-time room state synchronization
/// - Question management and answer submission
/// - User presence tracking (joins/leaves)
final class BattleRoomCubit extends Cubit<BattleRoomState> {
  BattleRoomCubit(this._battleRoomRepository)
    : super(const BattleRoomInitial());

  final BattleRoomRepository _battleRoomRepository;
  StreamSubscription<DocumentSnapshot>? _battleRoomStreamSubscription;
  final Random _rnd = Random.secure();

  void updateState(
    BattleRoomState newState, {
    bool cancelSubscription = false,
  }) {
    if (cancelSubscription) {
      _battleRoomStreamSubscription?.cancel();
    }
    emit(newState);
  }

  /// Subscribes to real-time battle room updates.
  ///
  /// Monitors opponent joins/leaves, room deletion, and ready state changes.
  /// Automatically handles cleanup if user navigates away during matchmaking.
  void subscribeToBattleRoom(
    String battleRoomDocumentId,
    List<Question> questions, {
    required bool isGroupBattle,
  }) {
    _battleRoomStreamSubscription = _battleRoomRepository
        .subscribeToBattleRoom(
          battleRoomDocumentId,
          forMultiUser: isGroupBattle,
        )
        .listen(
          (event) {
            if (event.exists) {
              final battleRoom = BattleRoom.fromDocumentSnapshot(event);
              final userNotFound = battleRoom.user2?.uid.isEmpty;

              // ignore: use_if_null_to_convert_nulls_to_bools
              if (userNotFound == true &&
                  (Routes.currentRoute == Routes.battleRoomFindOpponent ||
                      battleRoom.readyToPlay!)) {
                // Opponent left during active battle
                if (state is BattleRoomUserFound) {
                  emit(
                    BattleRoomUserFound(
                      battleRoom: (state as BattleRoomUserFound).battleRoom,
                      hasLeft: true,
                      isRoomExist: true,
                      questions: (state as BattleRoomUserFound).questions,
                    ),
                  );
                  return;
                }

                // Delete abandoned room if user navigated away during matchmaking
                if (Routes.currentRoute != Routes.battleRoomFindOpponent &&
                    battleRoom.roomCode!.isEmpty) {
                  deleteBattleRoom();
                }

                emit(BattleRoomCreated(battleRoom));
              } else {
                // Opponent found or already playing
                emit(
                  BattleRoomUserFound(
                    battleRoom: battleRoom,
                    isRoomExist: true,
                    questions: questions,
                    hasLeft: false,
                  ),
                );
              }
            } else {
              // Room was deleted
              if (state is BattleRoomUserFound) {
                emit(
                  BattleRoomUserFound(
                    battleRoom: (state as BattleRoomUserFound).battleRoom,
                    hasLeft: true,
                    isRoomExist: false,
                    questions: (state as BattleRoomUserFound).questions,
                  ),
                );
              }
            }
          },
          onError: (e) {
            emit(const BattleRoomFailure(errorCodeDefaultMessage));
          },
          cancelOnError: true,
        );
  }

  /// Subscribes to a bot battle room (simpler flow with no opponent waiting).
  void joinBattleRoomWithBot(
    String battleRoomDocumentId,
    List<Question> questions, {
    required bool type,
  }) {
    _battleRoomStreamSubscription = _battleRoomRepository
        .subscribeToBattleRoom(battleRoomDocumentId, forMultiUser: type)
        .listen(
          (event) {
            if (event.exists) {
              final battleRoom = BattleRoom.fromDocumentSnapshot(event);

              emit(
                BattleRoomUserFound(
                  battleRoom: battleRoom,
                  isRoomExist: true,
                  questions: questions,
                  hasLeft: false,
                ),
              );
            }
          },
          onError: (e) =>
              emit(const BattleRoomFailure(errorCodeDefaultMessage)),
          cancelOnError: true,
        );
  }

  /// Searches for an available battle room to join for random matchmaking.
  ///
  /// Flow:
  /// 1. Search for existing rooms matching category and language
  /// 2. If found: Join random room from available options
  /// 3. If not found: Create new room and wait for opponent
  ///
  /// If join fails due to race condition, automatically retries search.
  Future<void> searchRoom({
    required String categoryId,
    required String name,
    required String profileUrl,
    required String uid,
    required String questionLanguageId,
    required int entryFee,
  }) async {
    emit(const BattleRoomSearchInProgress());
    try {
      final documents = await _battleRoomRepository.searchBattleRoom(
        questionLanguageId: questionLanguageId,
        categoryId: categoryId,
        name: name,
        profileUrl: profileUrl,
        uid: uid,
      );

      if (documents.isNotEmpty) {
        final room = documents[Random.secure().nextInt(documents.length)];
        emit(const BattleRoomJoining());
        final questions = await _battleRoomRepository.getQuestions(
          isRandom: true,
          categoryId: categoryId,
          matchId: room.id,
          forMultiUser: false,
          roomDocumentId: room.id,
          languageId: questionLanguageId,
          roomCreator: false,
          entryCoin: entryFee,
        );
        final searchAgain = await _battleRoomRepository.joinBattleRoom(
          battleRoomDocumentId: room.id,
          name: name,
          profileUrl: profileUrl,
          uid: uid,
        );
        if (searchAgain) {
          await searchRoom(
            categoryId: categoryId,
            name: name,
            profileUrl: profileUrl,
            uid: uid,
            questionLanguageId: questionLanguageId,
            entryFee: entryFee,
          );
        } else {
          subscribeToBattleRoom(room.id, questions, isGroupBattle: false);
        }
      } else {
        await createRoom(
          categoryId: categoryId,
          categoryName: '',
          categoryImage: '',
          entryFee: entryFee,
          name: name,
          profileUrl: profileUrl,
          questionLanguageId: questionLanguageId,
          uid: uid,
        );
      }
    } on Exception catch (e) {
      emit(BattleRoomFailure(e.toString()));
    }
  }

  /// Generates a random room code for friend battles.
  String generateRoomCode(RoomCodeCharType charType, int length) =>
      String.fromCharCodes(
        Iterable.generate(
          length,
          (_) => charType.value.codeUnitAt(_rnd.nextInt(charType.value.length)),
        ),
      );

  /// Creates a battle room for random matchmaking or friend battles.
  ///
  /// [charType] null: Random matchmaking (no room code)
  /// [charType] provided: Friend battle (generates 6-char room code)
  Future<void> createRoom({
    required String categoryId,
    required String categoryName,
    required String categoryImage,
    RoomCodeCharType? charType,
    String? name,
    String? profileUrl,
    String? uid,
    int? entryFee,
    String? questionLanguageId,
  }) async {
    emit(const BattleRoomCreating());
    try {
      var roomCode = '';
      if (charType != null) {
        roomCode = generateRoomCode(charType, 6);
      }
      final documentSnapshot = await _battleRoomRepository.createBattleRoom(
        categoryId: categoryId,
        categoryName: categoryName,
        categoryImage: categoryImage,
        name: name!,
        profileUrl: profileUrl!,
        uid: uid!,
        roomCode: roomCode,
        roomType: 'public',
        entryFee: entryFee,
        questionLanguageId: questionLanguageId!,
      );

      final questions = await _battleRoomRepository.getQuestions(
        categoryId: categoryId,
        forMultiUser: false,
        isRandom: charType == null,
        matchId: charType != null ? roomCode : documentSnapshot.id,
        roomDocumentId: documentSnapshot.id,
        roomCreator: true,
        languageId: questionLanguageId,
        entryCoin: entryFee,
      );

      emit(
        BattleRoomCreated(BattleRoom.fromDocumentSnapshot(documentSnapshot)),
      );

      subscribeToBattleRoom(
        documentSnapshot.id,
        questions,
        isGroupBattle: false,
      );
    } on Exception catch (e) {
      emit(BattleRoomFailure(e.toString()));
    }
  }

  Future<void> createRoomWithBot({
    required String categoryId,
    required BuildContext context,
    RoomCodeCharType? charType,
    String? name,
    String? profileUrl,
    String? uid,
    int? entryFee,
    String? botName,
    String? questionLanguageId,
  }) async {
    emit(const BattleRoomCreating());
    try {
      var roomCode = '';
      if (charType != null) {
        roomCode = generateRoomCode(charType, 6);
      }
      final documentSnapshot = await _battleRoomRepository
          .createBattleRoomWithBot(
            categoryId: categoryId,
            name: name!,
            profileUrl: profileUrl!,
            uid: uid!,
            roomCode: roomCode,
            botName: botName,
            roomType: 'public',
            entryFee: entryFee,
            questionLanguageId: questionLanguageId!,
            context: context,
          );

      emit(
        BattleRoomCreated(BattleRoom.fromDocumentSnapshot(documentSnapshot)),
      );
      final questions = await _battleRoomRepository.getQuestions(
        categoryId: categoryId,
        isRandom: true,
        forMultiUser: false,
        matchId: charType != null ? roomCode : documentSnapshot.id,
        roomDocumentId: documentSnapshot.id,
        roomCreator: true,
        languageId: questionLanguageId,
        entryCoin: entryFee,
      );

      joinBattleRoomWithBot(documentSnapshot.id, questions, type: false);
    } on Exception catch (e) {
      emit(BattleRoomFailure(e.toString()));
    }
  }

  Future<void> joinRoom({
    required String currentCoin,
    String? name,
    String? profileUrl,
    String? uid,
    String? roomCode,
  }) async {
    emit(const BattleRoomJoining());
    try {
      final (:roomId, :questions) = await _battleRoomRepository
          .joinBattleRoomFrd(
            name: name,
            profileUrl: profileUrl,
            roomCode: roomCode,
            uid: uid,
            currentCoin: int.parse(currentCoin),
          );

      subscribeToBattleRoom(roomId, questions, isGroupBattle: false);
    } on Exception catch (e) {
      emit(BattleRoomFailure(e.toString()));
    }
  }

  /// Updates local question state with user's submitted answer.
  ///
  /// This is for local UI state only. The actual answer submission to
  /// Firebase happens in [submitAnswer].
  void updateQuestionAnswer(String? questionId, String? submittedAnswerId) {
    if (state is BattleRoomUserFound) {
      final updatedQuestions = (state as BattleRoomUserFound).questions;
      final questionIndex = updatedQuestions.indexWhere(
        (element) => element.id == questionId,
      );

      updatedQuestions[questionIndex] = updatedQuestions[questionIndex]
          .updateQuestionWithAnswer(submittedAnswerId: submittedAnswerId!);

      emit(
        BattleRoomUserFound(
          isRoomExist: (state as BattleRoomUserFound).isRoomExist,
          hasLeft: (state as BattleRoomUserFound).hasLeft,
          battleRoom: (state as BattleRoomUserFound).battleRoom,
          questions: updatedQuestions,
        ),
      );
    }
  }

  void deleteBattleRoom() {
    if (state is BattleRoomUserFound) {
      final battleRoom = (state as BattleRoomUserFound).battleRoom;
      _battleRoomRepository.deleteBattleRoom(
        battleRoom.roomId,
        isGroupBattle: false,
      );
      emit(const BattleRoomDeleted());
    } else if (state is BattleRoomCreated) {
      final battleRoom = (state as BattleRoomCreated).battleRoom;
      _battleRoomRepository.deleteBattleRoom(
        battleRoom.roomId,
        isGroupBattle: false,
      );
      emit(const BattleRoomDeleted());
    }
  }

  void deleteUserFromRoom(String userId) {
    if (state is BattleRoomUserFound) {
      final room = (state as BattleRoomUserFound).battleRoom;
      if (userId == room.user1!.uid) {
        _battleRoomRepository.deleteUserFromRoom(1, room);
      } else {
        _battleRoomRepository.deleteUserFromRoom(2, room);
      }
    }
  }

  void removeOpponentFromBattleRoom() {
    if (state is BattleRoomUserFound) {
      _battleRoomRepository.removeOpponentFromBattleRoom(
        (state as BattleRoomUserFound).battleRoom.roomId!,
      );
    }
  }

  void startGame() {
    if (state is BattleRoomUserFound) {
      _battleRoomRepository.startMultiUserQuiz(
        (state as BattleRoomUserFound).battleRoom.roomId,
        isMultiUserRoom: false,
      );
    }
  }

  BattleRoom? get battleRoom => state is BattleRoomUserFound
      ? (state as BattleRoomUserFound).battleRoom
      : null;

  int getEntryFee() {
    if (state is BattleRoomUserFound) {
      return (state as BattleRoomUserFound).battleRoom.entryFee!;
    }
    if (state is BattleRoomCreated) {
      return (state as BattleRoomCreated).battleRoom.entryFee!;
    }
    return 0;
  }

  String get categoryName {
    if (state is BattleRoomUserFound) {
      return (state as BattleRoomUserFound).battleRoom.categoryName!;
    }
    if (state is BattleRoomCreated) {
      return (state as BattleRoomCreated).battleRoom.categoryName!;
    }
    return '';
  }

  String get categoryImage {
    if (state is BattleRoomUserFound) {
      return (state as BattleRoomUserFound).battleRoom.categoryImage!;
    }
    if (state is BattleRoomCreated) {
      return (state as BattleRoomCreated).battleRoom.categoryImage!;
    }
    return '';
  }

  String getRoomCode() {
    if (state is BattleRoomUserFound) {
      return (state as BattleRoomUserFound).battleRoom.roomCode!;
    }
    if (state is BattleRoomCreated) {
      return (state as BattleRoomCreated).battleRoom.roomCode!;
    }
    return '';
  }

  /// Submits answer to Firebase and updates user's score in real-time.
  ///
  /// Only submits if user hasn't answered all questions yet (prevents
  /// duplicate submissions). The answer data includes:
  /// - Selected answer ID
  /// - Question ID
  /// - Time taken to answer (in seconds)
  void submitAnswer(
    String? currentUserId,
    String? submittedAnswer, {
    required bool isAnswerCorrect,
    String questionId = '',
    String timeTookToSubmitAnswer = '',
  }) {
    if (state is BattleRoomUserFound) {
      final battleRoom = (state as BattleRoomUserFound).battleRoom;
      final questions = (state as BattleRoomUserFound).questions;

      final forUser1 = battleRoom.user1!.uid == currentUserId;
      final user = forUser1 ? battleRoom.user1! : battleRoom.user2!;

      // Prevent duplicate submissions after all questions are answered
      if (user.answers.length != questions.length) {
        _battleRoomRepository.submitAnswer(
          battleRoomDocumentId: battleRoom.roomId,
          correctAnswers: isAnswerCorrect
              ? (user.correctAnswers + 1)
              : user.correctAnswers,
          forUser1: forUser1,
          submittedAnswer: List.from(user.answers)
            ..add({
              'answer': submittedAnswer ?? '',
              'id': questionId,
              'second': timeTookToSubmitAnswer,
            }),
        );
      }
    }
  }

  /// Returns the current question index based on slower player's progress.
  ///
  /// Both players must answer the current question before advancing.
  /// The index is determined by the player with fewer submitted answers.
  int getCurrentQuestionIndex() {
    if (state is BattleRoomUserFound) {
      final currentState = state as BattleRoomUserFound;
      final user1AnswerCount = currentState.battleRoom.user1!.answers.length;
      final user2AnswerCount = currentState.battleRoom.user2!.answers.length;

      // Use the smaller answer count to ensure both players are in sync
      var currentQuestionIndex = user1AnswerCount <= user2AnswerCount
          ? user1AnswerCount
          : user2AnswerCount;

      // Prevent index out of range after quiz completion
      if (currentQuestionIndex == currentState.questions.length) {
        currentQuestionIndex--;
      }

      return currentQuestionIndex;
    }

    return 0;
  }

  List<Question> getQuestions() {
    if (state is BattleRoomUserFound) {
      return (state as BattleRoomUserFound).questions;
    }
    return [];
  }

  String getRoomId() {
    if (state is BattleRoomUserFound) {
      return (state as BattleRoomUserFound).battleRoom.roomId!;
    }
    if (state is BattleRoomCreated) {
      return (state as BattleRoomCreated).battleRoom.roomId!;
    }
    return '';
  }

  UserBattleRoomDetails getCurrentUserDetails(String currentUserId) {
    if (state is BattleRoomUserFound) {
      if (currentUserId ==
          (state as BattleRoomUserFound).battleRoom.user1?.uid) {
        return (state as BattleRoomUserFound).battleRoom.user1!;
      } else {
        return (state as BattleRoomUserFound).battleRoom.user2!;
      }
    }
    return const UserBattleRoomDetails(
      answers: [],
      correctAnswers: 0,
      name: 'name',
      profileUrl: 'profileUrl',
      uid: 'uid',
      points: 0,
    );
  }

  UserBattleRoomDetails getOpponentUserDetails(String currentUserId) {
    if (state is BattleRoomUserFound) {
      if (currentUserId ==
          (state as BattleRoomUserFound).battleRoom.user1?.uid) {
        return (state as BattleRoomUserFound).battleRoom.user2!;
      } else {
        return (state as BattleRoomUserFound).battleRoom.user1!;
      }
    }
    return const UserBattleRoomDetails(
      points: 0,
      answers: [],
      correctAnswers: 0,
      name: 'name',
      profileUrl: 'profileUrl',
      uid: 'uid',
    );
  }

  bool opponentLeftTheGame(String userId) {
    if (state is BattleRoomUserFound) {
      return (state as BattleRoomUserFound).hasLeft &&
          getCurrentUserDetails(userId).answers.length !=
              (state as BattleRoomUserFound).questions.length;
    }

    return false;
  }

  List<UserBattleRoomDetails?> getUsers() {
    if (state is BattleRoomUserFound) {
      final users = <UserBattleRoomDetails?>[];
      final battleRoom = (state as BattleRoomUserFound).battleRoom;
      if (battleRoom.user1!.uid.isNotEmpty) {
        users.add(battleRoom.user1);
      }
      if (battleRoom.user2!.uid.isNotEmpty) {
        users.add(battleRoom.user2);
      }

      return users;
    }
    return [];
  }

  @override
  Future<void> close() async {
    await _battleRoomStreamSubscription?.cancel();
    return super.close();
  }
}
