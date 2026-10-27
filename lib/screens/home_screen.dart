import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;

  List<TaskItem> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  /// Lấy danh sách công việc từ Supabase
  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await _supabaseService.getAll();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  /// Thao tác đổi trạng thái Checkbox
  Future<void> _toggleTaskStatus(TaskItem task, bool? newValue) async {
    if (task.id == null || newValue == null) return;

    // Cập nhật UI tạm thời trước để có trải nghiệm mượt mà (Optimistic UI)
    final originalTasks = List<TaskItem>.from(_tasks);
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task.copyWith(isCompleted: newValue);
      }
    });

    try {
      await _supabaseService.updateStatus(task.id!, newValue);
    } catch (e) {
      // Revert lại nếu gọi API thất bại
      setState(() {
        _tasks = originalTasks;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thất bại: $e')),
        );
      }
    }
  }

  /// Thao tác xóa task
  Future<void> _deleteTask(TaskItem task) async {
    if (task.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "${task.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabaseService.delete(task.id!);
      setState(() {
        _tasks.removeWhere((t) => t.id == task.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa công việc thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xóa thất bại: $e')),
        );
      }
    }
  }

  /// Hiển thị Modal BottomSheet để thêm mới Task
  void _showAddTaskBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _AddTaskForm(
        onTaskCreated: (newTask) {
          setState(() {
            _tasks.insert(0, newTask);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách công việc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTasks,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskBottomSheet,
        tooltip: 'Thêm công việc',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Xử lý render UI theo trạng thái: Loading, Error, Empty, hoặc Content
  Widget _buildBody() {
    // 1. Trạng thái Loading
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 2. Trạng thái Error
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchTasks,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Trạng thái Empty
    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa có công việc nào',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            const Text('Nhấn nút + bên dưới để thêm mới công việc!'),
          ],
        ),
      );
    }

    // 4. Trạng thái có dữ liệu (ListView.builder)
    return RefreshIndicator(
      onRefresh: _fetchTasks,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          final formattedDate = task.createdAt != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(task.createdAt!)
              : null;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: Checkbox(
                value: task.isCompleted,
                onChanged: (val) => _toggleTaskStatus(task, val),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.description != null && task.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(task.description!),
                    ),
                  if (formattedDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteTask(task),
                tooltip: 'Xóa',
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widget Form Thêm mới Task dạng BottomSheet với dispose Controller đầy đủ
class _AddTaskForm extends StatefulWidget {
  final Function(TaskItem) onTaskCreated;

  const _AddTaskForm({required this.onTaskCreated});

  @override
  State<_AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends State<_AddTaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    // Giải phóng bộ nhớ cho các controller
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final newTask = TaskItem(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      final createdTask = await SupabaseService.instance.insert(newTask);

      widget.onTaskCreated(createdTask);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm công việc thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thêm công việc: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tự động đẩy bottom sheet khi mở bàn phím
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Thêm công việc mới',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tên công việc *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.task_alt),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên công việc';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả chi tiết (không bắt buộc)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu công việc', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
