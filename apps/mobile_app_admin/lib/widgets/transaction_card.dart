import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final double widthScale;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.widthScale,
    this.onTap,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isDeposit = transaction['type'] == 'DEPOSIT';
    final isExchange = transaction['type'] == 'EXCHANGE';
    final isReferral = transaction['type'] == 'REFERRAL';
    final status = transaction['status'] as String;
    final isPending = status == 'PENDING';

    final bgCard = Theme.of(context).cardColor;
    final border = Theme.of(context).dividerColor;
    final textDim = Theme.of(context).colorScheme.onSurfaceVariant;
    final primary = Theme.of(context).primaryColor;
    const blue = Color(0xFF3B82F6);
    const danger = Color(0xFFF87171);

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

    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    if (isDeposit) {
      typeColor = primary;
      typeIcon = Icons.arrow_downward;
      typeLabel = 'Deposit';
    } else if (isExchange) {
      typeColor = blue;
      typeIcon = Icons.swap_horiz;
      typeLabel = 'Exchange';
    } else {
      typeColor = Colors.green;
      typeIcon = Icons.card_giftcard;
      typeLabel = 'Referral';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12 * widthScale),
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
                  width: 44 * widthScale,
                  height: 44 * widthScale,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    typeIcon,
                    size: 20 * widthScale,
                    color: typeColor,
                  ),
                ),
                SizedBox(width: 14 * widthScale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * widthScale,
                              vertical: 2 * widthScale,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 10 * widthScale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8 * widthScale),
                          Expanded(
                            child: Text(
                              (transaction['user']?['firstName'] != null ||
                                      transaction['user']?['lastName'] != null)
                                  ? '${transaction['user']?['firstName'] ?? ''} ${transaction['user']?['lastName'] ?? ''}'
                                        .trim()
                                  : transaction['user']?['email'] ?? 'Unknown',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14 * widthScale,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6 * widthScale),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(
                          DateTime.tryParse(
                                transaction['createdAt']?.toString() ?? '',
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
                      '${NumberFormat('#,##0.00').format(transaction['amount'] as num)} USDT',
                      style: GoogleFonts.outfit(
                        color: isDeposit
                            ? primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 15 * widthScale,
                      ),
                    ),
                    SizedBox(height: 6 * widthScale),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8 * widthScale,
                        vertical: 4 * widthScale,
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
              SizedBox(height: 12 * widthScale),
              Container(height: 1, color: border),
              SizedBox(height: 12 * widthScale),
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      label: 'Approve',
                      icon: Icons.check_circle_outline,
                      color: primary,
                      filled: true,
                      onPressed: onApprove,
                    ),
                  ),
                  SizedBox(width: 8 * widthScale),
                  Expanded(
                    child: _ActionBtn(
                      label: 'Reject',
                      icon: Icons.cancel_outlined,
                      color: danger,
                      onPressed: onReject,
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
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback? onPressed;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: filled ? 0.20 : 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
