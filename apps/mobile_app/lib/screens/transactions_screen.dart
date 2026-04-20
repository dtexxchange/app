import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../main.dart' show routeObserver;
import '../services/api_service.dart';
import '../widgets/transaction_detail_sheet.dart';

const _bgDark = Color(0xFF0A0B0D);
const _bgCard = Color(0xFF15171C);
const _primary = Color(0xFF00FF9D);
const _blue = Color(0xFF3B82F6);
const _textDim = Color(0xFF94A3B8);
const _border = Color(0x0DFFFFFF);

/// Number of items to fetch per page.
const _pageSize = 15;

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => TransactionsScreenState();
}

// State exposed so MainScreen can refresh via GlobalKey<TransactionsScreenState>.
class TransactionsScreenState extends State<TransactionsScreen>
    with RouteAware {
  List _transactions = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _page = 1;

  String _filterType = '';
  String _filterStatus = '';

  final _api = ApiService();
  final _scrollController = ScrollController();

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
      final params = <String, String>{'page': '1', 'limit': '$_pageSize'};
      if (_filterType.isNotEmpty) params['type'] = _filterType;
      if (_filterStatus.isNotEmpty) params['status'] = _filterStatus;

      final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final res = await _api.getRequest('/wallet/transactions?$query');

      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _transactions = data;
          _page = 2;
          _hasMore = data.length >= _pageSize;
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

  Future<void> _loadMore() async {
    if (_isFetchingMore || !_hasMore || _isLoading) return;
    setState(() => _isFetchingMore = true);

    try {
      final params = <String, String>{'page': '$_page', 'limit': '$_pageSize'};
      if (_filterType.isNotEmpty) params['type'] = _filterType;
      if (_filterStatus.isNotEmpty) params['status'] = _filterStatus;

      final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final res = await _api.getRequest('/wallet/transactions?$query');

      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _transactions = [..._transactions, ...data];
          _page++;
          _hasMore = data.length >= _pageSize;
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
    return Scaffold(
      backgroundColor: _bgDark,
      body: RefreshIndicator(
        onRefresh: () => _fetchPage(reset: true),
        color: _primary,
        backgroundColor: _bgCard,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: _bgDark.withOpacity(0.9),
              elevation: 0,
              titleSpacing: 24,
              title: Row(
                children: [
                  const Icon(Icons.receipt_long, color: _primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Transaction History',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: _border),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: _buildFilters(),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: _primary),
                ),
              )
            else if (_transactions.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildTxTile(_transactions[i]),
                    childCount: _transactions.length,
                  ),
                ),
              ),
              // Load-more indicator or end-of-list footer
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                  child: _isFetchingMore
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                              color: _primary,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : _hasMore
                      ? const SizedBox.shrink()
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              '— All transactions loaded —',
                              style: TextStyle(
                                color: _textDim.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: _FilterChip(
            label: 'All Types',
            options: const {
              '': 'All',
              'DEPOSIT': 'Deposit',
              'EXCHANGE': 'Exchange',
              'REFERRAL_COMMISSION': 'Commission',
            },
            value: _filterType,
            onChanged: (v) {
              setState(() => _filterType = v);
              _fetchPage(reset: true);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FilterChip(
            label: 'All Status',
            options: const {
              '': 'All',
              'PENDING': 'Pending',
              'COMPLETED': 'Done',
              'REJECTED': 'Rejected',
            },
            value: _filterStatus,
            onChanged: (v) {
              setState(() => _filterStatus = v);
              _fetchPage(reset: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.show_chart, size: 56, color: Colors.white.withOpacity(0.08)),
        const SizedBox(height: 16),
        const Text(
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
      statusBg = _primary.withOpacity(0.08);
      statusIcon = Icons.check_circle_outline;
    } else if (status == 'PENDING') {
      statusColor = _blue;
      statusBg = _blue.withOpacity(0.08);
      statusIcon = Icons.access_time;
    } else {
      statusColor = const Color(0xFFF87171);
      statusBg = const Color(0xFFF87171).withOpacity(0.08);
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
                    ? _primary.withOpacity(0.10)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                size: 20,
                color: isIncome ? _primary : Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['type'].toString().toLowerCase().capitalize(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • hh:mm a',
                    ).format(DateTime.parse(tx['createdAt'])),
                    style: const TextStyle(color: _textDim, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${NumberFormat('#,##0.00').format(tx['amount'])}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isIncome ? _primary : Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'USDT',
                  style: TextStyle(color: _textDim, fontSize: 11),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TransactionDetailSheet(tx: tx),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Map<String, String> options;
  final String value;
  final ValueChanged<String> onChanged;

  const _FilterChip({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final chosen = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: _bgCard,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ...options.entries.map(
                  (e) => ListTile(
                    title: Text(
                      e.value,
                      style: TextStyle(
                        color: value == e.key ? _primary : Colors.white,
                        fontWeight: value == e.key
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: value == e.key
                        ? const Icon(Icons.check, color: _primary, size: 18)
                        : null,
                    onTap: () => Navigator.pop(ctx, e.key),
                  ),
                ),
              ],
            ),
          ),
        );
        if (chosen != null) onChanged(chosen);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value.isNotEmpty ? _primary.withOpacity(0.4) : _border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              options[value] ?? label,
              style: TextStyle(
                color: value.isNotEmpty ? _primary : _textDim,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: value.isNotEmpty ? _primary : _textDim,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
