import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

class LiveTimerWidget extends StatefulWidget {
  final DateTime expiresAt;
  const LiveTimerWidget({super.key, required this.expiresAt});

  @override
  State<LiveTimerWidget> createState() => _LiveTimerWidgetState();
}

class _LiveTimerWidgetState extends State<LiveTimerWidget> {
  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color get _blue => Colors.blue;
  Color get _danger => Color(0xFFF87171);

  Timer? _timer;
  late int _timeLeft;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _startTimer();
  }

  @override
  void didUpdateWidget(LiveTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _calculateTimeLeft();
    }
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    _timeLeft = widget.expiresAt.difference(now).inSeconds;
    if (_timeLeft < 0) _timeLeft = 0;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTimeLeft();
          if (_timeLeft <= 0) {
            _timer?.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _timerColor() {
    if (_timeLeft <= 0) return _danger;
    if (_timeLeft < 60) return Colors.redAccent;
    if (_timeLeft < 300) return Colors.orangeAccent;
    return _blue;
  }

  @override
  Widget build(BuildContext context) {
    final color = _timerColor();
    final isExpired = _timeLeft <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isExpired ? 'EXPIRED' : '${_formatTime(_timeLeft)} LEFT',
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard => Theme.of(context).cardColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).dividerColor;

  final _api = ApiService();
  List<dynamic> _assignments = [];
  bool _isLoading = true;

  // Filter State
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedStatus = 'All';

  List<dynamic> get _filteredAssignments {
    return _assignments.where((a) {
      final user = a['user'];
      if (user == null) return false;

      final firstName = user['firstName']?.toString().toLowerCase() ?? '';
      final lastName = user['lastName']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      final query = (_searchQuery).toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          firstName.contains(query) ||
          lastName.contains(query) ||
          email.contains(query);

      final expiresAtStr = a['expiresAt']?.toString() ?? '';
      bool isExpired = false;
      if (expiresAtStr.isNotEmpty) {
        final expiresAt = DateTime.tryParse(expiresAtStr);
        if (expiresAt != null) {
          isExpired = expiresAt.isBefore(DateTime.now());
        }
      }

      final matchesStatus =
          _selectedStatus == 'All' ||
          (_selectedStatus == 'Active' && !isExpired) ||
          (_selectedStatus == 'Expired' && isExpired);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getRequest('/settings/admin/assignments');
      if (res.statusCode == 200) {
        if (mounted) setState(() => _assignments = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Views',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedStatus = 'All';
                      });
                      setLocalState(() {});
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildFilterLabel('Assignment Status'),
              _buildFilterOptions(
                ['All', 'Active', 'Expired'],
                _selectedStatus,
                (val) {
                  setState(() => _selectedStatus = val);
                  setLocalState(() {});
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: _textDim,
        ),
      ),
    );
  }

  Widget _buildFilterOptions(
    List<String> options,
    String current,
    Function(String) onSelected,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isActive = opt == current;
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? _primary : _bgDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isActive ? _primary : _border),
            ),
            child: Text(
              opt,
              style: TextStyle(
                color: isActive ? Colors.black : _textDim,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isSearching && _searchQuery.isEmpty) {
          setState(() => _isSearching = false);
        }
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: _bgDark,
        body: RefreshIndicator(
          onRefresh: _fetchAssignments,
          color: _primary,
          backgroundColor: _bgCard,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: _bgDark.withValues(alpha: 0.95),
                elevation: 0,
                titleSpacing: 0,
                leading: (_isSearching)
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        onPressed: () => setState(() {
                          _isSearching = false;
                          _searchQuery = '';
                        }),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                title: (_isSearching)
                    ? TextField(
                        autofocus: true,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by name or email...',
                          hintStyle: TextStyle(
                            color: _textDim.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                        ),
                      )
                    : Text(
                        'Live QR Views',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                        ),
                      ),
                actions: [
                  if (!_isSearching)
                    IconButton(
                      icon: Icon(Icons.search, size: 22, color: _textDim),
                      onPressed: () => setState(() => _isSearching = true),
                    ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.more_vert, size: 22, color: _textDim),
                        onPressed: _showFilterSheet,
                      ),
                      if (_searchQuery.isNotEmpty || _selectedStatus != 'All')
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: _bgDark, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: _border),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                sliver: _isLoading
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 100),
                            child: CircularProgressIndicator(color: _primary),
                          ),
                        ),
                      )
                    : _filteredAssignments.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 80),
                              Icon(
                                _searchQuery.isNotEmpty ||
                                        _selectedStatus != 'All'
                                    ? Icons.search_off_rounded
                                    : Icons.qr_code_scanner,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.05),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty ||
                                        _selectedStatus != 'All'
                                    ? 'No matching views found'
                                    : 'No active QR views matching users',
                                style: TextStyle(color: _textDim, fontSize: 14),
                              ),
                              if (_searchQuery.isNotEmpty ||
                                  _selectedStatus != 'All')
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedStatus = 'All';
                                    });
                                  },
                                  child: Text(
                                    'Clear all filters',
                                    style: TextStyle(color: _primary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((ctx, i) {
                          final a = _filteredAssignments[i];
                          return _buildAssignmentCard(a);
                        }, childCount: _filteredAssignments.length),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(dynamic a) {
    final user = a['user'];
    final wallet = a['wallet'];
    final expiresAt = DateTime.tryParse(a['expiresAt'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      (user['firstName'] ?? user['email'] ?? '?')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (user['firstName'] != null || user['lastName'] != null)
                            ? '${user['firstName']} ${user['lastName']}'.trim()
                            : user['email'],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        user['email'],
                        style: TextStyle(color: _textDim, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (expiresAt != null) LiveTimerWidget(expiresAt: expiresAt),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: _border, height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ASSIGNED WALLET',
                  style: TextStyle(
                    color: _textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  wallet['name']?.toString().toUpperCase() ?? wallet['network'],
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ADDRESS',
                  style: TextStyle(
                    color: _textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Flexible(
                  child: Text(
                    wallet['address'],
                    style: GoogleFonts.firaCode(
                      color: _primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'OPENED AT',
                  style: TextStyle(
                    color: _textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  a['createdAt'] != null
                      ? DateFormat('MMM d, HH:mm').format(DateTime.parse(a['createdAt']))
                      : 'UNKNOWN',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
