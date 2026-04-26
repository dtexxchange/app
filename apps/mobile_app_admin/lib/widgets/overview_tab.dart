import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'action_button.dart';

class OverviewTab extends StatelessWidget {
  final List<dynamic> users;
  final List<dynamic> transactions;
  final double? conversionRate;
  final String txStatus;
  final String txType;
  final Function(String) onStatusChanged;
  final Function(String) onTypeChanged;
  final Function(Map<String, dynamic>) onTransactionTap;
  final Function(String, String) onUpdateTxStatus;
  final Future<void> Function() onRefresh;
  final VoidCallback onViewAll;

  const OverviewTab({
    super.key,
    required this.users,
    required this.transactions,
    this.conversionRate,
    required this.txStatus,
    required this.txType,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.onTransactionTap,
    required this.onUpdateTxStatus,
    required this.onRefresh,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final widthScale = (MediaQuery.of(context).size.width / 375.0).clamp(
      0.85,
      1.2,
    );
    final pending = transactions.where((t) => t['status'] == 'PENDING').length;
    final isSmall = MediaQuery.of(context).size.width < 360;
    final primary = Theme.of(context).primaryColor;
    final blue = const Color(0xFF3B82F6);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: primary,
      backgroundColor: Theme.of(context).cardColor,
      child: ListView(
        padding: EdgeInsets.fromLTRB(22 * widthScale, 8, 22 * widthScale, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Stats row
          if (isSmall) ...[
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Total Users',
                    value: users.length.toString(),
                    icon: Icons.people_outline,
                    iconColor: blue,
                    widthScale: widthScale,
                  ),
                ),
                SizedBox(width: 12 * widthScale),
                Expanded(
                  child: StatCard(
                    label: 'Pending',
                    value: pending.toString(),
                    icon: Icons.access_time,
                    iconColor: blue,
                    widthScale: widthScale,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12 * widthScale),
            StatCard(
              label: 'Current Conversion Rate',
              value: conversionRate != null
                  ? '₹${conversionRate!.toStringAsFixed(2)}'
                  : '---',
              icon: Icons.show_chart,
              iconColor: blue,
              widthScale: widthScale,
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Total Users',
                    value: users.length.toString(),
                    icon: Icons.people_outline,
                    iconColor: blue,
                    widthScale: widthScale,
                  ),
                ),
                SizedBox(width: 12 * widthScale),
                Expanded(
                  child: StatCard(
                    label: 'Pending',
                    value: pending.toString(),
                    icon: Icons.access_time,
                    iconColor: blue,
                    widthScale: widthScale,
                  ),
                ),
                SizedBox(width: 12 * widthScale),
                Expanded(
                  child: StatCard(
                    label: 'USD Rate',
                    value: conversionRate != null
                        ? '₹${conversionRate!.toStringAsFixed(2)}'
                        : '---',
                    icon: Icons.show_chart,
                    iconColor: blue,
                    widthScale: widthScale,
                  ),
                ),
              ],
            ),
          SizedBox(height: 24 * widthScale),

          // Filters
          Row(
            children: [
              Expanded(
                child: DropFilter(
                  label: 'Status',
                  value: txStatus,
                  options: const {
                    '': 'All',
                    'PENDING': 'Pending',
                    'COMPLETED': 'Done',
                    'REJECTED': 'Rejected',
                  },
                  onChanged: onStatusChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropFilter(
                  label: 'Type',
                  value: txType,
                  options: const {
                    '': 'All Types',
                    'DEPOSIT': 'Deposit',
                    'EXCHANGE': 'Exchange',
                  },
                  onChanged: onTypeChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Transactions list
          SizedBox(height: 12 * widthScale),
          Row(
            children: [
              Icon(Icons.show_chart, color: primary, size: 20 * widthScale),
              SizedBox(width: 10 * widthScale),
              Text(
                'Latest Transactions',
                style: GoogleFonts.outfit(
                  fontSize: 20 * widthScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * widthScale),

          if (transactions.isEmpty)
            _emptyState(context, 'No transactions', Icons.show_chart)
          else ...[
            ...transactions
                .take(20)
                .map((tx) => _buildTxCard(context, tx, widthScale)),
            if (transactions.length >= 20) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onViewAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Full Transactions',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14 * widthScale,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: primary, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTxCard(
    BuildContext context,
    Map<String, dynamic> tx,
    double widthScale,
  ) {
    final isDeposit = tx['type'] == 'DEPOSIT';
    final status = tx['status'] as String;
    final isPending = status == 'PENDING';
    final primary = Theme.of(context).primaryColor;
    final blue = const Color(0xFF3B82F6);
    final danger = const Color(0xFFF87171);
    final border = Theme.of(context).dividerColor;
    final bgCard = Theme.of(context).cardColor;
    final textDim = Theme.of(context).colorScheme.onSurfaceVariant;

    Color statusColor;
    IconData statusIcon;
    if (status == 'COMPLETED') {
      statusColor = primary;
      statusIcon = Icons.check_circle_outline;
    } else if (status == 'PENDING') {
      statusColor = blue;
      statusIcon = Icons.access_time;
    } else {
      statusColor = danger;
      statusIcon = Icons.cancel_outlined;
    }

    return GestureDetector(
      onTap: () => onTransactionTap(tx),
      child: Container(
        margin: EdgeInsets.only(bottom: 10 * widthScale),
        padding: EdgeInsets.all(16 * widthScale),
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
                  width: 40 * widthScale,
                  height: 40 * widthScale,
                  decoration: BoxDecoration(
                    color: isDeposit
                        ? primary.withValues(alpha: 0.10)
                        : blue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 18 * widthScale,
                    color: isDeposit ? primary : blue,
                  ),
                ),
                SizedBox(width: 12 * widthScale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (tx['user']?['firstName'] != null ||
                                tx['user']?['lastName'] != null)
                            ? '${tx['user']?['firstName'] ?? ''} ${tx['user']?['lastName'] ?? ''}'
                                  .trim()
                            : tx['user']?['email'] ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14 * widthScale,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        DateFormat('MMM dd, hh:mm a').format(
                          DateTime.tryParse(
                                tx['createdAt']?.toString() ?? '',
                              ) ??
                              DateTime.now(),
                        ),
                        style: TextStyle(
                          color: textDim,
                          fontSize: 11 * widthScale,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${NumberFormat('#,##0.00').format(tx['amount'] as num)} USDT',
                      style: GoogleFonts.outfit(
                        color: isDeposit
                            ? primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14 * widthScale,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 10 * widthScale,
                            color: statusColor,
                          ),
                          SizedBox(width: 4 * widthScale),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9 * widthScale,
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
            if (isPending) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: border),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      label: 'Approve',
                      icon: Icons.check_circle_outline,
                      color: primary,
                      filled: true,
                      onPressed: () => onUpdateTxStatus(tx['id'], 'COMPLETED'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ActionButton(
                      label: 'Reject',
                      icon: Icons.cancel_outlined,
                      color: danger,
                      onPressed: () => onUpdateTxStatus(tx['id'], 'REJECTED'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, String label, IconData icon) {
    final textDim = Theme.of(context).colorScheme.onSurfaceVariant;
    final primary = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 42,
              color: primary.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There is no data matching your current filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDim,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final double widthScale;
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.widthScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final bgCard = Theme.of(context).cardColor;
    final border = Theme.of(context).dividerColor;
    final textDim = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.all(16 * widthScale),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36 * widthScale,
            height: 36 * widthScale,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18 * widthScale, color: iconColor),
          ),
          SizedBox(height: 12 * widthScale),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22 * widthScale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 4 * widthScale),
          Text(
            label,
            style: TextStyle(
              color: textDim,
              fontSize: 11 * widthScale,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class DropFilter extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  const DropFilter({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bgCard = Theme.of(context).cardColor;
    final primary = Theme.of(context).primaryColor;
    final textDim = Theme.of(context).colorScheme.onSurfaceVariant;
    final border = Theme.of(context).dividerColor;

    return GestureDetector(
      onTap: () async {
        final chosen = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: bgCard,
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                ...options.entries.map(
                  (e) => ListTile(
                    title: Text(
                      e.value,
                      style: TextStyle(
                        color: value == e.key
                            ? primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: value == e.key
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: value == e.key
                        ? Icon(Icons.check, color: primary, size: 18)
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
          color: bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value.isNotEmpty ? primary.withValues(alpha: 0.4) : border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              options[value] ?? label,
              style: TextStyle(
                color: value.isNotEmpty ? primary : textDim,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: value.isNotEmpty ? primary : textDim,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
