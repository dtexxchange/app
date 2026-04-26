import 'package:flutter/material.dart';

import 'transaction_card.dart';

class TransactionsTab extends StatefulWidget {
  final List<dynamic> transactions;
  final String searchQuery;
  final String selectedType;
  final String selectedStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortBy;
  final Function(String) onSearchChanged;
  final Function(String) onTypeChanged;
  final Function(String) onStatusChanged;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final Function(String) onSortChanged;
  final VoidCallback onShowFilterSheet;
  final Function(String, String) onTransactionAction;

  const TransactionsTab({
    super.key,
    required this.transactions,
    required this.searchQuery,
    required this.selectedType,
    required this.selectedStatus,
    this.startDate,
    this.endDate,
    this.sortBy = 'date',
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onSortChanged,
    required this.onShowFilterSheet,
    required this.onTransactionAction,
  });

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  int _currentTransactionTab = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionTabs = ['All', 'Deposits', 'Exchanges', 'Withdrawals', 'Referral'];
    final widthScale = (MediaQuery.of(context).size.width / 375.0).clamp(
      0.85,
      1.2,
    );

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          // Swiped right (go to previous tab)
          if (_currentTransactionTab > 0) {
            setState(() {
              _currentTransactionTab--;
            });
            _pageController.animateToPage(
              _currentTransactionTab,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        } else if (details.primaryVelocity! < 0) {
          // Swiped left (go to next tab)
          if (_currentTransactionTab < transactionTabs.length - 1) {
            setState(() {
              _currentTransactionTab++;
            });
            _pageController.animateToPage(
              _currentTransactionTab,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      },
      child: Column(
        children: [
          // Horizontal scrollable tabs
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: transactionTabs.length,
              itemBuilder: (context, index) {
                final isSelected = _currentTransactionTab == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentTransactionTab = index;
                    });
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Text(
                      transactionTabs[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Transaction list content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentTransactionTab = index;
                });
              },
              children: [
                _buildTransactionList('all', widthScale),
                _buildTransactionList('deposit', widthScale),
                _buildTransactionList('exchange', widthScale),
                _buildTransactionList('withdrawal', widthScale),
                _buildTransactionList('referral', widthScale),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(String type, double widthScale) {
    List<dynamic> filteredTransactions() {
      List<dynamic> filtered = List.from(widget.transactions);

      // Filter by tab type first
      if (type != 'all') {
        final tabType = type.toLowerCase();
        filtered = filtered.where((tx) {
          final txType = tx['type']?.toString().toLowerCase() ?? '';
          return txType.contains(tabType);
        }).toList();
      }

      // Filter by type (from filter sheet)
      if (widget.selectedType != 'All') {
        filtered = filtered.where((tx) {
          final txType = tx['type']?.toString().toLowerCase() ?? '';
          return txType.contains(txType);
        }).toList();
      }

      // Filter by search
      if (widget.searchQuery.isNotEmpty) {
        final searchLower = widget.searchQuery.toLowerCase();
        filtered = filtered.where((tx) {
          final userName =
              '${tx['user']?['firstName'] ?? ''} ${tx['user']?['lastName'] ?? ''}'
                  .toLowerCase();
          final userEmail =
              tx['user']?['email']?.toString().toLowerCase() ?? '';
          final txId = tx['id']?.toString().toLowerCase() ?? '';

          return userName.contains(searchLower) ||
              userEmail.contains(searchLower) ||
              txId.contains(searchLower);
        }).toList();
      }

      // Filter by status
      if (widget.selectedStatus != 'All') {
        filtered = filtered
            .where((tx) => tx['status'] == widget.selectedStatus)
            .toList();
      }

      // Filter by date range
      if (widget.startDate != null || widget.endDate != null) {
        filtered = filtered.where((tx) {
          final txDate = DateTime.tryParse(tx['createdAt']?.toString() ?? '');
          if (txDate == null) return false;

          if (widget.startDate != null && txDate.isBefore(widget.startDate!)) {
            return false;
          }
          if (widget.endDate != null && txDate.isAfter(widget.endDate!)) {
            return false;
          }

          return true;
        }).toList();
      }

      // Apply sorting
      filtered.sort((a, b) {
        switch (widget.sortBy) {
          case 'date':
            final dateA =
                DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
                DateTime.now();
            final dateB =
                DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
                DateTime.now();
            return dateB.compareTo(dateA);
          case 'amount':
            final amountA = (a['amount'] as num?) ?? 0;
            final amountB = (b['amount'] as num?) ?? 0;
            return amountB.compareTo(amountA);
          case 'type':
            final typeA = a['type']?.toString() ?? '';
            final typeB = b['type']?.toString() ?? '';
            return typeA.compareTo(typeB);
          case 'status':
            final statusA = a['status']?.toString() ?? '';
            final statusB = b['status']?.toString() ?? '';
            return statusA.compareTo(statusB);
          default:
            return 0;
        }
      });

      return filtered;
    }

    final filtered = filteredTransactions();

    if (filtered.isEmpty) {
      return _emptyState('No transactions found', Icons.receipt_long);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      children: filtered
          .map(
            (tx) => TransactionCard(
              transaction: tx,
              widthScale: widthScale,
              onTap: () => widget.onTransactionAction(tx['id'], 'detail'),
              onApprove: () => widget.onTransactionAction(tx['id'], 'approve'),
              onReject: () => widget.onTransactionAction(tx['id'], 'reject'),
            ),
          )
          .toList(),
    );
  }

  Widget _emptyState(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
