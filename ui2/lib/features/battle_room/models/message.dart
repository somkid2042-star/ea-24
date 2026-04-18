import 'package:cloud_firestore/cloud_firestore.dart';

final class Message {
  const Message({
    required this.by,
    required this.isTextMessage,
    required this.message,
    required this.messageId,
    required this.roomId,
    required this.timestamp,
  });

  Message.fromDocumentSnapshot(
    Map<String, dynamic> json, {
    required this.messageId,
  }) : by = json['by'] as String? ?? '',
       isTextMessage = json['isTextMessage'] as bool? ?? false,
       message = json['message'] as String? ?? '',
       roomId = json['roomId'] as String? ?? '',
       timestamp = json['timestamp'] as Timestamp? ?? Timestamp.now();

  final String messageId;
  final String message;
  final String roomId;
  final String by;
  final Timestamp timestamp;
  final bool isTextMessage;

  static Message empty = Message(
    by: '',
    isTextMessage: false,
    message: '',
    messageId: '',
    roomId: '',
    timestamp: Timestamp.now(),
  );

  Map<String, dynamic> toJson() => {
    'by': by,
    'roomId': roomId,
    'message': message,
    'isTextMessage': isTextMessage,
    'timestamp': timestamp,
  };
}
