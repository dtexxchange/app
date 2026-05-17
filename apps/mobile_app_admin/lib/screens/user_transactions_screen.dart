import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/transactions_tab.dart';
import 'transaction_detail_screen.dart';
import '../widgets/transaction_filter_sheet.dart';

class UserTransactionsScreen extends StatefulWidget {
  final String userId;
  final String? userName;

  const UserTransactionsScreen({super.key, required this.userId, this.userName});

  @override
  State<UserTransactionsScreen> createState() => _UserTransactionsScreenState();
}

class _UserTransactionsScreenState extends State<UserTransactionsScreen> {
  final _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _transactions = [];

  String _transactionSearch = '';
  String _selectedTransactionType = 'All';
  String _selectedTransactionStatus = 'All';
  DateTime? _transactionStartDate;
  DateTime? _transactionEndDate;
  String _transactionSortBy = 'date';

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final params = <String>[];
      params.add('userId=${widget.userId}');
      if (_selectedTransactionStatus != 'All') {
        params.add('status=$_selectedTransactionStatus');
      }
      if (_selectedTransactionType != 'All') {
        params.add('type=$_selectedTransactionType');
      }
      params.add('limit=500');

      final query = '?${params.join('&')}';
      final res = await _api.getRequest('/wallet/transactions$query');

      if (res.statusCode == 200 && mounted) {
        setState(() {
          _transactions = jsonDecode(res.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTransactionFilterSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => TransactionFilterSheet(
        selectedType: _selectedTransactionType,
        selectedStatus: _selectedTransactionStatus,
        startDate: _transactionStartDate,
        endDate: _transactionEndDate,
        sortBy: _transactionSortBy,
        onTypeChanged: (v) => setState(() => _selectedTransactionType = v),
        onStatusChanged: (v) => setState(() => _selectedTransactionStatus = v),
        onStartDateChanged: (v) => setState(() => _transactionStartDate = v),
        onEndDateChanged: (v) => setState(() => _transactionEndDate = v),
        onSortChanged: (v) => setState(() => _transactionSortBy = v),
        onReset: () {
          setState(() {
            _selectedTransactionType = 'All';
            _selectedTransactionStatus = 'All';
            _transactionStartDate = null;
            _transactionEndDate = null;
            _transactionSortBy = 'date';
          });
          _fetchTransactions();
        },
        onApply: () {
          Navigator.pop(ctx);
          _fetchTransactions();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.userName != null ? "${widget.userName}'s Ledger" : "User Ledger",
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showTransactionFilterSheet,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: theme.dividerColor,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : TransactionsTab(
              transactions: _transactions,
              searchQuery: _transactionSearch,
              selectedType: _selectedTransactionType,
              selectedStatus: _selectedTransactionStatus,
              startDate: _transactionStartDate,
              endDate: _transactionEndDate,
              sortBy: _transactionSortBy,
              onSearchChanged: (v) => setState(() => _transactionSearch = v),
              onTypeChanged: (v) => setState(() => _selectedTransactionType = v),
              onStatusChanged: (v) => setState(() => _selectedTransactionStatus = v),
              onStartDateChanged: (v) => setState(() => _transactionStartDate = v),
              onEndDateChanged: (v) => setState(() => _transactionEndDate = v),
              onSortChanged: (v) => setState(() => _transactionSortBy = v),
              onShowFilterSheet: _showTransactionFilterSheet,
              onTransactionAction: (id, action) {
                if (action == 'detail') {
                  final tx = _transactions.firstWhere((t) => t['id'] == id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailScreen(
                        tx: tx,
                        onStatusUpdate: (s, {utr}) => _updateStatus(id, s, utr: utr),
                      ),
                    ),
                  ).then((_) => _fetchTransactions());
                } else if (action == 'approve') {
                  _updateStatus(id, 'COMPLETED');
                } else if (action == 'reject') {
                  _updateStatus(id, 'REJECTED');
                }
              },
            ),
    );
  }

  Future<void> _updateStatus(String id, String status, {String? utr}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        final utrCtrl = TextEditingController();
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(
            "${status == 'COMPLETED' ? 'Approve' : 'Reject'} Transaction",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Are you sure you want to mark this as $status?",
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (status == 'COMPLETED') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: utrCtrl,
                  decoration: InputDecoration(
                    labelText: "UTR Number",
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (status == 'COMPLETED' && utrCtrl.text.isEmpty) return;
                Navigator.pop(ctx, {"confirmed": true, "utr": utrCtrl.text});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.black,
              ),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );

    if (result == null || result['confirmed'] != true) return;

    try {
      final res = await _api.patchRequest('/wallet/transactions/$id/status', {
        'status': status,
        'utr': result['utr'],
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        _fetchTransactions();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
