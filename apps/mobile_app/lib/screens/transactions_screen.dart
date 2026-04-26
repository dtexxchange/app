import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../main.dart' show routeObserver;
import '../services/api_service.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => TransactionsScreenState();
}

// State exposed so MainScreen can refresh via GlobalKey<TransactionsScreenState>.
class TransactionsScreenState extends State<TransactionsScreen>
    with RouteAware {
  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard => Theme.of(context).cardColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).dividerColor;
  static const Color _blue = Color(0xFF3B82F6);

  /// Number of items to fetch per page.
  static const _pageSize = 15;
  List _transactions = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _page = 1;

  String _filterType = '';
  String _filterStatus = '';

  final _api = ApiService();
  final _scrollController = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  String _searchQuery = '';
  int _currentTypeTab = 0;
  final List<String> _typeTabs = ['All', 'Deposits', 'Exchanges', 'Withdrawals', 'Referral'];

  @override
  void initState() {
    super.initState();
    _fetchPage(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  /// Refresh when navigated back to from another screen.
  @override
  void didPopNext() {
    _fetchPage(reset: true);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _scrollController.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  /// Public so MainScreen can trigger a reset via GlobalKey.
  Future<void> fetchPage({bool reset = false}) => _fetchPage(reset: reset);

  Future<void> _fetchPage({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _page = 1;
        _hasMore = true;
        _transactions = [];
      });
    }

    try {
      // Increase limit to allow better local filtering/search like the admin app
      final effectiveLimit = _isSearching || _currentTypeTab != 0 ? 100 : _pageSize;
      
      final params = <String, String>{'page': '1', 'limit': '$effectiveLimit'};
      if (_filterType.isNotEmpty) params['type'] = _filterType;
      if (_filterStatus.isNotEmpty) params['status'] = _filterStatus;

      final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final res = await _api.getRequest('/wallet/transactions?$query');

      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _transactions = data;
          _page = 2;
          _hasMore = data.length >= effectiveLimit;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List get _filteredTransactions {
    List filtered = List.from(_transactions);

    // Filter by type tab
    if (_currentTypeTab != 0) {
      final tabType = _typeTabs[_currentTypeTab].toUpperCase();
      if (tabType == 'DEPOSITS') {
        filtered = filtered.where((tx) => tx['type'] == 'DEPOSIT').toList();
      } else if (tabType == 'EXCHANGES') {
        filtered = filtered.where((tx) => tx['type'] == 'EXCHANGE').toList();
      } else if (tabType == 'WITHDRAWALS') {
        filtered = filtered.where((tx) => tx['type'] == 'WITHDRAWAL').toList();
      } else if (tabType == 'REFERRAL') {
        filtered = filtered.where((tx) => tx['type'] == 'REFERRAL_COMMISSION').toList();
      }
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((tx) {
        final txId = tx['id']?.toString().toLowerCase() ?? '';
        final readableId = tx['readableId']?.toString().toLowerCase() ?? '';
        final type = tx['type']?.toString().toLowerCase() ?? '';
        final amount = tx['amount']?.toString() ?? '';
        return txId.contains(q) || readableId.contains(q) || type.contains(q) || amount.contains(q);
      }).toList();
    }

    return filtered;
  }

  Future<void> _loadMore() async {
    if (_isFetchingMore || !_hasMore || _isLoading) return;
    setState(() => _isFetchingMore = true);

    try {
      final effectiveLimit = _isSearching || _currentTypeTab != 0 ? 100 : _pageSize;
      final params = <String, String>{'page': '$_page', 'limit': '$effectiveLimit'};
      if (_filterType.isNotEmpty) params['type'] = _filterType;
      if (_filterStatus.isNotEmpty) params['status'] = _filterStatus;

      final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final res = await _api.getRequest('/wallet/transactions?$query');

      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _transactions = [..._transactions, ...data];
          _page++;
          _hasMore = data.length >= effectiveLimit;
          _isFetchingMore = false;
        });
      } else if (mounted) {
        setState(() => _isFetchingMore = false);
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) setState(() => _isFetchingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final widthScale = (MediaQuery.of(context).size.width / 375.0).clamp(0.85, 1.2);
    final displayTxs = _filteredTransactions;

    return Scaffold(
      backgroundColor: _bgDark,
      body: Column(
        children: [
          _buildTopBar(widthScale),
          _buildTypeTabs(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchPage(reset: true),
              color: _primary,
              backgroundColor: _bgCard,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: _primary))
                  : displayTxs.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            _buildEmptyState(),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                          itemCount: displayTxs.length + (_isFetchingMore || _hasMore ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i < displayTxs.length) {
                              return _buildTxTile(displayTxs[i]);
                            }
                            
                            // Load-more indicator or end-of-list footer
                            if (_isFetchingMore) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: CircularProgressIndicator(
                                    color: _primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            
                            if (!_hasMore && displayTxs.isNotEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Text(
                                    '— All transactions loaded —',
                                    style: TextStyle(
                                      color: _textDim.withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                            return const SizedBox.shrink();
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(double widthScale) {
    return Container(
      decoration: BoxDecoration(
        color: _bgDark.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24 * widthScale, 8, 24 * widthScale, 12),
          child: Row(
            children: [
              if (_isSearching)
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchCtrl.clear();
                  }),
                )
              else ...[
                Icon(Icons.receipt_long, color: _primary, size: 22),
                const SizedBox(width: 12),
                Text(
                  'History',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],

              if (_isSearching) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: (v) {
                      if (_debounce?.isActive ?? false) _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        setState(() => _searchQuery = v);
                      });
                    },
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search history...',
                      hintStyle: TextStyle(
                        color: _textDim.withValues(alpha: 0.5),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ] else
                const Spacer(),

              if (!_isSearching)
                IconButton(
                  icon: Icon(Icons.search, color: _textDim, size: 22),
                  onPressed: () => setState(() => _isSearching = true),
                ),
              
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.filter_list, color: _textDim, size: 22),
                    onPressed: _showStatusFilterSheet,
                  ),
                  if (_filterStatus.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _typeTabs.length,
        itemBuilder: (context, index) {
          final isSelected = _currentTypeTab == index;
          return GestureDetector(
            onTap: () {
              setState(() => _currentTypeTab = index);
              // Optionally fetch more if switching tabs and list is small
              if (_transactions.length < 50) _fetchPage();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? _primary : _bgCard,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? _primary : _border,
                ),
              ),
              child: Text(
                _typeTabs[index],
                style: TextStyle(
                  color: isSelected ? Colors.black : _textDim,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showStatusFilterSheet() {
    final options = {
      '': 'All Status',
      'PENDING': 'Pending Only',
      'COMPLETED': 'Completed Only',
      'REJECTED': 'Rejected Only',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _textDim.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Filter by Status',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...options.entries.map(
              (e) => ListTile(
                title: Text(
                  e.value,
                  style: TextStyle(
                    color: _filterStatus == e.key ? _primary : null,
                    fontWeight: _filterStatus == e.key ? FontWeight.bold : null,
                  ),
                ),
                trailing: _filterStatus == e.key
                    ? Icon(Icons.check_circle, color: _primary, size: 20)
                    : null,
                onTap: () {
                  setState(() => _filterStatus = e.key);
                  _fetchPage(reset: true);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.show_chart,
          size: 56,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.08),
        ),
        const SizedBox(height: 16),
        Text(
          'No transactions found',
          style: TextStyle(
            color: _textDim,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildTxTile(Map<String, dynamic> tx) {
    final isDeposit = tx['type'] == 'DEPOSIT';
    final isCommission = tx['type'] == 'REFERRAL_COMMISSION';
    final isIncome = isDeposit || isCommission;
    final status = tx['status'] as String;

    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    if (status == 'COMPLETED') {
      statusColor = _primary;
      statusBg = _primary.withValues(alpha: 0.08);
      statusIcon = Icons.check_circle_outline;
    } else if (status == 'PENDING') {
      statusColor = _blue;
      statusBg = _blue.withValues(alpha: 0.08);
      statusIcon = Icons.access_time;
    } else {
      statusColor = const Color(0xFFF87171);
      statusBg = const Color(0xFFF87171).withValues(alpha: 0.08);
      statusIcon = Icons.cancel_outlined;
    }

    return GestureDetector(
      onTap: () => _showTransactionDetail(tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDeposit
                    ? _primary.withValues(alpha: 0.10)
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                size: 20,
                color: isIncome
                    ? _primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['type'].toString().toLowerCase().capitalize(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • hh:mm a',
                    ).format(DateTime.parse(tx['createdAt'])),
                    style: TextStyle(color: _textDim, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${NumberFormat('#,##0.00').format(tx['amount'])} USDT',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isIncome
                        ? _primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 10, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetail(Map<String, dynamic> tx) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(tx: tx),
      ),
    );
  }
}


extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
