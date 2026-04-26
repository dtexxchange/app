import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final _api = ApiService();
  List<dynamic> _newsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getRequest('/news/admin');
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _newsList = jsonDecode(res.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) _showSnack('Failed to fetch news');
      }
    } catch (e) {
      if (mounted) _showSnack('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createNews(String title, String description, String? link) async {
    try {
      final res = await _api.postRequest('/news', {
        'title': title,
        'description': description,
        if (link != null && link.isNotEmpty) 'link': link,
      });
      if (res.statusCode == 201) {
        _showSnack('News created successfully', success: true);
        _fetchNews();
      } else {
        _showSnack('Failed to create news');
      }
    } catch (e) {
      _showSnack('Error: ${e.toString()}');
    }
  }

  Future<void> _updateNews(String id, String title, String description, String? link, String status) async {
    try {
      final res = await _api.patchRequest('/news/$id', {
        'title': title,
        'description': description,
        'link': link ?? '',
        'status': status,
      });
      if (res.statusCode == 200) {
        _showSnack('News updated successfully', success: true);
        _fetchNews();
      } else {
        _showSnack('Failed to update news');
      }
    } catch (e) {
      _showSnack('Error: ${e.toString()}');
    }
  }

  Future<void> _toggleStatus(String id, String currentStatus) async {
    final newStatus = currentStatus == 'PUBLISHED' ? 'ARCHIVED' : 'PUBLISHED';
    try {
      final res = await _api.patchRequest('/news/$id', {'status': newStatus});
      if (res.statusCode == 200) {
        _showSnack(
          newStatus == 'PUBLISHED' ? 'News Published' : 'News Archived',
          success: true,
        );
        _fetchNews();
      } else {
        _showSnack('Failed to update status');
      }
    } catch (e) {
      _showSnack('Error: ${e.toString()}');
    }
  }

  Future<void> _deleteNews(String id) async {
    try {
      final res = await _api.deleteRequest('/news/$id');
      if (res.statusCode == 200) {
        _showSnack('News deleted successfully', success: true);
        _fetchNews();
      } else {
        _showSnack('Failed to delete news');
      }
    } catch (e) {
      _showSnack('Error: ${e.toString()}');
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: success ? Theme.of(context).primaryColor : const Color(0xFFF87171),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showNewsDialog({Map<String, dynamic>? news}) {
    final titleController = TextEditingController(text: news?['title'] ?? '');
    final descController = TextEditingController(text: news?['description'] ?? '');
    final linkController = TextEditingController(text: news?['link'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final primary = Theme.of(context).primaryColor;
        final bgCard = Theme.of(context).cardColor;
        final bgDark = Theme.of(context).scaffoldBackgroundColor;
        final textDim = Theme.of(context).colorScheme.onSurfaceVariant;

        return AlertDialog(
          backgroundColor: bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            news == null ? 'Create News' : 'Edit News',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TITLE',
                    style: TextStyle(
                      color: primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: titleController,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Enter news title',
                      filled: true,
                      fillColor: bgDark.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      color: primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter news description',
                      filled: true,
                      fillColor: bgDark.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'LINK (OPTIONAL)',
                    style: TextStyle(
                      color: primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: linkController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. https://example.com',
                      filled: true,
                      fillColor: bgDark.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: textDim, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final title = titleController.text.trim();
                  final desc = descController.text.trim();
                  final link = linkController.text.trim();
                  
                  if (news == null) {
                    _createNews(title, desc, link);
                  } else {
                    _updateNews(news['id'], title, desc, link, news['status']);
                  }
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(news == null ? 'Create' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Delete News', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this news item? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteNews(id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF87171), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final bgDark = Theme.of(context).scaffoldBackgroundColor;
    final bgCard = Theme.of(context).cardColor;
    final textDim = Theme.of(context).colorScheme.onSurfaceVariant;
    final border = Theme.of(context).dividerColor;

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        title: Text(
          'Manage News',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNews,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 4,
        onPressed: () => _showNewsDialog(),
        child: const Icon(Icons.add, size: 28),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : _newsList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.newspaper_outlined, size: 64, color: textDim.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No news found',
                        style: GoogleFonts.outfit(fontSize: 18, color: textDim, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to create a news item',
                        style: TextStyle(color: textDim, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _newsList.length,
                  itemBuilder: (context, index) {
                    final news = _newsList[index];
                    final isPublished = news['status'] == 'PUBLISHED';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPublished
                                      ? primary.withValues(alpha: 0.1)
                                      : textDim.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isPublished ? 'PUBLISHED' : 'ARCHIVED',
                                  style: TextStyle(
                                    color: isPublished ? primary : textDim,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                color: textDim,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () => _showNewsDialog(news: news),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                color: const Color(0xFFF87171),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () => _confirmDelete(news['id']),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            news['title'] ?? '',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            news['description'] ?? '',
                            style: TextStyle(color: textDim, fontSize: 14, height: 1.4),
                          ),
                          if (news['link'] != null && (news['link'] as String).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.link, size: 16, color: primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    news['link'],
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _toggleStatus(news['id'], news['status']),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: isPublished ? const Color(0xFFF87171) : primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: Icon(
                                isPublished ? Icons.archive_outlined : Icons.unarchive_outlined,
                                color: isPublished ? const Color(0xFFF87171) : primary,
                                size: 18,
                              ),
                              label: Text(
                                isPublished ? 'Archive News' : 'Publish News',
                                style: TextStyle(
                                  color: isPublished ? const Color(0xFFF87171) : primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
