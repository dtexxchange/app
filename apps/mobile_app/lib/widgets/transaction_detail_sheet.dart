import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/crypto_service.dart';

class TransactionDetailSheet extends StatelessWidget {
  final Map<String, dynamic> tx;

  const TransactionDetailSheet({super.key, required this.tx});

  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color _bgDark(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  Color _bgCard(BuildContext context) => Theme.of(context).cardColor;
  Color _primary(BuildContext context) => Theme.of(context).primaryColor;
  Color _blue(BuildContext context) => const Color(0xFF3B82F6);
  Color _textDim(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
  Color _border(BuildContext context) => Theme.of(context).dividerColor;
  Color _danger(BuildContext context) => const Color(0xFFF87171);

  @override
  Widget build(BuildContext context) {
    final status = tx['status'] as String? ?? 'PENDING';
    final logs = tx['logs'] as List? ?? [];
    final isDeposit = tx['type'] == 'DEPOSIT';
    final isExchange = tx['type'] == 'EXCHANGE';
    
    final bank = (isExchange && tx['bankDetails'] != null)
        ? CryptoService.decrypt(tx['bankDetails'])
        : null;

    Color statusColor;
    if (status == 'COMPLETED') {
      statusColor = _primary(context);
    } else if (status == 'PENDING') {
      statusColor = _blue(context);
    } else {
      statusColor = _danger(context);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
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
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TX-${tx['id']?.toString().substring(0, 12).toUpperCase() ?? 'UNKNOWN'}',
                          style: TextStyle(color: _textDim(context), fontSize: 12),
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

                // Main Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _bgDark(context),
                    border: Border.all(color: _border(context)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(label: 'TYPE', value: tx['type'] ?? 'Unknown'),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'AMOUNT',
                        value:
                            '${NumberFormat('#,##0.00').format(tx['amount'] as num)} USDT',
                        valueColor: isDeposit ? _primary(context) : Theme.of(context).colorScheme.onSurface,
                      ),
                      if (tx['conversionRate'] != null) ...[
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'RATE',
                          value:
                              '₹${(tx['conversionRate'] as num).toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'CREDIT ESTIMATE',
                          value:
                              '₹${NumberFormat('#,##0.00').format((tx['amount'] as num) * (tx['conversionRate'] as num))}',
                          valueColor: _blue(context),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Bank Details (Exchange Instructions)
                if (bank != null) ...[
                  Text(
                    'EXCHANGE INSTRUCTIONS',
                    style: TextStyle(
                      color: _textDim(context),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _bgDark(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primary(context).withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _infoRow(
                          'Beneficiary',
                          bank['name'] ?? 'Unknown',
                          context,
                        ),
                        const SizedBox(height: 8),
                        _infoRow(
                          'Account',
                          bank['account'] ?? 'Locked',
                          context,
                        ),
                        const SizedBox(height: 8),
                        _infoRow('Bank', bank['bank'] ?? 'Private', context),
                        const SizedBox(height: 8),
                        _infoRow(
                          'IFSC/Sort',
                          bank['ifsc'] ?? 'LOCKED',
                          context,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Activity Logs
                  Text(
                    'ACTIVITY LOGS',
                    style: TextStyle(
                      color: _textDim(context),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                const SizedBox(height: 16),
                if (logs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'No activity history found',
                      style: TextStyle(color: _textDim(context), fontSize: 13),
                    ),
                  )
                else
                  ...logs.map(
                    (log) => _buildLogItem(
                      context,
                      tx,
                      log,
                      logs.indexOf(log) == logs.length - 1,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, BuildContext context,
      {bool isLast = false}) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _textDim(context), fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                _CopyButton(label: label, value: value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, Map<String, dynamic> tx, Map<String, dynamic> log, bool isLast) {
    String actorStr = log['actor'] ?? 'Unknown';
    String note = log['note'] ?? 'Status updated';

    if (actorStr == 'SYSTEM') {
      actorStr = 'System';
    } else if (tx['user'] != null && actorStr == tx['user']['email']) {
      final f = tx['user']['firstName']?.toString() ?? '';
      final l = tx['user']['lastName']?.toString() ?? '';
      final name = '$f $l'.trim();
      if (name.isNotEmpty) actorStr = name;
    }

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
                  color: _primary(context).withOpacity(0.3),
                  border: Border.all(color: _primary(context), width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: _primary(context).withOpacity(0.3)),
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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'hh:mm a',
                        ).format(DateTime.parse(log['createdAt'])),
                        style: TextStyle(color: _textDim(context), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: TextStyle(color: _textDim(context), fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'by $actorStr',
                    style: TextStyle(
                      color: _primary(context).withOpacity(0.5),
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String label;
  final String value;
  const _CopyButton({required this.label, required this.value});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: widget.value));
    setState(() => _copied = true);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.label} Copied',
          textAlign: TextAlign.center,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 140,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleCopy,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color:
              _copied ? Theme.of(context).primaryColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          _copied ? Icons.check_rounded : Icons.copy_rounded,
          size: 14,
          color: _copied ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
        ),
      ),
    );
  }
}
