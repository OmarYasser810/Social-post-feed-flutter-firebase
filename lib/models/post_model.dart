import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final List<String> likes;
  final DateTime? createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    this.likes = const [],
    this.createdAt,
  });

  // Create PostModel from Firestore document
  factory PostModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Safely convert likes list
    List<String> likesList = [];
    if (data['likes'] != null) {
      likesList = (data['likes'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }
    
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      text: data['text'] ?? '',
      likes: likesList,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert PostModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'text': text,
      'likes': likes,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
    };
  }

  // Create a copy with updated fields
  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? text,
    List<String>? likes,
    DateTime? createdAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      text: text ?? this.text,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters
  int get likeCount => likes.length;
  
  bool isLikedBy(String userId) => likes.contains(userId);
}