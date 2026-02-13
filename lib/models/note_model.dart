import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String message;
  final String authorId;
  final String authorName;
  final String emoji;
  final DateTime? createdAt;

  Note({
    required this.id,
    required this.message,
    required this.authorId,
    required this.authorName,
    this.emoji = '❤️',
    this.createdAt,
  });

  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      message: data['message'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      emoji: data['emoji'] ?? '❤️',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'authorId': authorId,
      'authorName': authorName,
      'emoji': emoji,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
