import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_item.dart';

/// Singleton Service quản lý kết nối và thao tác dữ liệu với Supabase
class SupabaseService {
  // Private constructor
  SupabaseService._internal();

  // Instance duy nhất của Singleton
  static final SupabaseService instance = SupabaseService._internal();

  // Placeholder URL & Anon Key của Supabase Project
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  static const String _tableName = 'tasks';

  /// Khởi tạo Supabase client (gọi trong main.dart trước runApp)
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  /// Getter để truy cập SupabaseClient
  SupabaseClient get client => Supabase.instance.client;

  // ==================== KHUNG 4 HÀM CRUD CƠ BẢN ====================

  /// 1. Lấy danh sách tất cả các công việc (getAll)
  Future<List<TaskItem>> getAll() async {
    final response = await client
        .from(_tableName)
        .select()
        .order('created_at', ascending: false);

    final dataList = response as List<dynamic>;
    return dataList.map((map) => TaskItem.fromMap(map as Map<String, dynamic>)).toList();
  }

  /// 2. Thêm mới công việc (insert)
  Future<TaskItem> insert(TaskItem task) async {
    final response = await client
        .from(_tableName)
        .insert(task.toMap())
        .select()
        .single();

    return TaskItem.fromMap(response);
  }

  /// 3. Cập nhật trạng thái hoàn thành (updateStatus)
  Future<void> updateStatus(int id, bool isCompleted) async {
    await client
        .from(_tableName)
        .update({'is_completed': isCompleted})
        .eq('id', id);
  }

  /// 4. Xóa công việc (delete)
  Future<void> delete(int id) async {
    await client
        .from(_tableName)
        .delete()
        .eq('id', id);
  }
}
