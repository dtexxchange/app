import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import 'transaction_detail_screen.dart';

class LiveTimerWidget extends StatefulWidget {
  final DateTime expiresAt;
  const LiveTimerWidget({super.key, required this.expiresAt});

  @override
  State<LiveTimerWidget> createState() => _LiveTimerWidgetState();
}

class _LiveTimerWidgetState extends State<LiveTimerWidget> {
  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color get primary => Theme.of(context).primaryColor;
  Color get _danger => const Color(0xFFF87171);

  Timer? _timer;
  late int _timeLeft;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _startTimer();
  }

  @override
  void didUpdateWidget(LiveTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _calculateTimeLeft();
    }
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    _timeLeft = widget.expiresAt.difference(now).inSeconds;
    if (_timeLeft < 0) _timeLeft = 0;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTimeLeft();
          if (_timeLeft <= 0) {
            _timer?.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _timerColor() {
    if (_timeLeft <= 0) return _danger;
    if (_timeLeft < 60) return Colors.redAccent;
    if (_timeLeft < 300) return Colors.orangeAccent;
    return primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _timerColor();
    final isExpired = _timeLeft <= 0;
    return Text(
      isExpired ? 'EXPIRED' : '${_formatTime(_timeLeft)} minutes left',
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
    );
  }
}

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final List<dynamic>? allUsers;
  const UserDetailScreen({super.key, required this.userId, this.allUsers});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard => Theme.of(context).cardColor;
  Color get primary => Theme.of(context).primaryColor;
  Color get textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).dividerColor;
  static const Color _blue = Color(0xFF3B82F6);
  static const Color _danger = Color(0xFFF87171);
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
    final size = MediaQuery.of(context).size;
    final widthScale = (size.width / 375.0).clamp(0.85, 1.2);

    return Scaffold(
      backgroundColor: _bgDark,
      body: RefreshIndicator(
        onRefresh: _fetchUser,
        color: primary,
        backgroundColor: _bgCard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: _bgDark.withValues(alpha: 0.95),
              elevation: 0,
              titleSpacing: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
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
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: _border),
              ),
            ),
            if (_isLoading)
              SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: primary)),
              )
            else if (_user == null)
              SliverFillRemaining(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load user',
                      style: TextStyle(color: textDim),
                    ),
                  ],
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  24 * widthScale,
                  24,
                  24 * widthScale,
                  80,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(widthScale),
                    const SizedBox(height: 20),
                    _buildInfoCard(widthScale),
                    if (_user?['status'] == 'PENDING_APPROVAL') ...[
                      const SizedBox(height: 20),
                      _buildApprovalActions(widthScale),
                    ],
                    if (_user?['role'] == 'USER') ...[
                      const SizedBox(height: 20),
                      _buildAdminActions(),
                    ],
                    const SizedBox(height: 24),
                    _buildTransactionsSection(widthScale),
                    if (_user?['walletAssignments'] != null &&
                        (_user!['walletAssignments'] as List).isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildAssignmentSection(widthScale),
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
  Widget _buildHeader(double widthScale) {
    final user = _user!;
    final isAdmin = user['role'] == 'ADMIN';
    final initial =
        (user['firstName']?.toString() ?? user['email']?.toString() ?? '?')
            .substring(0, 1)
            .toUpperCase();

    return Container(
      padding: EdgeInsets.all(24 * widthScale),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64 * widthScale,
            height: 64 * widthScale,
            decoration: BoxDecoration(
              color: (isAdmin ? primary : _blue).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (isAdmin ? primary : _blue).withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: isAdmin ? primary : _blue,
                  fontSize: 26 * widthScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16 * widthScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (user['firstName'] != null || user['lastName'] != null)
                      ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                            .trim()
                      : user['email'],
                  style: TextStyle(
                    fontSize: 16 * widthScale,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6 * widthScale),
                _RoleBadge(role: user['role'], widthScale: widthScale),
              ],
            ),
          ),
          SizedBox(width: 12 * widthScale),
          // Balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'BALANCE',
                style: TextStyle(
                  color: textDim,
                  fontSize: 10 * widthScale,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5 * widthScale,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  NumberFormat('#,##0.00').format(user['balance'] ?? 0),
                  style: GoogleFonts.outfit(
                    fontSize: 22 * widthScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'USDT',
                style: GoogleFonts.outfit(
                  color: primary,
                  fontSize: 12 * widthScale,
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
  Widget _buildInfoCard(double widthScale) {
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
            label: 'User ID',
            value: user['readableId'],
            widthScale: widthScale,
          ),
          Divider(height: 1, color: _border),
          _InfoRow(
            icon: Icons.person_outline,
            label: (user['firstName'] != null || user['lastName'] != null)
                ? 'Full Name'
                : 'Identifier',
            value: (user['firstName'] != null || user['lastName'] != null)
                ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim()
                : user['email'],
            widthScale: widthScale,
          ),
          Divider(height: 1, color: _border),
          _InfoRow(
            icon: Icons.mail_outline,
            label: 'Email',
            value: user['email'],
            widthScale: widthScale,
          ),
          Divider(height: 1, color: _border),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Role',
            value: user['role'],
            valueColor: user['role'] == 'ADMIN'
                ? primary
                : Theme.of(context).colorScheme.onSurface,
            widthScale: widthScale,
          ),
          Divider(height: 1, color: _border),
          _InfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Status',
            value: (user['status']?.toString() ?? 'APPROVED').replaceAll(
              '_',
              ' ',
            ),
            valueColor: user['status'] == 'PENDING_APPROVAL'
                ? _blue
                : user['status'] == 'REJECTED'
                ? _danger
                : primary,
            widthScale: widthScale,
          ),
          if (joined != null) ...[
            Divider(height: 1, color: _border),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Joined',
              value: DateFormat('MMM dd, yyyy').format(joined),
              widthScale: widthScale,
            ),
          ],
        ],
      ),
    );
  }

  // ─── Approval Actions ────────────────────────────────────────────────────────

  Widget _buildApprovalActions(double widthScale) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.check, size: 18 * widthScale),
            onPressed: () => _updateUserStatus('APPROVED'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 14 * widthScale),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            label: Text(
              'Approve',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13 * widthScale,
              ),
            ),
          ),
        ),
        SizedBox(width: 12 * widthScale),
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.close, size: 18 * widthScale),
            onPressed: () => _updateUserStatus('REJECTED'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger.withValues(alpha: 0.1),
              foregroundColor: _danger,
              padding: EdgeInsets.symmetric(vertical: 14 * widthScale),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _danger.withValues(alpha: 0.3)),
              ),
            ),
            label: Text(
              'Reject',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13 * widthScale,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateUserStatus(String status) async {
    try {
      final res = await _api.patchRequest('/users/${widget.userId}/status', {
        'status': status,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User marked as ${status.replaceAll('_', ' ')}'),
              backgroundColor: status == 'APPROVED' ? primary : _danger,
            ),
          );
        }
        _fetchUser();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // ─── Admin Actions ─────────────────────────────────────────────────────────
  Widget _buildAdminActions() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(Icons.add, size: 18),
        onPressed: _showManualDepositModal,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary.withValues(alpha: 0.1),
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: primary.withValues(alpha: 0.3)),
          ),
        ),
        label: Text(
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
                Icon(Icons.account_balance_wallet, color: primary),
                const SizedBox(width: 12),
                Text(
                  'Credit Account',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manually credit USDT balance for this user. This creates a COMPLETED deposit logging.',
              style: TextStyle(color: textDim, fontSize: 12),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Amount (USDT)',
                labelStyle: TextStyle(color: textDim, fontSize: 14),
                filled: true,
                fillColor: _bgDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primary),
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
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Account Credited'),
                          backgroundColor: primary,
                        ),
                      );
                    }
                    _fetchUser();
                  }
                } catch (e) {
                  debugPrint(e.toString());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
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
  Widget _buildTransactionsSection(double widthScale) {
    final txs = _user?['transactions'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.receipt_long, color: primary, size: 20 * widthScale),
            SizedBox(width: 10 * widthScale),
            Text(
              'Transactions (${txs.length})',
              style: GoogleFonts.outfit(
                fontSize: 20 * widthScale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16 * widthScale),
        if (txs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions found',
                    style: TextStyle(color: textDim, fontSize: 13),
                  ),
                ],
              ),
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
      statusColor = primary;
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
                    ? primary.withValues(alpha: 0.10)
                    : _blue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                size: 18,
                color: isDeposit ? primary : _blue,
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
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • hh:mm a',
                    ).format(DateTime.parse(tx['createdAt'])),
                    style: TextStyle(color: textDim, fontSize: 11),
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
                    color: isDeposit
                        ? primary
                        : Theme.of(context).colorScheme.onSurface,
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
                    color: statusColor.withValues(alpha: 0.08),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(
          tx: tx,
          onStatusUpdate: (s, {utr}) => _updateTxStatus(tx['id'], s, utr: utr),
          allUsers: widget.allUsers,
        ),
      ),
    ).then((_) => _fetchUser());
  }

  Future<void> _updateTxStatus(String id, String status, {String? utr}) async {
    try {
      final res = await _api.patchRequest('/wallet/transactions/$id/status', {
        'status': status,
        'utr': utr,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        _fetchUser();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Status updated to $status')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status')),
        );
      }
    }
  }

  Widget _buildAssignmentSection(double widthScale) {
    final assignments = _user?['walletAssignments'] as List?;
    if (assignments == null || assignments.isEmpty) return const SizedBox();

    final assignment = assignments[0];
    final wallet = assignment['wallet'];
    final expiresAt = DateTime.tryParse(assignment['expiresAt'] ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.qr_code_2, color: primary, size: 20 * widthScale),
            SizedBox(width: 10 * widthScale),
            Text(
              'Active Deposit Gateway',
              style: GoogleFonts.outfit(
                fontSize: 20 * widthScale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16 * widthScale),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary.withValues(alpha: 0.3)),
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
                widthScale: widthScale,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'ADDRESS',
                value: wallet['address'],
                valueColor: primary,
                widthScale: widthScale,
              ),
              if (expiresAt != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'EXPIRES IN',
                      style: TextStyle(
                        color: textDim,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    LiveTimerWidget(expiresAt: expiresAt),
                  ],
                ),
              ],
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
  final double widthScale;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.widthScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final textDim = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20 * widthScale,
        vertical: 16 * widthScale,
      ),
      child: Row(
        children: [
          Icon(icon, color: textDim, size: 20 * widthScale),
          SizedBox(width: 14 * widthScale),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: textDim, fontSize: 13 * widthScale),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                fontSize: 13 * widthScale,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  final double widthScale;
  const _RoleBadge({required this.role, this.widthScale = 1.0});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isAdmin = role == 'ADMIN';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8 * widthScale,
        vertical: 3 * widthScale,
      ),
      decoration: BoxDecoration(
        color: (isAdmin ? primary : Theme.of(context).colorScheme.onSurface)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isAdmin ? primary : Theme.of(context).colorScheme.onSurface)
              .withValues(alpha: 0.20),
        ),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: isAdmin ? primary : Theme.of(context).colorScheme.onSurface,
          fontSize: 10 * widthScale,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final double widthScale;
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.widthScale = 1.0,
  });

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
            fontSize: 10 * widthScale,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              fontSize: 13 * widthScale,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
