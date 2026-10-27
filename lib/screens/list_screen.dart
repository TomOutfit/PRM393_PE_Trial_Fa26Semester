import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../services/auth_service.dart';
import '../services/book_service.dart';
import '../widgets/add_book_bottom_sheet.dart';
import 'detail_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final AuthService _authService = AuthService();
  final BookService _bookService = BookService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedGenreFilter = 'All';
  String _selectedStatusFilter = 'All';
  bool _favoritesOnly = false;
  String _searchQuery = '';

  final List<String> _genreFilterOptions = ['All', 'Fiction', 'Non-Fiction', 'Academic', 'Other'];
  final List<String> _statusFilterOptions = ['All', 'To Read', 'Reading', 'Finished'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedGenreFilter = 'All';
      _selectedStatusFilter = 'All';
      _favoritesOnly = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _showAddBookBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const AddBookBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return PopScope(
      canPop: false, // Ngăn bấm nút Back quay lại form Login/Register
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            currentUser?.email ?? 'BookShelf',
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false, // Bỏ nút back
          actions: [
            TextButton.icon(
              onPressed: () async {
                await _authService.signOut();
              },
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: currentUser == null
            ? const Center(child: Text('User not authenticated'))
            : StreamBuilder<List<BookModel>>(
                stream: _bookService.getBooksStream(currentUser.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading books: ${snapshot.error}'),
                    );
                  }

                  final allBooks = snapshot.data ?? [];

                  // Lọc sách theo 4 tiêu chí: Genre, Status, Favorites, Search
                  final filteredBooks = allBooks.where((book) {
                    // Lọc Genre
                    if (_selectedGenreFilter != 'All' && book.genre != _selectedGenreFilter) {
                      return false;
                    }
                    // Lọc Status
                    if (_selectedStatusFilter != 'All' && book.status != _selectedStatusFilter) {
                      return false;
                    }
                    // Lọc Favorites Only
                    if (_favoritesOnly && !book.favorite) {
                      return false;
                    }
                    // Lọc Search (Title hoặc Author)
                    if (_searchQuery.trim().isNotEmpty) {
                      final q = _searchQuery.trim().toLowerCase();
                      final matchTitle = book.title.toLowerCase().contains(q);
                      final matchAuthor = book.author.toLowerCase().contains(q);
                      if (!matchTitle && !matchAuthor) {
                        return false;
                      }
                    }
                    return true;
                  }).toList();

                  return Column(
                    children: [
                      // Vùng Bộ lọc, Tìm kiếm và Nút Clear
                      _buildFilterAndSearchSection(),
                      // Vùng Tổng quan Summary
                      _buildSummarySection(filteredBooks),
                      const Divider(height: 1),
                      // Vùng Hiển thị Danh sách Sách
                      Expanded(
                        child: filteredBooks.isEmpty
                            ? const Center(
                                child: Text(
                                  'No books found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: filteredBooks.length,
                                itemBuilder: (context, index) {
                                  final book = filteredBooks[index];
                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    child: ListTile(
                                      title: Text(
                                        book.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 2),
                                          Text('Author: ${book.author}'),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.deepPurple.shade50,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  book.genre,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.deepPurple,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade50,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  book.status,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.amber.shade900,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          book.favorite ? Icons.star : Icons.star_border,
                                          color: book.favorite ? Colors.amber : Colors.grey,
                                        ),
                                        onPressed: () {
                                          _bookService.toggleFavorite(book.id, book.favorite);
                                        },
                                        tooltip: 'Toggle favorite',
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DetailScreen(book: book),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddBookBottomSheet,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          tooltip: 'Add Book',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  /// Widget hiển thị Thanh tìm kiếm, dropdown Genre, Status, switch Favorites và nút Clear
  Widget _buildFilterAndSearchSection() {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Search box
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search title or author...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Genre Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _selectedGenreFilter,
                  decoration: const InputDecoration(
                    labelText: 'Genre',
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _genreFilterOptions.map((g) {
                    return DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedGenreFilter = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Status Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _selectedStatusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _statusFilterOptions.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatusFilter = val;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // Favorites Only Switch
              FilterChip(
                label: const Text('Favorites Only'),
                selected: _favoritesOnly,
                avatar: Icon(
                  _favoritesOnly ? Icons.star : Icons.star_border,
                  color: _favoritesOnly ? Colors.amber : Colors.grey,
                  size: 18,
                ),
                onSelected: (selected) {
                  setState(() {
                    _favoritesOnly = selected;
                  });
                },
              ),
              const Spacer(),
              // Clear Button
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget tổng quan mô tả số lượng sách, số lượng yêu thích và phân bổ theo Status
  Widget _buildSummarySection(List<BookModel> books) {
    final int totalCount = books.length;
    final int favCount = books.where((b) => b.favorite).length;

    // Đếm theo từng status
    final Map<String, int> statusCounts = {};
    for (var book in books) {
      statusCounts[book.status] = (statusCounts[book.status] ?? 0) + 1;
    }

    // Sắp xếp các status xuất hiện: số lượng nhiều nhất xếp trước
    // Nếu bằng nhau: To Read -> Reading -> Finished
    final constOrder = ['To Read', 'Reading', 'Finished'];
    final statusEntries = statusCounts.entries.where((e) => e.value > 0).toList();

    statusEntries.sort((a, b) {
      int countCompare = b.value.compareTo(a.value);
      if (countCompare != 0) return countCompare;
      int orderA = constOrder.indexOf(a.key);
      int orderB = constOrder.indexOf(b.key);
      if (orderA == -1) orderA = 99;
      if (orderB == -1) orderB = 99;
      return orderA.compareTo(orderB);
    });

    return Container(
      width: double.infinity,
      color: Colors.deepPurple.shade50.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Books: $totalCount',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 24),
              Text(
                'Favorites: $favCount',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber),
              ),
            ],
          ),
          if (statusEntries.isNotEmpty) ...[
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: statusEntries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '${e.key}: ${e.value}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
