import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';

const _bgDark = Color(0xFF0A0B0D);
const _bgCard = Color(0xFF15171C);
const _primary = Color(0xFF00FF9D);
const _blue = Color(0xFF3B82F6);
const _textDim = Color(0xFF94A3B8);
const _border = Color(0x0DFFFFFF);

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List _transactions = [];
  bool _isLoading = true;
  String _filterType = '';
  String _filterStatus = '';
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, String>{};
      if (_filterType.isNotEmpty) params['type'] = _filterType;
      if (_filterStatus.isNotEmpty) params['status'] = _filterStatus;
      final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final txRes = await _api.getRequest(
        '/wallet/transactions${query.isNotEmpty ? '?$query' : ''}',
      );
      if (txRes.statusCode == 200 && mounted) {
        setState(() {
          _transactions = jsonDecode(txRes.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: RefreshIndicator(
        onRefresh: _fetchTransactions,
        color: _primary,
        backgroundColor: _bgCard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: _bgDark.withOpacity(0.9),
              elevation: 0,
              titleSpacing: 24,
              title: Row(children: [
                const Icon(Icons.receipt_long, color: _primary, size: 20),
                const SizedBox(width: 10),
                Text('Transaction History', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ]),
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
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildTxTile(_transactions[i]),
                    childCount: _transactions.length,
                  ),
                ),
              ),
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
              'WITHDRAW': 'Withdraw',
            },
            value: _filterType,
            onChanged: (v) {
              setState(() => _filterType = v);
              _fetchTransactions();
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
              _fetchTransactions();
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
                isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                size: 20,
                color: isDeposit ? _primary : Colors.white,
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
                    DateFormat('MMM dd, yyyy • HH:mm')
                        .format(DateTime.parse(tx['createdAt'])),
                    style: const TextStyle(color: _textDim, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isDeposit ? '+' : '-'}${NumberFormat('#,##0.00').format(tx['amount'])}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDeposit ? _primary : Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                const Text('USDT', style: TextStyle(color: _textDim, fontSize: 11)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
      builder: (context) => _TransactionDetailSheet(tx: tx),
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

class _TransactionDetailSheet extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionDetailSheet({required this.tx});

  @override
  Widget build(BuildContext context) {
    final status = tx['status'] as String? ?? 'PENDING';
    final logs = tx['logs'] as List? ?? [];
    final isDeposit = tx['type'] == 'DEPOSIT';
    final bank = (!isDeposit && tx['bankDetails'] != null)
        ? CryptoService.decrypt(tx['bankDetails'])
        : null;

    Color statusColor;
    if (status == 'COMPLETED')
      statusColor = _primary;
    else if (status == 'PENDING')
      statusColor = _blue;
    else
      statusColor = const Color(0xFFF87171);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction Details',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TX-${tx['id'].toString().substring(0, 12).toUpperCase()}',
                          style: const TextStyle(color: _textDim, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _bgDark,
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(label: 'TYPE', value: tx['type'] ?? 'Unknown'),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'AMOUNT',
                        value:
                            '${NumberFormat('#,##0.00').format(tx['amount'])} USDT',
                        valueColor: isDeposit ? _primary : Colors.white,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (bank != null) ...[
                  const Text(
                    'WITHDRAWAL INSTRUCTIONS',
                    style: TextStyle(
                      color: _textDim,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _bgDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primary.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _infoRow('Beneficiary', bank['name'] ?? 'Unknown'),
                        const SizedBox(height: 8),
                        _infoRow('Account', bank['account'] ?? 'Locked'),
                        const SizedBox(height: 8),
                        _infoRow('Bank', bank['bank'] ?? 'Private'),
                        const SizedBox(height: 8),
                        _infoRow(
                          'IFSC/Sort',
                          bank['ifsc'] ?? 'LOCKED',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                const Text(
                  'ACTIVITY LOGS',
                  style: TextStyle(
                    color: _textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                if (logs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      'No logs available',
                      style: TextStyle(color: _textDim, fontSize: 13),
                    ),
                  )
                else
                  ...logs.map(
                    (log) =>
                        _buildLogItem(log, logs.indexOf(log) == logs.length - 1),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withOpacity(0.3),
                  border: Border.all(color: _primary, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: _primary.withOpacity(0.1)),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        log['status'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'HH:mm',
                        ).format(DateTime.parse(log['createdAt'])),
                        style: const TextStyle(color: _textDim, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log['note'] ?? 'Status updated',
                    style: const TextStyle(color: _textDim, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'by ${log['actor']}',
                    style: TextStyle(
                      color: _primary.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _textDim, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textDim,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
