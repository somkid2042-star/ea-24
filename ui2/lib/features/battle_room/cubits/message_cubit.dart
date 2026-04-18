import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/battle_room/battle_room_repository.dart';
import 'package:flutterquiz/features/battle_room/models/message.dart';

sealed class MessageState {
  const MessageState();
}

final class MessageInitial extends MessageState {
  const MessageInitial();
}

final class MessageAddInProgress extends MessageState {
  const MessageAddInProgress();
}

final class MessageFetchedSuccess extends MessageState {
  const MessageFetchedSuccess(this.messages);

  final List<Message> messages;
}

final class MessageAddedFailure extends MessageState {
  const MessageAddedFailure(this.errorCode);

  final String errorCode;
}

/// Manages real-time chat messages in battle rooms.
///
/// Provides functionality to:
/// - Subscribe to real-time message updates
/// - Send new messages
/// - Delete user messages when leaving
/// - Check for new messages from specific users
final class MessageCubit extends Cubit<MessageState> {
  MessageCubit(this._battleRoomRepository)
    : super(MessageFetchedSuccess(List<Message>.from([])));

  final BattleRoomRepository _battleRoomRepository;
  late StreamSubscription<List<Message>> streamSubscription;

  /// Starts listening to real-time message updates for a battle room.
  void subscribeToMessages(String roomId) {
    streamSubscription = _battleRoomRepository
        .subscribeToMessages(roomId: roomId)
        .listen((messages) {
          emit(MessageFetchedSuccess(messages));
        });
  }

  /// Adds a new message to the battle room.
  ///
  /// The [isTextMessage] flag distinguishes between text messages and
  /// emoji/sticker messages for rendering purposes.
  Future<void> addMessage({
    required String message,
    required String by,
    required String roomId,
    required bool isTextMessage,
  }) async {
    try {
      await _battleRoomRepository.addMessage(
        Message(
          by: by,
          isTextMessage: isTextMessage,
          message: message,
          messageId: '',
          roomId: roomId,
          timestamp: Timestamp.now(),
        ),
      );
    } on Exception catch (e) {
      emit(MessageAddedFailure(e.toString()));
    }
  }

  /// Deletes all messages sent by a specific user when they leave the room.
  void deleteMessages(String roomId, String by) {
    streamSubscription.cancel();
    _battleRoomRepository.deleteMessagesByUserId(roomId, by);
  }

  /// Returns the latest message from a specific user.
  ///
  /// If [messageId] is null: Returns the most recent message for display.
  /// If [messageId] is provided: Returns empty if it matches the latest
  /// message, otherwise returns the new message (used to detect new messages).
  Message getUserLatestMessage(String userId, {String? messageId}) {
    if (state is MessageFetchedSuccess) {
      final messages = (state as MessageFetchedSuccess).messages;
      final messagesByUser = messages.where((e) => e.by == userId);

      if (messagesByUser.isEmpty) {
        return Message.empty;
      }

      // Fetch latest message for display
      if (messageId == null) {
        return messagesByUser.first;
      }

      // Check if there's a new message since last check
      return messagesByUser.first.messageId == messageId
          ? Message
                .empty // No new message
          : messagesByUser.first; // New message available
    }

    return Message.empty;
  }

  @override
  Future<void> close() async {
    await streamSubscription.cancel();
    await super.close();
  }
}
