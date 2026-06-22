import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'admin_ticket_detail_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> with SingleTickerProviderStateMixin {
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard => Theme.of(context).cardColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).dividerColor;
  static const Color _danger = Color(0xFFF87171);

  final _api = ApiService();
  List<dynamic> _allTickets = [];
  List<dynamic> _filteredTickets = [];
  bool _isLoading = true;
  String _searchQuery = '';
  late TabController _tabController;

  int _page = 1;
  bool _hasMore = true;
  bool _isLoadMore = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  // Dynamic Contact support variables
  List<dynamic> _contacts = [];
  bool _isSavingContacts = false;
  String? _editingId;

  // Controllers for adding
  final _newTitleCtrl = TextEditingController();
  final _newUrlCtrl = TextEditingController();
  String _newPlatform = 'LINK';

  // Controllers for editing
  final _editTitleCtrl = TextEditingController();
  final _editUrlCtrl = TextEditingController();
  String _editPlatform = 'LINK';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);
    _scrollController.addListener(_scrollListener);
    _fetchTickets();
    _fetchSupportContacts();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _tabController.dispose();
    _newTitleCtrl.dispose();
    _newUrlCtrl.dispose();
    _editTitleCtrl.dispose();
    _editUrlCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoadMore && !_isLoading) {
        _fetchMoreTickets();
      }
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    setState(() {}); // Trigger rebuild to switch view
    if (_tabController.index < 4) {
      _fetchTickets();
    }
  }

  String? _getTabStatus(int tabIndex) {
    if (tabIndex == 1) return 'OPEN';
    if (tabIndex == 2) return 'RESOLVED';
    if (tabIndex == 3) return 'UNRESOLVED';
    return null;
  }

  Future<void> _fetchTickets({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    _page = 1;
    _hasMore = true;

    final String? status = _getTabStatus(_tabController.index);
    final String query = _searchQuery.trim();

    final Map<String, String> queryParams = {
      'page': '1',
      'limit': '10',
    };
    if (status != null) {
      queryParams['status'] = status;
    }
    if (query.isNotEmpty) {
      queryParams['search'] = query;
    }

    final String queryString = Uri(queryParameters: queryParams).query;
    final String url = '/tickets?$queryString';

    try {
      final res = await _api.getRequest(url);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _allTickets = data;
          _filteredTickets = data;
          _isLoading = false;
          if (data.length < 10) {
            _hasMore = false;
          }
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSupportContacts() async {
    try {
      final res = await _api.getRequest('/settings/support-contacts');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _contacts = data is List ? data : [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching support contacts: $e');
    }
  }

  Future<void> _createSupportContact() async {
    final title = _newTitleCtrl.text.trim();
    final url = _newUrlCtrl.text.trim();
    if (title.isEmpty || url.isEmpty) return;

    setState(() => _isSavingContacts = true);
    try {
      final res = await _api.postRequest('/settings/admin/support-contacts', {
        'title': title,
        'platform': _newPlatform,
        'url': url,
      });
      if (res.statusCode == 201 || res.statusCode == 200) {
        _newTitleCtrl.clear();
        _newUrlCtrl.clear();
        setState(() {
          _newPlatform = 'LINK';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Support channel created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _fetchSupportContacts();
      } else {
        throw Exception('Failed to create. Status code: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating support channel: $e'),
            backgroundColor: _danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingContacts = false);
      }
    }
  }

  Future<void> _updateSupportContact(String id) async {
    final title = _editTitleCtrl.text.trim();
    final url = _editUrlCtrl.text.trim();
    if (title.isEmpty || url.isEmpty) return;

    setState(() => _isSavingContacts = true);
    try {
      final res = await _api.patchRequest('/settings/admin/support-contacts/$id', {
        'title': title,
        'platform': _editPlatform,
        'url': url,
      });
      if (res.statusCode == 200) {
        setState(() {
          _editingId = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Support channel updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _fetchSupportContacts();
      } else {
        throw Exception('Failed to update. Status code: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating support channel: $e'),
            backgroundColor: _danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingContacts = false);
      }
    }
  }

  Future<void> _deleteSupportContact(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _bgCard,
        title: Text('Delete Channel', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text('Are you sure you want to delete this support channel?', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _primary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _danger),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSavingContacts = true);
    try {
      final res = await _api.deleteRequest('/settings/admin/support-contacts/$id');
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Support channel deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _fetchSupportContacts();
      } else {
        throw Exception('Failed to delete. Status code: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting support channel: $e'),
            backgroundColor: _danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingContacts = false);
      }
    }
  }

  Future<void> _fetchMoreTickets() async {
    if (!mounted) return;
    setState(() => _isLoadMore = true);
    final nextPage = _page + 1;

    final String? status = _getTabStatus(_tabController.index);
    final String query = _searchQuery.trim();

    final Map<String, String> queryParams = {
      'page': nextPage.toString(),
      'limit': '10',
    };
    if (status != null) {
      queryParams['status'] = status;
    }
    if (query.isNotEmpty) {
      queryParams['search'] = query;
    }

    final String queryString = Uri(queryParameters: queryParams).query;
    final String url = '/tickets?$queryString';

    try {
      final res = await _api.getRequest(url);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _page = nextPage;
            _allTickets.addAll(data);
            _filteredTickets = _allTickets;
            _isLoadMore = false;
            if (data.length < 10) {
              _hasMore = false;
            }
          });
        }
      } else {
        if (mounted) setState(() => _isLoadMore = false);
      }
    } catch (e) {
      debugPrint('Error fetching more tickets: $e');
      if (mounted) setState(() => _isLoadMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showContactsForm = _tabController.index == 4;

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Ticketing Dashboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(showContactsForm ? 60 : 100),
          child: Column(
            children: [
              if (!showContactsForm)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: TextField(
                      onChanged: (v) {
                        setState(() => _searchQuery = v);
                        if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
                        _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                          _fetchTickets();
                        });
                      },
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Search email, subject or ticket #',
                        hintStyle: TextStyle(
                          color: _textDim.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(Icons.search, color: _primary, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              TabBar(
                controller: _tabController,
                indicatorColor: _primary,
                labelColor: _primary,
                unselectedLabelColor: _textDim,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Open'),
                  Tab(text: 'Resolved'),
                  Tab(text: 'Cannot'),
                  Tab(text: 'Contacts'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : showContactsForm
              ? _buildContactsForm()
              : RefreshIndicator(
                  onRefresh: () => _fetchTickets(silent: true),
                  color: _primary,
                  child: _filteredTickets.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 60),
                          itemCount: _filteredTickets.length + (_isLoadMore ? 1 : 0),
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index == _filteredTickets.length) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: CircularProgressIndicator(color: _primary),
                                ),
                              );
                            }
                            final ticket = _filteredTickets[index];
                            final readableId = ticket['readableId'] ?? '';
                            final subject = ticket['subject'] ?? '';
                            final status = ticket['status'] ?? 'OPEN';
                            final user = ticket['user'] ?? {};
                            final email = user['email'] ?? 'Unknown User';
                            final date = DateTime.parse(ticket['updatedAt'] ?? ticket['createdAt']);

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminTicketDetailScreen(ticketId: ticket['id']),
                                  ),
                                ).then((_) => _fetchTickets(silent: true));
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: _bgCard,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Ticket #$readableId',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _textDim,
                                          ),
                                        ),
                                        _buildStatusBadge(status),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      subject,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Divider(height: 1, color: _border),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'RAISED BY',
                                                style: GoogleFonts.inter(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: _textDim,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                email,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'LAST UPDATED',
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: _textDim,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormat('MMM d, hh:mm a').format(date),
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }

  Widget _buildContactsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Channels Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support Channels Configuration',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Setup direct social media handles and custom support links for user redirection.',
                  style: TextStyle(color: _textDim, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Text(
                  'ACTIVE SUPPORT CHANNELS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                _contacts.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No support channels configured.',
                            style: GoogleFonts.inter(
                              color: _textDim,
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _contacts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final c = _contacts[index];
                          final id = c['id'].toString();
                          final isEditing = _editingId == id;

                          if (isEditing) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _bgDark.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _primary.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFormTextField(
                                    controller: _editTitleCtrl,
                                    label: 'TITLE',
                                    hint: 'e.g. Helpdesk',
                                    icon: Icons.title,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'PLATFORM',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _primary,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: _bgDark.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _border),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _editPlatform,
                                        dropdownColor: _bgCard,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        isExpanded: true,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'TELEGRAM',
                                            child: Text('Telegram'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'WHATSAPP',
                                            child: Text('WhatsApp'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'LINK',
                                            child: Text('General Link'),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _editPlatform = val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildFormTextField(
                                    controller: _editUrlCtrl,
                                    label: 'ADDRESS / URL',
                                    hint: 'Username, phone or URL link',
                                    icon: Icons.link,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 40,
                                          child: ElevatedButton(
                                            onPressed: _isSavingContacts ? null : () => _updateSupportContact(id),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _primary,
                                              foregroundColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: SizedBox(
                                          height: 40,
                                          child: OutlinedButton(
                                            onPressed: () => setState(() => _editingId = null),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: _border),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }

                          final title = c['title'] ?? '';
                          final platform = c['platform'] ?? 'LINK';
                          final url = c['url'] ?? '';

                          Color badgeColor;
                          Color badgeBg;
                          IconData platformIcon;

                          if (platform == 'TELEGRAM') {
                            badgeColor = Colors.blue;
                            badgeBg = Colors.blue.withValues(alpha: 0.1);
                            platformIcon = Icons.telegram;
                          } else if (platform == 'WHATSAPP') {
                            badgeColor = Colors.green;
                            badgeBg = Colors.green.withValues(alpha: 0.1);
                            platformIcon = Icons.phone_iphone_rounded;
                          } else {
                            badgeColor = _primary;
                            badgeBg = _primary.withValues(alpha: 0.1);
                            platformIcon = Icons.link_rounded;
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _bgDark.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _border),
                            ),
                            child: Row(
                              children: [
                                Icon(platformIcon, color: badgeColor, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: badgeBg,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                                            ),
                                            child: Text(
                                              platform,
                                              style: GoogleFonts.inter(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: badgeColor,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        url,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: _textDim,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, color: _primary, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _editingId = id;
                                      _editTitleCtrl.text = title;
                                      _editUrlCtrl.text = url;
                                      _editPlatform = platform;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: _danger, size: 20),
                                  onPressed: () => _deleteSupportContact(id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Create Section Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: _primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Create Support Channel',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildFormTextField(
                  controller: _newTitleCtrl,
                  label: 'TITLE',
                  hint: 'e.g. Telegram Support',
                  icon: Icons.label_outline_rounded,
                ),
                const SizedBox(height: 20),
                Text(
                  'PLATFORM',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _bgDark.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _newPlatform,
                      dropdownColor: _bgCard,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'TELEGRAM',
                          child: Text('Telegram'),
                        ),
                        DropdownMenuItem(
                          value: 'WHATSAPP',
                          child: Text('WhatsApp'),
                        ),
                        DropdownMenuItem(
                          value: 'LINK',
                          child: Text('General Link'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _newPlatform = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildFormTextField(
                  controller: _newUrlCtrl,
                  label: 'REDIRECT ADDRESS / HANDLE',
                  hint: 'e.g. @username or +91XXXXXXXXXX or https://...',
                  icon: Icons.link_rounded,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSavingContacts ? null : _createSupportContact,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSavingContacts
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Add New Channel',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: _primary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _textDim.withValues(alpha: 0.4),
              fontSize: 15,
            ),
            prefixIcon: Icon(icon, color: _primary),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primary, width: 2),
            ),
            filled: true,
            fillColor: _bgDark.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'OPEN':
        bg = _primary.withValues(alpha: 0.08);
        fg = _primary;
        break;
      case 'RESOLVED':
        bg = Colors.green.withValues(alpha: 0.08);
        fg = Colors.green;
        break;
      case 'UNRESOLVED':
        bg = _danger.withValues(alpha: 0.08);
        fg = _danger;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.08);
        fg = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Text(
        status == 'UNRESOLVED' ? 'CANNOT RESOLVE' : status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_chat_read_outlined,
                size: 36,
                color: _primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Tickets Found',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No support tickets match the current search or filter criteria.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _textDim,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
