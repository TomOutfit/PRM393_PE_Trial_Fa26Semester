import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';

class AddBookBottomSheet extends StatefulWidget {
  final BookModel? bookToEdit; // Nếu != null thì là chế độ Chỉnh sửa

  const AddBookBottomSheet({super.key, this.bookToEdit});

  @override
  State<AddBookBottomSheet> createState() => _AddBookBottomSheetState();
}

class _AddBookBottomSheetState extends State<AddBookBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bookService = BookService();

  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _ratingController;
  late final TextEditingController _notesController;

  String? _selectedGenre;
  String? _selectedStatus;

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _genreOptions = ['Choose genre', 'Fiction', 'Non-Fiction', 'Academic', 'Other'];
  final List<String> _statusOptions = ['Choose status', 'To Read', 'Reading', 'Finished'];

  @override
  void initState() {
    super.initState();
    final book = widget.bookToEdit;
    _titleController = TextEditingController(text: book?.title ?? '');
    _authorController = TextEditingController(text: book?.author ?? '');
    _ratingController = TextEditingController(text: book?.rating != null ? book!.rating.toString() : '');
    _notesController = TextEditingController(text: book?.notes ?? '');

    _selectedGenre = (book != null && _genreOptions.contains(book.genre))
        ? book.genre
        : 'Choose genre';

    _selectedStatus = (book != null && _statusOptions.contains(book.status))
        ? book.status
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

  Future<void> _submitForm() async {
    setState(() {
      _autovalidateMode = AutovalidateMode.always;
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isSubmitting = true;
    });

    final ratingInt = _ratingController.text.trim().isNotEmpty
        ? int.tryParse(_ratingController.text.trim())
        : null;

    final newBook = BookModel(
      id: widget.bookToEdit?.id ?? '',
      userId: currentUser.uid,
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      genre: _selectedGenre!,
      status: _selectedStatus!,
      rating: ratingInt,
      favorite: widget.bookToEdit?.favorite ?? false,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: widget.bookToEdit?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.bookToEdit == null) {
        await _bookService.addBook(newBook);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Book added'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        await _bookService.updateBook(newBook);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Book updated'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, newBook);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is FirebaseException) {
            _errorMessage = e.message ?? e.toString();
          } else {
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          }
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.bookToEdit == null ? 'Add a book' : 'Edit book',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              // Title Field
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
              // Author Field
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
              // Genre Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedGenre,
                decoration: const InputDecoration(
                  labelText: 'Genre *',
                  border: OutlineInputBorder(),
                ),
                items: _genreOptions.map((genre) {
                  return DropdownMenuItem<String>(
                    value: genre,
                    child: Text(genre),
                  );
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
              // Status Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status *',
                  border: OutlineInputBorder(),
                ),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
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
              // Rating Field (Optional)
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
              // Notes Field (Optional)
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
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.bookToEdit == null ? 'Save Book' : 'Save Changes',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
