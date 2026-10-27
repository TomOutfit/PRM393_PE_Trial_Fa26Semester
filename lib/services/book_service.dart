import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'books';

  /// Lấy danh sách sách của user dưới dạng Stream thời gian thực
  Stream<List<BookModel>> getBooksStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final books = snapshot.docs
          .map((doc) => BookModel.fromFirestore(doc))
          .toList();

      // Sắp xếp thứ tự bảng chữ cái theo Title (không phân biệt hoa/thường), nếu tiêu đề trùng thì theo Author
      books.sort((a, b) {
        int titleCompare = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        if (titleCompare != 0) return titleCompare;
        return a.author.toLowerCase().compareTo(b.author.toLowerCase());
      });

      return books;
    });
  }

  /// Kiểm tra trùng lặp tiêu đề + tác giả cho cùng một người dùng (case-insensitive)
  Future<bool> isDuplicateBook({
    required String userId,
    required String title,
    required String author,
    String? excludeBookId,
  }) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    final targetTitle = title.trim().toLowerCase();
    final targetAuthor = author.trim().toLowerCase();

    for (var doc in querySnapshot.docs) {
      if (excludeBookId != null && doc.id == excludeBookId) {
        continue;
      }
      final data = doc.data();
      final docTitle = (data['title'] as String? ?? '').trim().toLowerCase();
      final docAuthor = (data['author'] as String? ?? '').trim().toLowerCase();

      if (docTitle == targetTitle && docAuthor == targetAuthor) {
        return true;
      }
    }
    return false;
  }

  /// Thêm một cuốn sách mới vào Firestore
  Future<void> addBook(BookModel book) async {
    final isDup = await isDuplicateBook(
      userId: book.userId,
      title: book.title,
      author: book.author,
    );

    if (isDup) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message: 'A book with this title and author already exists.',
      );
    }

    await _firestore.collection(_collection).add(book.toMap());
  }

  /// Cập nhật thông tin cuốn sách trong Firestore
  Future<void> updateBook(BookModel book) async {
    final isDup = await isDuplicateBook(
      userId: book.userId,
      title: book.title,
      author: book.author,
      excludeBookId: book.id,
    );

    if (isDup) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message: 'A book with this title and author already exists.',
      );
    }

    await _firestore.collection(_collection).doc(book.id).update(book.toMap());
  }

  /// Thay đổi trạng thái Yêu thích (favorite)
  Future<void> toggleFavorite(String bookId, bool currentFavorite) async {
    await _firestore
        .collection(_collection)
        .doc(bookId)
        .update({'favorite': !currentFavorite});
  }

  /// Xóa cuốn sách khỏi Firestore
  Future<void> deleteBook(String bookId) async {
    await _firestore.collection(_collection).doc(bookId).delete();
  }
}
