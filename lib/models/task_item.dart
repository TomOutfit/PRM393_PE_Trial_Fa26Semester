class TaskItem {
  final int? id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? createdAt;

  TaskItem({
    this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.createdAt,
  });

  /// Chuyển từ Map (dữ liệu trả về từ Supabase DB) sang Data Model
  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      isCompleted: map['is_completed'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  /// Chuyển từ Data Model sang Map để gửi lên Supabase DB
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'is_completed': isCompleted,
    };
    if (id != null) {
      map['id'] = id;
    }
    if (createdAt != null) {
      map['created_at'] = createdAt!.toIso8601String();
    }
    return map;
  }

  /// Tạo bản sao đối tượng với các trường có thể thay đổi
  TaskItem copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
