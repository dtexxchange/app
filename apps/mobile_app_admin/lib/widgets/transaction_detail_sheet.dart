import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart' as pc;
import '../services/api_service.dart';

// ─── Design Tokens (Standardized) ───────────────────────────────────────────
const _bgDark = Color(0xFF0A0B0D);
const _primary = Color(0xFF00FF9D);
const _blue = Color(0xFF3B82F6);
const _textDim = Color(0xFF94A3B8);
const _border = Color(0x0DFFFFFF);
const _danger = Color(0xFFF87171);

class TransactionDetailSheet extends StatefulWidget {
  final Map<String, dynamic> tx;
  final Function(String)? onStatusUpdate;
  final List<dynamic>? allUsers;

  const TransactionDetailSheet({
    super.key,
    required this.tx,
    this.onStatusUpdate,
    this.allUsers,
  });

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
  Map<String, dynamic>? _decrypted;
  bool _isLoadingInfo = false;
  List<dynamic>? _fetchedLogs;
  Map<String, dynamic>? _fetchedUser;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoadingInfo = true);
    try {
      const storage = FlutterSecureStorage();
      final privPem = await storage.read(key: 'admin_private_key');

      if (_CryptoHelper.enableE2EE == false ||
          (privPem != null && widget.tx['bankDetails'] != null)) {
        final api = ApiService();
        final res = await api.getRequest(
          '/wallet/transactions/${widget.tx['id']}',
        );
        if (res.statusCode == 200) {
          final txFull = jsonDecode(res.body);
          final logs = txFull['logs'] as List<dynamic>?;
          final encrypted = txFull['bankDetails'];

          setState(() {
            if (logs != null) _fetchedLogs = logs;
            _fetchedUser = txFull['user'];
          });

          if (encrypted != null) {
            final decryptedStr = _CryptoHelper.decrypt(
              privPem ?? "",
              encrypted,
            );
            if (decryptedStr != null) {
              setState(() => _decrypted = jsonDecode(decryptedStr));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Decryption error: $e');
    }
    if (mounted) setState(() => _isLoadingInfo = false);
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final user = _fetchedUser ?? tx['user'];
    final logs = _fetchedLogs ?? tx['logs'] as List<dynamic>? ?? [];
    final status = tx['status'] as String? ?? 'PENDING';
    final isDeposit = tx['type'] == 'DEPOSIT';
    final isPending = status == 'PENDING';

    Color statusColor;
    if (status == 'COMPLETED') {
      statusColor = _primary;
    } else if (status == 'PENDING') {
      statusColor = _blue;
    } else {
      statusColor = _danger;
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
                          'Transaction Review',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TX-${tx['id']?.toString().substring(0, 12).toUpperCase() ?? 'UNKNOWN'}',
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

                // Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _bgDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'USER',
                        value:
                            (user?['firstName'] != null ||
                                user?['lastName'] != null)
                            ? '${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'
                                  .trim()
                            : (user?['email'] ?? 'Unknown'),
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'AMOUNT',
                        value:
                            '${NumberFormat('#,##0.00').format(tx['amount'] as num)} USDT',
                        valueColor: isDeposit ? _primary : Colors.white,
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(label: 'TYPE', value: tx['type']),
                      if (tx['conversionRate'] != null) ...[
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'RATE',
                          value:
                              '₹${(tx['conversionRate'] as num).toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'CREDIT (INR)',
                          value:
                              '₹${NumberFormat('#,##0.00').format((tx['amount'] as num) * (tx['conversionRate'] as num))}',
                          valueColor: _blue,
                        ),
                      ],
                    ],
                  ),
                ),

                // Action Buttons
                if (isPending && widget.onStatusUpdate != null) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          label: 'Approve',
                          icon: Icons.check_circle_outline,
                          color: _primary,
                          filled: true,
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onStatusUpdate!('COMPLETED');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          label: 'Reject',
                          icon: Icons.cancel_outlined,
                          color: _danger,
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onStatusUpdate!('REJECTED');
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                if (tx['type'] == 'EXCHANGE') ...[
                  const Text(
                    'BANK DETAILS (E2EE)',
                    style: TextStyle(
                      color: _textDim,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingInfo)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: _primary,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else if (_decrypted != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _bgDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _primary.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          _infoRow(
                            'Beneficiary',
                            _decrypted!['name'] ?? 'Unknown',
                            context,
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            'Account',
                            _decrypted!['account'] ?? 'Locked',
                            context,
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            'Bank',
                            _decrypted!['bank'] ?? 'Private',
                            context,
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            'IFSC/Sort',
                            _decrypted!['ifsc'] ?? 'LOCKED',
                            context,
                            isLast: true,
                          ),
                        ],
                      ),
                    )
                  else
                    const Text(
                      'Locked: Requires Admin RSA Key',
                      style: TextStyle(color: _danger, fontSize: 12),
                    ),
                  const SizedBox(height: 32),
                ],

                const Text(
                  'ACTIVITY TIMELINE',
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
                      'No activity logs found',
                      style: TextStyle(color: _textDim, fontSize: 13),
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
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
    BuildContext context, {
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _textDim, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
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
      final namePart = actorStr.split('@')[0].split('.')[0];
      actorStr =
          '${namePart[0].toUpperCase()}${namePart.substring(1).toLowerCase()} (Admin)';
    }

    String noteStr = log['note'] ?? 'Status updated';
    if (widget.allUsers != null && noteStr.contains('@')) {
      for (final u in widget.allUsers!) {
        final email = u['email']?.toString() ?? '';
        if (email.isNotEmpty && noteStr.contains(email)) {
          final f = u['firstName']?.toString() ?? '';
          final l = u['lastName']?.toString() ?? '';
          final name = '$f $l'.trim();
          if (name.isNotEmpty) {
            noteStr = noteStr.replaceAll(email, name);
          }
        }
      }
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
                          'MMM dd, hh:mm a',
                        ).format(DateTime.parse(log['createdAt'])),
                        style: const TextStyle(color: _textDim, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    noteStr,
                    style: const TextStyle(color: _textDim, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'by $actorStr',
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

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onPressed;
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
          color: color.withOpacity(filled ? 0.20 : 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
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
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 140,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _primary,
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
          color: _copied ? _primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          _copied ? Icons.check_rounded : Icons.copy_rounded,
          size: 14,
          color: _copied ? _primary : Colors.white.withOpacity(0.25),
        ),
      ),
    );
  }
}

class _CryptoHelper {
  static const bool enableE2EE = false;
  static String? decrypt(String pem, String encryptedBase64) {
    if (!enableE2EE) {
      try {
        return utf8.decode(base64Decode(encryptedBase64));
      } catch (e) {
        return null;
      }
    }
    try {
      final privateKey = enc.RSAKeyParser().parse(pem) as pc.RSAPrivateKey;
      final crypter = enc.Encrypter(enc.RSA(privateKey: privateKey));

      final decrypted = crypter.decrypt(
        enc.Encrypted.fromBase64(encryptedBase64),
      );
      return decrypted;
    } catch (e) {
      return null;
    }
  }
}
