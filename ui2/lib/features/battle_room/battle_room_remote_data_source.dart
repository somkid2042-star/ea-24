import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/core/constants/api_exception.dart';
import 'package:flutterquiz/core/constants/constants.dart';
import 'package:flutterquiz/features/system_config/cubits/system_config_cubit.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:flutterquiz/utils/internet_connectivity.dart';
import 'package:http/http.dart' as http;

/// Remote data source for battle room operations.
///
/// Handles:
/// - Battle room CRUD operations (create, read, delete)
/// - Question fetching for 1v1 and group battles
/// - Room matchmaking and joining logic
/// - Real-time message management
/// - User data updates during battles
final class BattleRoomRemoteDataSource {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  /// Fetches questions for 1v1 battles from the backend API.
  ///
  /// For random battles: Uses [matchId] as room document ID
  /// For friend battles: Uses [matchId] as room code
  Future<List<Map<String, dynamic>>?> getQuestions({
    required String languageId,
    required String categoryId,
    required String matchId,
    bool isRandom = false,
    int? entryCoin,
  }) async {
    try {
      final body = <String, String>{
        languageIdKey: languageId,
        matchIdKey: matchId,
        categoryKey: categoryId,
        if (isRandom) 'random': '1',
        'entry_coin': ?entryCoin?.toString(),
      };
      if (categoryId.isEmpty) {
        body.remove(categoryKey);
      }
      if (languageId.isEmpty) {
        body.remove(languageIdKey);
      }

      final response = await http.post(
        Uri.parse(getQuestionForOneToOneBattle),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        throw ApiException(responseJson['message'] as String);
      }

      return (responseJson['data'] as List? ?? []).cast<Map<String, dynamic>>();
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  /// Fetches questions for group battles (up to 4 players) from the backend API.
  Future<List<Map<String, dynamic>>?> getMultiUserBattleQuestions(
    String? roomCode,
  ) async {
    try {
      final body = <String, String?>{roomIdKey: roomCode};

      final response = await http.post(
        Uri.parse(getQuestionForMultiUserBattle),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

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

  /// Subscribes to real-time battle room updates from Firestore.
  ///
  /// Returns a stream that emits whenever the room document changes
  /// (user joins/leaves, answers submitted, game state changes).
  Stream<DocumentSnapshot> subscribeToBattleRoom(
    String? battleRoomDocumentId, {
    required bool forMultiUser,
  }) {
    if (forMultiUser) {
      return _firebaseFirestore
          .collection(multiUserBattleRoomCollection)
          .doc(battleRoomDocumentId)
          .snapshots();
    }

    return _firebaseFirestore
        .collection(battleRoomCollection)
        .doc(battleRoomDocumentId)
        .snapshots();
  }

  /// Removes opponent (user2) from a 1v1 battle room.
  ///
  /// Resets user2 data to empty, allowing another player to join.
  Future<void> removeOpponentFromBattleRoom(String roomId) async {
    try {
      await _firebaseFirestore
          .collection(battleRoomCollection)
          .doc(roomId)
          .update({
            'user2': {
              'name': '',
              'correctAnswers': 0,
              'answers': <String>[],
              'uid': '',
              'profileUrl': '',
            },
          });
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on PlatformException {
      throw const ApiException(errorCodeDefaultMessage);
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  /// Searches for available 1v1 battle rooms for random matchmaking.
  ///
  /// Finds rooms that match:
  /// - Same category and language
  /// - No room code (random battles only)
  /// - Empty user2 slot (waiting for opponent)
  Future<List<DocumentSnapshot>> searchBattleRoom(
    String categoryId,
    String questionLanguageId,
  ) async {
    try {
      if (await InternetConnectivity.isUserOffline()) {
        throw const SocketException('');
      }

      final querySnapshot = await _firebaseFirestore
          .collection(battleRoomCollection)
          .where('languageId', isEqualTo: questionLanguageId)
          .where('categoryId', isEqualTo: categoryId)
          .where('roomCode', isEqualTo: '')
          .where('user2.uid', isEqualTo: '')
          .get();

      return querySnapshot.docs;
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on PlatformException {
      throw const ApiException(errorCodeUnableToFindRoom);
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  /// Deletes a battle room from Firestore.
  ///
  /// For group battles: Also cleans up associated room code data.
  Future<void> deleteBattleRoom(
    String? documentId, {
    required bool isGroupBattle,
    String? roomCode,
  }) async {
    try {
      if (isGroupBattle) {
        await _firebaseFirestore
            .collection(multiUserBattleRoomCollection)
            .doc(documentId)
            .delete();
      } else {
        await _firebaseFirestore
            .collection(battleRoomCollection)
            .doc(documentId)
            .delete();
      }
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on PlatformException {
      throw const ApiException(errorCodeDefaultMessage);
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  /// Gets all rooms created by a specific user (both 1v1 and group battles).
  ///
  /// Returns a map with 'battle' and 'groupBattle' keys containing
  /// respective room documents.
  Future<Map<String, List<DocumentSnapshot>>> getRoomCreatedByUser(
    String userId,
  ) async {
    try {
      final multiUserBattleQuerySnapshot = await _firebaseFirestore
          .collection(multiUserBattleRoomCollection)
          .where('createdBy', isEqualTo: userId)
          .get();

      final battleQuerySnapshot = await _firebaseFirestore
          .collection(battleRoomCollection)
          .where('createdBy', isEqualTo: userId)
          .get();

      return {
        'battle': battleQuerySnapshot.docs,
        'groupBattle': multiUserBattleQuerySnapshot.docs,
      };
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on PlatformException {
      throw const ApiException(errorCodeDefaultMessage);
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  /// Creates a new 1v1 battle room in Firestore.
  ///
  /// The creator becomes user1, user2 slot is empty awaiting opponent.
  /// For friend battles, [roomCode] is provided; for random battles, it's empty.
  Future<DocumentSnapshot> createBattleRoom({
    required String categoryId,
    required String categoryName,
    required String categoryImage,
    required String name,
    required String profileUrl,
    required String uid,
    required String questionLanguageId,
    String? roomCode,
    String? roomType,
    int? entryFee,
  }) async {
    try {
      final documentReference = await _firebaseFirestore
          .collection(battleRoomCollection)
          .add({
            'createdBy': uid,
            'categoryId': categoryId,
            'categoryName': categoryName,
            'categoryImage': categoryImage,
            'languageId': questionLanguageId,
            'roomCode': roomCode ?? '',
            'entryFee': entryFee ?? 0,
            'readyToPlay': false,
            'user1': {
              'name': name,
              'points': 0,
              'correctAnswers': 0,
              'answers': <String>[],
              'uid': uid,
              'profileUrl': profileUrl,
            },
            'user2': {
              'name': '',
              'points': 0,
              'correctAnswers': 0,
              'answers': <String>[],
              'uid': '',
              'profileUrl': '',
            },
            'createdAt': Timestamp.now(),
          });

      return documentReference.get();
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on PlatformException {
      throw const ApiException(errorCodeUnableToCreateRoom);
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  /// Creates a 1v1 battle room with a bot opponent.
  ///
  /// The bot is assigned to user2 with uid '000' and uses the system
  /// configured bot image. Room is immediately ready to play.
  Future<DocumentSnapshot> createBattleRoomWithBot({
    required String categoryId,
    required String name,
    required String profileUrl,
    required String uid,
    required String questionLanguageId,
    required BuildContext context,
    String? roomCode,
    String? roomType,
    int? entryFee,
    String? botName,
  }) async {
    try {
      final documentReference = await _firebaseFirestore
          .collection(battleRoomCollection)
          .add({
            'createdBy': uid,
            'categoryId': categoryId,
            'languageId': questionLanguageId,
            'roomCode': roomCode ?? '',
            'entryFee': entryFee ?? 0,
            'readyToPlay': true,
            'user1': {
              'name': name,
              'points': 0,
              'correctAnswers': 0,
              'answers': <String>[],
              'uid': uid,
              'profileUrl': profileUrl,
            },
            'user2': {
              'name': botName ?? 'Robot',
              'points': 0,
              'correctAnswers': 0,
              'answers': <String>[],
              'uid': '000',
              'profileUrl': context.read<SystemConfigCubit>().botImage,
            },
            'createdAt': Timestamp.now(),
          });

      return documentReference.get();
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on PlatformException {
      throw const ApiException(errorCodeUnableToCreateRoom);
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  /// Creates a group battle room for up to 4 players.
  ///
  /// First validates room code with backend API, then creates Firestore document
  /// with 4 empty user slots (creator assigned to user1).
  Future<DocumentSnapshot> createMultiUserBattleRoom({
    required String categoryId,
    required String categoryName,
    required String categoryImage,
    String? name,
    String? profileUrl,
    String? uid,
    String? roomCode,
    String? roomType,
    int? entryFee,
    String? questionLanguageId,
  }) async {
    try {
      final body = <String, String>{
        roomIdKey: roomCode!,
        roomTypeKey: roomType!,
        categoryKey: categoryId,
        languageIdKey: questionLanguageId!,
        'entry_coin': entryFee.toString(),
      };
      if (categoryId.isEmpty) {
        body.remove(categoryKey);
      }
      if (questionLanguageId.isEmpty) {
        body.remove(languageIdKey);
      }

      // Validate room code with backend
      final response = await http.post(
        Uri.parse(createMultiUserBattleRoomUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        throw ApiException(responseJson['message'].toString());
      }

      // Create Firestore room document
      final documentReference = await _firebaseFirestore
          .collection(multiUserBattleRoomCollection)
          .add({
            'createdBy': uid,
            'categoryId': categoryId,
            'categoryName': categoryName,
            'categoryImage': categoryImage,
            'roomCode': roomCode,
            'entryFee': entryFee,
            'readyToPlay': false,
            'user1': {
              'name': name,
              'correctAnswers': 0,
              'answers': <String>[],
              'uid': uid,
              'profileUrl': profileUrl,
            },
            'user2': {
              'name': '',
              'correctAnswers': 0,
              'answers': <String>[],
              'uid': '',
              'profileUrl': '',
            },
            'user3': {
              'name': '',
              'correctAnswers': 0,
              'answers': <String>[],
              'uid': '',
              'profileUrl': '',
            },
            'user4': {
              'name': '',
              'correctAnswers': 0,
              'answers': <String>[],
              'uid': '',
              'profileUrl': '',
            },
            'createdAt': Timestamp.now(),
          });
      return documentReference.get();
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on PlatformException {
      throw const ApiException(errorCodeUnableToCreateRoom);
    } on ApiException catch (e) {
      throw ApiException(e.toString());
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  /// Joins an existing 1v1 battle room.
  ///
  /// Uses Firestore transaction to atomically check and join the room.
  /// Returns true if user2 slot was already filled (search for another room).
  /// Returns false if successfully joined as user2.
  Future<bool> joinBattleRoom({
    String? name,
    String? profileUrl,
    String? uid,
    String? battleRoomDocumentId,
  }) async {
    try {
      final documentReference =
          (await _firebaseFirestore
                  .collection(battleRoomCollection)
                  .doc(battleRoomDocumentId)
                  .get())
              .reference;

      return FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get latest room state to avoid race conditions
        final documentSnapshot = await documentReference.get();
        final user2Details =
            documentSnapshot.data()!['user2'] as Map<String, dynamic>;

        if (user2Details['uid'].toString().isEmpty) {
          // User2 slot available, join as user2
          transaction.update(documentReference, {
            'user2.name': name,
            'user2.uid': uid,
            'user2.profileUrl': profileUrl,
          });
          return false; // Successfully joined
        }

        return true; // Room full, search for another
      });
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on PlatformException {
      throw const ApiException(errorCodeUnableToJoinRoom);
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  /// Finds a room by room code (supports both 1v1 and group battles).
  Future<QuerySnapshot> getMultiUserBattleRoom(
    String? roomCode,
    String? type,
  ) async {
    try {
      final querySnapshot = await _firebaseFirestore
          .collection(
            type == 'battle'
                ? battleRoomCollection
                : multiUserBattleRoomCollection,
          )
          .where('roomCode', isEqualTo: roomCode)
          .get();
      return querySnapshot;
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on PlatformException {
      throw const ApiException(errorCodeUnableToFindRoom);
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  /// Submits a player's answer to Firestore.
  ///
  /// Updates the appropriate user's answers array and correct answer count.
  Future<void> submitAnswer({
    required Map<String, dynamic> submitAnswer,
    required bool forMultiUser,
    String? battleRoomDocumentId,
  }) async {
    try {
      if (forMultiUser) {
        await _firebaseFirestore
            .collection(multiUserBattleRoomCollection)
            .doc(battleRoomDocumentId)
            .update(submitAnswer);
      } else {
        await _firebaseFirestore
            .collection(battleRoomCollection)
            .doc(battleRoomDocumentId)
            .update(submitAnswer);
      }
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on PlatformException {
      throw const ApiException(errorCodeUnableToSubmitAnswer);
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  /// Updates user data in a battle room.
  ///
  /// Used for removing users, updating ready states, or modifying player info.
  Future<void> updateUserDataInRoom(
    String? documentId,
    Map<String, dynamic> updatedData, {
    required bool isMultiUserRoom,
  }) async {
    try {
      await _firebaseFirestore
          .collection(
            !isMultiUserRoom
                ? battleRoomCollection
                : multiUserBattleRoomCollection,
          )
          .doc(documentId)
          .update(updatedData);
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on PlatformException {
      throw const ApiException(errorCodeDefaultMessage);
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  // Message Operations

  /// Subscribes to real-time chat messages in a battle room.
  ///
  /// Messages are ordered by timestamp (newest first).
  Stream<QuerySnapshot> subscribeToMessages({required String roomId}) {
    return _firebaseFirestore
        .collection(messagesCollection)
        .where('roomId', isEqualTo: roomId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Adds a new message to the battle room chat.
  ///
  /// Returns the created message document ID.
  Future<String> addMessage(Map<String, dynamic> data) async {
    try {
      final documentReference = await _firebaseFirestore
          .collection(messagesCollection)
          .add(data);

      return documentReference.id;
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on PlatformException {
      throw const ApiException(errorCodeDefaultMessage);
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  /// Deletes a specific message from the chat.
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firebaseFirestore
          .collection(messagesCollection)
          .doc(messageId)
          .delete();
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on PlatformException {
      throw const ApiException(errorCodeDefaultMessage);
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  /// Gets all messages sent by a specific user in a room.
  ///
  /// Used for deleting user messages when they leave the room.
  Future<List<DocumentSnapshot>> getMessagesByUserId(
    String roomId,
    String by,
  ) async {
    try {
      final querySnapshot = await _firebaseFirestore
          .collection(messagesCollection)
          .where('roomId', isEqualTo: roomId)
          .where('by', isEqualTo: by)
          .get();

      return querySnapshot.docs;
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on PlatformException {
      throw const ApiException(errorCodeDefaultMessage);
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }
}
