import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../services/api_service.dart';
import '../services/crypto_service.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tx;

  const TransactionDetailScreen({
    super.key,
    required this.tx,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  Map<String, dynamic>? _decrypted;
  bool _isLoadingInfo = false;
  bool _isSharing = false;
  List<dynamic>? _fetchedLogs;

  bool _isExpanded = false;

  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color get bgDarkToken => Theme.of(context).scaffoldBackgroundColor;
  Color get primaryToken => Theme.of(context).primaryColor;
  Color get blueToken => const Color(0xFF3B82F6);
  Color get textDimToken => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get borderToken => Theme.of(context).dividerColor;
  static const Color dangerToken = Color(0xFFF87171);

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final isExchange = widget.tx['type'] == 'EXCHANGE';
    final isWithdrawal = widget.tx['type'] == 'WITHDRAWAL';
    if ((isExchange || isWithdrawal) && widget.tx['bankDetails'] != null) {
      setState(() => _isLoadingInfo = true);
      try {
        final decrypted = CryptoService.decrypt(widget.tx['bankDetails']);
        if (decrypted != null) {
          setState(() => _decrypted = decrypted);
        }
      } catch (e) {
        debugPrint('Decryption error: $e');
      }
      setState(() => _isLoadingInfo = false);
    }

    // Refresh logs if needed
    try {
      final api = ApiService();
      final res = await api.getRequest(
        '/wallet/transactions/${widget.tx['id']}',
      );
      if (res.statusCode == 200) {
        final txFull = jsonDecode(res.body);
        final logs = txFull['logs'] as List<dynamic>?;
        if (logs != null) {
          setState(() => _fetchedLogs = logs);
        }
      }
    } catch (e) {
      debugPrint('Log fetch error: $e');
    }
  }

  Future<void> _shareAsImage() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final image = await _screenshotController.capture(
        delay: const Duration(milliseconds: 10),
        pixelRatio: 2.0,
      );

      if (image != null) {
        final fileName = 'transaction_${widget.tx['readableId']}.png';
        await SharePlus.instance.share(
          ShareParams(
            text: 'Transaction Details: ${widget.tx['readableId']}',
            files: [
              XFile.fromData(image, name: fileName, mimeType: 'image/png'),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sharing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share image: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgDark = bgDarkToken;
    final primary = primaryToken;
    final blue = blueToken;
    final textDim = textDimToken;
    final border = borderToken;
    final danger = dangerToken;

    final tx = widget.tx;
    final logs = _fetchedLogs ?? tx['logs'] as List<dynamic>? ?? [];
    final status = tx['status'] as String? ?? 'PENDING';
    final isDeposit = tx['type'] == 'DEPOSIT';
    final isExchange = tx['type'] == 'EXCHANGE';
    final isWithdrawal = tx['type'] == 'WITHDRAWAL';

    Color statusColor;
    if (status == 'COMPLETED') {
      statusColor = primary;
    } else if (status == 'PENDING') {
      statusColor = blue;
    } else {
      statusColor = danger;
    }

    final double conversionRate =
        (tx['conversionRate'] as num?)?.toDouble() ?? 0.0;
    final double amountUsdt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final double amountInr =
        amountUsdt * (conversionRate > 0 ? conversionRate : 1.0);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transaction Details',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          if (!_isSharing)
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 22),
              onPressed: _shareAsImage,
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
        centerTitle: true,
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Container(
          color: bgDark,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              // Section 1: Core Summary
              _buildSectionCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TRANSACTION ID',
                              style: TextStyle(
                                color: textDim,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  tx['readableId']?.toString() ?? 'UNKNOWN',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _CopyButton(
                                  label: 'ID',
                                  value: tx['readableId']?.toString() ?? '',
                                ),
                              ],
                            ),
                          ],
                        ),
                        _buildStatusBadge(status, statusColor),
                      ],
                    ),
                    if (tx['utr'] != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.receipt_outlined, color: primary, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'UTR NUMBER',
                                    style: TextStyle(
                                      color: textDim,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    tx['utr'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _CopyButton(label: 'UTR', value: tx['utr']),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AMOUNT (INR)',
                              style: TextStyle(
                                color: textDim,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${NumberFormat('#,##0.00').format(amountInr)}',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(height: 1, color: border.withValues(alpha: 0.15)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CREATED AT',
                                style: TextStyle(
                                  color: textDim,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, hh:mm a').format(
                                  DateTime.parse(
                                    tx['createdAt'] ??
                                        DateTime.now().toString(),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: border.withValues(alpha: 0.2),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'UPDATED AT',
                                style: TextStyle(
                                  color: textDim,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, hh:mm a').format(
                                  DateTime.parse(
                                    tx['updatedAt'] ??
                                        tx['createdAt'] ??
                                        DateTime.now().toString(),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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

              const SizedBox(height: 24),

              // Section 2: Bank Details (Instructions for Exchange/Withdrawal)
              if (isExchange || isWithdrawal) ...[
                Text(
                  isWithdrawal ? 'WITHDRAWAL DESTINATION' : 'EXCHANGE INSTRUCTIONS',
                  style: TextStyle(
                    color: textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSectionCard(
                  child: Column(
                    children: [
                      if (_isLoadingInfo)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_decrypted != null) ...[
                        _infoRow(
                          'Beneficiary',
                          _decrypted!['name'] ?? 'Unknown',
                          context,
                        ),
                        const SizedBox(height: 12),
                        _infoRow(
                          'Account',
                          _decrypted!['account'] ?? 'Locked',
                          context,
                        ),
                        const SizedBox(height: 12),
                        _infoRow(
                          'Bank',
                          _decrypted!['bank'] ?? 'Private',
                          context,
                        ),
                        const SizedBox(height: 12),
                        _infoRow(
                          'IFSC/Sort',
                          _decrypted!['ifsc'] ?? 'LOCKED',
                          context,
                          isLast: true,
                        ),
                      ] else
                        Text(
                          'Bank details locked or unavailable',
                          style: TextStyle(color: danger, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Show More Toggle Button
              Center(
                child: _buildShowMoreButton(
                  expanded: _isExpanded,
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ),

              // Expanded Content
              if (_isExpanded) ...[
                const SizedBox(height: 32),
                Text(
                  'ADDITIONAL DETAILS',
                  style: TextStyle(
                    color: textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSectionCard(
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'AMOUNT (USDT)',
                        value:
                            '${NumberFormat('#,##0.00').format(amountUsdt)} USDT',
                        valueColor: isDeposit ? primary : null,
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(label: 'TYPE', value: tx['type']),
                      if (conversionRate > 0) ...[
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'CONVERSION RATE',
                          value: '₹${conversionRate.toStringAsFixed(2)}',
                        ),
                      ],
                      if (tx['fee'] != null) ...[
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'WITHDRAWAL FEE',
                          value: '${(tx['fee'] as num).toDouble().toStringAsFixed(2)} USDT',
                          valueColor: danger,
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'NET AMOUNT',
                          value: '${(amountUsdt - (tx['fee'] as num).toDouble()).toStringAsFixed(2)} USDT',
                          valueColor: primary,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'ACTIVITY TIMELINE',
                  style: TextStyle(
                    color: textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSectionCard(
                  child: Column(
                    children: [
                      if (logs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No activity history found',
                            style: TextStyle(color: textDim, fontSize: 13),
                          ),
                        )
                      else
                        ...logs.map(
                          (log) => _buildLogItem(
                            log,
                            logs.indexOf(log) == logs.length - 1,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderToken),
      ),
      child: child,
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildShowMoreButton({
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: primaryToken.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              expanded ? 'Show Less' : 'Show More',
              style: TextStyle(
                color: primaryToken,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
              color: primaryToken,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
    BuildContext context, {
    bool isLast = false,
  }) {
    final textDim = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textDim, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
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

  Widget _buildLogItem(Map<String, dynamic> log, bool isLast) {
    final primary = primaryToken;
    final textDim = textDimToken;

    String actorStr = log['actor'] ?? 'Unknown';
    if (actorStr == 'SYSTEM') {
      actorStr = 'System';
    } else if (widget.tx['user'] != null &&
        actorStr == widget.tx['user']['email']) {
      final f = widget.tx['user']['firstName']?.toString() ?? '';
      final l = widget.tx['user']['lastName']?.toString() ?? '';
      final name = '$f $l'.trim();
      if (name.isNotEmpty) actorStr = name;
    } else if (actorStr.contains('@')) {
      // For users, we don't show admin emails, just "Admin"
      actorStr = 'Admin';
    }

    String noteStr = log['note'] ?? 'Status updated';

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
                  color: primary.withValues(alpha: 0.3),
                  border: Border.all(color: primary, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: primary.withValues(alpha: 0.1),
                  ),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'MMM dd, hh:mm a',
                        ).format(DateTime.parse(log['createdAt'])),
                        style: TextStyle(color: textDim, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(noteStr, style: TextStyle(color: textDim, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    'by $actorStr',
                    style: TextStyle(
                      color: primary.withValues(alpha: 0.5),
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
    final textDim = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textDim,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color:
                        valueColor ?? Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
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
    final primary = Theme.of(context).primaryColor;
    Clipboard.setData(ClipboardData(text: widget.value));
    setState(() => _copied = true);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.label} Copied',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 140,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: primary,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: _handleCopy,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _copied
              ? primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          _copied ? Icons.check_rounded : Icons.copy_rounded,
          size: 14,
          color: _copied
              ? primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}
