import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';

class DetailScreen extends StatefulWidget {
  final BookModel book;

  const DetailScreen({super.key, required this.book});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late BookModel _currentBook;
  final BookService _bookService = BookService();
  bool _isEditingInline = false;

  // Form controllers cho Inline Edit mode
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _ratingController;
  late final TextEditingController _notesController;

  String? _selectedGenre;
  String? _selectedStatus;

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _genreOptions = ['Choose genre', 'Fiction', 'Non-Fiction', 'Academic', 'Other'];
  final List<String> _statusOptions = ['Choose status', 'To Read', 'Reading', 'Finished'];

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _initControllers();
  }

  void _initControllers() {
    _titleController = TextEditingController(text: _currentBook.title);
    _authorController = TextEditingController(text: _currentBook.author);
    _ratingController = TextEditingController(
      text: _currentBook.rating != null ? _currentBook.rating.toString() : '',
    );
    _notesController = TextEditingController(text: _currentBook.notes ?? '');

    _selectedGenre = _genreOptions.contains(_currentBook.genre)
        ? _currentBook.genre
        : 'Choose genre';

    _selectedStatus = _statusOptions.contains(_currentBook.status)
        ? _currentBook.status
        : 'Choose status';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _ratingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Toggle trạng thái Yêu thích
  Future<void> _toggleFavorite() async {
    final newFavorite = !_currentBook.favorite;
    setState(() {
      _currentBook = _currentBook.copyWith(favorite: newFavorite);
    });

    try {
      await _bookService.toggleFavorite(_currentBook.id, !newFavorite);
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentBook = _currentBook.copyWith(favorite: !newFavorite);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite: $e')),
        );
      }
    }
  }

  /// Xóa sách
  Future<void> _deleteBook() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${_currentBook.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _bookService.deleteBook(_currentBook.id);
      if (mounted) {
        Navigator.of(context).pop(true); // Trả về true để ListScreen cập nhật nếu cần
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete book: $e')),
        );
      }
    }
  }

  /// Lưu chỉnh sửa trong Inline Edit
  Future<void> _saveEdit() async {
    setState(() {
      _autovalidateMode = AutovalidateMode.always;
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final ratingInt = _ratingController.text.trim().isNotEmpty
        ? int.tryParse(_ratingController.text.trim())
        : null;

    final updatedBook = _currentBook.copyWith(
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      genre: _selectedGenre!,
      status: _selectedStatus!,
      rating: ratingInt,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      await _bookService.updateBook(updatedBook);
      if (mounted) {
        setState(() {
          _currentBook = updatedBook;
          _isEditingInline = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is FirebaseException) {
            _errorMessage = e.message ?? e.toString();
          } else {
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          }
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _initControllers();
      _isEditingInline = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditingInline ? 'Edit Book' : _currentBook.title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditingInline) ...[
            IconButton(
              icon: Icon(
                _currentBook.favorite ? Icons.star : Icons.star_border,
                color: _currentBook.favorite ? Colors.amber : Colors.white,
              ),
              onPressed: _toggleFavorite,
              tooltip: 'Favorite',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditingInline = true;
                });
              },
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteBook,
              tooltip: 'Delete',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: _isEditingInline ? _buildEditMode() : _buildViewMode(),
      ),
    );
  }

  /// Giao diện Chế độ Xem (View Mode)
  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentBook.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'by ${_currentBook.author}',
                    style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              iconSize: 32,
              icon: Icon(
                _currentBook.favorite ? Icons.star : Icons.star_border,
                color: _currentBook.favorite ? Colors.amber : Colors.grey,
              ),
              onPressed: _toggleFavorite,
            ),
          ],
        ),
        const Divider(height: 32),
        _buildInfoTile('Genre', _currentBook.genre, Icons.category_outlined),
        const SizedBox(height: 12),
        _buildInfoTile('Status', _currentBook.status, Icons.bookmark_outline),
        const SizedBox(height: 12),
        _buildInfoTile(
          'Rating',
          _currentBook.rating != null ? '${_currentBook.rating} / 5 ★' : 'No rating',
          Icons.star_half_outlined,
        ),
        const SizedBox(height: 12),
        _buildInfoTile(
          'Notes',
          _currentBook.notes != null && _currentBook.notes!.isNotEmpty
              ? _currentBook.notes!
              : 'No notes added.',
          Icons.note_alt_outlined,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditingInline = true;
                  });
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Book'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _deleteBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Giao diện Chế độ Chỉnh sửa (Edit Mode)
  Widget _buildEditMode() {
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Title is required';
              }
              if (value.trim().length > 100) {
                return 'Title must be at most 100 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _authorController,
            decoration: const InputDecoration(
              labelText: 'Author *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Author is required';
              }
              if (value.trim().length > 60) {
                return 'Author must be at most 60 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedGenre,
            decoration: const InputDecoration(
              labelText: 'Genre *',
              border: OutlineInputBorder(),
            ),
            items: _genreOptions.map((g) {
              return DropdownMenuItem(value: g, child: Text(g));
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedGenre = val;
              });
            },
            validator: (value) {
              if (value == null || value == 'Choose genre') {
                return 'Please choose a genre';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status *',
              border: OutlineInputBorder(),
            ),
            items: _statusOptions.map((s) {
              return DropdownMenuItem(value: s, child: Text(s));
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedStatus = val;
              });
            },
            validator: (value) {
              if (value == null || value == 'Choose status') {
                return 'Please choose a status';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ratingController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Rating (0 to 5, optional)',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final ratingVal = int.tryParse(value.trim());
                if (ratingVal == null || ratingVal < 0 || ratingVal > 5) {
                  return 'Rating must be a whole number from 0 to 5';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value != null && value.trim().length > 300) {
                return 'Notes must be at most 300 characters';
              }
              return null;
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _cancelEdit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
