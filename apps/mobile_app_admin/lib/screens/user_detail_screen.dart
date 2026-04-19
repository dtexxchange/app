import 'dart:convert';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pointycastle/export.dart' as pc;

import '../services/api_service.dart';

const _bgDark = Color(0xFF0A0B0D);
const _bgCard = Color(0xFF15171C);
const _primary = Color(0xFF00FF9D);
const _blue = Color(0xFF3B82F6);
const _textDim = Color(0xFF94A3B8);
const _border = Color(0x0DFFFFFF);
const _danger = Color(0xFFF87171);

class UserDetailScreen extends StatefulWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getRequest('/users/${widget.userId}');
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _user = jsonDecode(res.body);
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
        onRefresh: _fetchUser,
        color: _primary,
        backgroundColor: _bgCard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: _bgDark.withOpacity(0.95),
              elevation: 0,
              titleSpacing: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                _isLoading
                    ? 'User Details'
                    : (_user?['firstName'] != null ||
                          _user?['lastName'] != null)
                    ? '${_user?['firstName'] ?? ''} ${_user?['lastName'] ?? ''}'
                          .trim()
                    : (_user?['email'] ?? 'User Details'),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: _border),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: _primary),
                ),
              )
            else if (_user == null)
              SliverFillRemaining(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load user',
                      style: TextStyle(color: _textDim),
                    ),
                  ],
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildInfoCard(),
                    if (_user?['role'] == 'USER') ...[
                      const SizedBox(height: 20),
                      _buildAdminActions(),
                    ],
                    const SizedBox(height: 24),
                    _buildTransactionsSection(),
                    if (_user?['walletAssignment'] != null) ...[
                      const SizedBox(height: 24),
                      _buildAssignmentSection(),
                    ],
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Header card ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final user = _user!;
    final isAdmin = user['role'] == 'ADMIN';
    final initial =
        (user['firstName']?.toString() ?? user['email']?.toString() ?? '?')
            .substring(0, 1)
            .toUpperCase();
    final userId = 'USR-${user['id'].toString().substring(0, 8).toUpperCase()}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (isAdmin ? _primary : _blue).withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (isAdmin ? _primary : _blue).withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: isAdmin ? _primary : _blue,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (user['firstName'] != null || user['lastName'] != null)
                      ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                            .trim()
                      : user['email'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _RoleBadge(role: user['role']),
                    const SizedBox(width: 8),
                    Text(
                      userId,
                      style: const TextStyle(color: _textDim, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'BALANCE',
                style: TextStyle(
                  color: _textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                NumberFormat('#,##0.00').format(user['balance'] ?? 0),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'USDT',
                style: GoogleFonts.outfit(
                  color: _primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Info rows ────────────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    final user = _user!;
    final joined = DateTime.tryParse(user['createdAt'] ?? '');

    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_outline,
            label: (user['firstName'] != null || user['lastName'] != null)
                ? 'Full Name'
                : 'Identifier',
            value: (user['firstName'] != null || user['lastName'] != null)
                ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim()
                : user['email'],
          ),
          Divider(height: 1, color: _border),
          _InfoRow(
            icon: Icons.mail_outline,
            label: 'Email',
            value: user['email'],
          ),
          Divider(height: 1, color: _border),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Role',
            value: user['role'],
            valueColor: user['role'] == 'ADMIN' ? _primary : Colors.white,
          ),
          if (joined != null) ...[
            Divider(height: 1, color: _border),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Joined',
              value: DateFormat('MMM dd, yyyy').format(joined),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Admin Actions ─────────────────────────────────────────────────────────
  Widget _buildAdminActions() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add, size: 18),
        onPressed: _showManualDepositModal,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary.withOpacity(0.1),
          foregroundColor: _primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _primary.withOpacity(0.3)),
          ),
        ),
        label: const Text(
          'Manual USDT Deposit',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showManualDepositModal() {
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: _primary),
                const SizedBox(width: 12),
                Text(
                  'Credit Account',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Manually credit USDT balance for this user. This creates a COMPLETED deposit logging.',
              style: TextStyle(color: _textDim, fontSize: 12),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: 'Amount (USDT)',
                labelStyle: const TextStyle(color: _textDim, fontSize: 14),
                filled: true,
                fillColor: _bgDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || amount <= 0) return;
                try {
                  final res = await _api.postRequest('/wallet/admin/deposit', {
                    'userId': widget.userId,
                    'amount': amount,
                  });
                  if (res.statusCode == 200 || res.statusCode == 201) {
                    Navigator.pop(ctx);
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Account Credited',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: _primary,
                        ),
                      );
                    _fetchUser();
                  }
                } catch (e) {
                  debugPrint(e.toString());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm Deposit',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Transactions ─────────────────────────────────────────────────────────────
  Widget _buildTransactionsSection() {
    final txs = _user?['transactions'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long, color: _primary, size: 20),
            const SizedBox(width: 10),
            Text(
              'Transactions (${txs.length})',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (txs.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(
                  Icons.show_chart,
                  size: 44,
                  color: Colors.white.withOpacity(0.07),
                ),
                const SizedBox(height: 14),
                const Text(
                  'No transactions yet',
                  style: TextStyle(color: _textDim, fontSize: 14),
                ),
              ],
            ),
          )
        else
          ...txs.map<Widget>((tx) => _buildTxTile(tx as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildTxTile(Map<String, dynamic> tx) {
    final isDeposit = tx['type'] == 'DEPOSIT';
    final status = tx['status'] as String;

    Color statusColor;
    IconData statusIcon;
    if (status == 'COMPLETED') {
      statusColor = _primary;
      statusIcon = Icons.check_circle_outline;
    } else if (status == 'PENDING') {
      statusColor = _blue;
      statusIcon = Icons.access_time;
    } else {
      statusColor = _danger;
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDeposit
                    ? _primary.withOpacity(0.10)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                size: 18,
                color: isDeposit ? _primary : Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['type'].toString()[0] +
                        tx['type'].toString().substring(1).toLowerCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • HH:mm',
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
                  '${isDeposit ? '+' : '-'}${NumberFormat('#,##0.00').format(tx['amount'])} USDT',
                  style: GoogleFonts.outfit(
                    color: isDeposit ? _primary : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
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
      builder: (context) => _TransactionDetailSheet(
        tx: tx,
        onStatusUpdate: (s) => _updateTxStatus(tx['id'], s),
      ),
    ).then((_) => _fetchUser());
  }

  Future<void> _updateTxStatus(String id, String status) async {
    try {
      final res = await _api.patchRequest('/wallet/transactions/$id/status', {
        'status': status,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        _fetchUser();
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Status updated to $status')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status')),
        );
    }
  }

  Widget _buildAssignmentSection() {
    final assignment = _user!['walletAssignment'];
    final wallet = assignment['wallet'];
    final expiresAt = DateTime.tryParse(assignment['expiresAt'] ?? '');
    final now = DateTime.now();
    final isActive = expiresAt != null && expiresAt.isAfter(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.qr_code_2, color: _primary, size: 20),
            const SizedBox(width: 10),
            Text(
              'Active Deposit Gateway',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? _primary.withOpacity(0.3)
                  : _danger.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              _DetailRow(
                label: 'WALLET NAME',
                value:
                    (wallet['name'] != null &&
                        wallet['name'].toString().isNotEmpty)
                    ? wallet['name'].toString().toUpperCase()
                    : '${wallet['network']} GATEWAY',
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'ADDRESS',
                value: wallet['address'],
                valueColor: _primary,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'EXPIRES IN',
                value: isActive
                    ? '${expiresAt.difference(now).inMinutes} minutes'
                    : 'EXPIRED',
                valueColor: isActive ? _primary : _danger,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: _textDim, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _textDim, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'ADMIN';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isAdmin ? _primary : Colors.white).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isAdmin ? _primary : Colors.white).withOpacity(0.20),
        ),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: isAdmin ? _primary : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _TransactionDetailSheet extends StatefulWidget {
  final Map<String, dynamic> tx;
  final Function(String)? onStatusUpdate;

  const _TransactionDetailSheet({required this.tx, this.onStatusUpdate});

  @override
  State<_TransactionDetailSheet> createState() =>
      _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<_TransactionDetailSheet> {
  Map<String, dynamic>? _decrypted;
  bool _isLoadingInfo = false;

  @override
  void initState() {
    super.initState();
    if (widget.tx['type'] == 'EXCHANGE') {
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoadingInfo = true);
    try {
      final storage = const FlutterSecureStorage();
      final privPem = await storage.read(key: 'admin_private_key');

      if (_CryptoHelper.enableE2EE == false ||
          (privPem != null && widget.tx['bankDetails'] != null)) {
        // Attempt decryption
        final api = ApiService();
        final res = await api.getRequest(
          '/wallet/transactions/${widget.tx['id']}',
        );
        if (res.statusCode == 200) {
          final txFull = jsonDecode(res.body);
          final encrypted = txFull['bankDetails'];

          if (encrypted != null) {
            // RSA Decryption
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
    final logs = tx['logs'] as List<dynamic>? ?? [];
    final isDeposit = tx['type'] == 'DEPOSIT';
    final status = tx['status'] as String? ?? 'PENDING';
    final isPending = status == 'PENDING';

    Color statusColor;
    if (status == 'COMPLETED')
      statusColor = _primary;
    else if (status == 'PENDING')
      statusColor = _blue;
    else
      statusColor = _danger;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle fixed at top
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
                            (tx['user']?['firstName'] != null ||
                                tx['user']?['lastName'] != null)
                            ? '${tx['user']?['firstName'] ?? ''} ${tx['user']?['lastName'] ?? ''}'
                                  .trim()
                            : tx['user']?['email'] ?? 'Unknown',
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

                if (!isDeposit) ...[
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
                          ),
                          const SizedBox(height: 8),
                          _infoRow(
                            'Account',
                            _decrypted!['account'] ?? 'Locked',
                          ),
                          const SizedBox(height: 8),
                          _infoRow('Bank', _decrypted!['bank'] ?? 'Private'),
                          const SizedBox(height: 8),
                          _infoRow(
                            'IFSC/Sort',
                            _decrypted!['ifsc'] ?? 'LOCKED',
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
                          'MMM dd, HH:mm',
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
      final privKeyString = pem
          .replaceAll('-----BEGIN PRIVATE KEY-----', '')
          .replaceAll('-----END PRIVATE KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();

      final privateKey = enc.RSAKeyParser().parse(pem) as pc.RSAPrivateKey;
      final crypter = enc.Encrypter(enc.RSA(privateKey: privateKey));

      final decrypted = crypter.decrypt(
        enc.Encrypted.fromBase64(encryptedBase64),
      );
      return decrypted;
    } catch (e) {
      print('RSA Decrypt Error: $e');
      return null;
    }
  }
}
