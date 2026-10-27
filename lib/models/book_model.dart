import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String userId;
  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final bool favorite;
  final String? notes;
  final DateTime? createdAt;

  BookModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    this.rating,
    this.favorite = false,
    this.notes,
    this.createdAt,
  });

  /// Chuyển đổi từ Firestore DocumentSnapshot sang BookModel
  factory BookModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BookModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      author: data['author'] as String? ?? '',
      genre: data['genre'] as String? ?? 'Other',
      status: data['status'] as String? ?? 'To Read',
      rating: data['rating'] != null ? (data['rating'] as num).toInt() : null,
      favorite: data['favorite'] as bool? ?? false,
      notes: data['notes'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt'].toString()))
          : null,
    );
  }

  /// Chuyển đổi từ BookModel sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'author': author,
      'genre': genre,
      'status': status,
      'rating': rating,
      'favorite': favorite,
      'notes': notes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// Tạo bản sao với các thuộc tính được cập nhật
  BookModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? author,
    String? genre,
    String? status,
    int? rating,
    bool? favorite,
    String? notes,
    DateTime? createdAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      favorite: favorite ?? this.favorite,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
