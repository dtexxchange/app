import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../main.dart' show routeObserver;
import '../services/api_service.dart';
import '../widgets/transaction_detail_sheet.dart';

// ─── Shared Sheet Components ─────────────────────────────────────────────────
class CustomBottomSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const CustomBottomSheet({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class AmountField extends StatelessWidget {
  final TextEditingController controller;
  const AmountField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: '0.00',
        hintStyle: GoogleFonts.outfit(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.10),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }
}

class SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  const SheetField({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.10),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 375.0).clamp(0.85, 1.15);

    return SizedBox(
      height: 52 * scale,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18 * scale),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15 * scale,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const GhostButton({required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 375.0).clamp(0.85, 1.15);

    return SizedBox(
      height: 52 * scale,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(color: Theme.of(context).dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18 * scale),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15 * scale,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Sheet Components ─────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final VoidCallback? onViewHistory;
  const HomeScreen({super.key, this.onViewHistory});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

// Exposed so MainScreen can call refresh via GlobalKey.
class HomeScreenState extends State<HomeScreen> with RouteAware {
  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard => Theme.of(context).cardColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).dividerColor;
  static const Color _blue = Color(0xFF3B82F6);
  static const Color _danger = Color(0xFFF87171);

  double _balance = 0;
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  bool _hasPasscode = true;
  final _api = ApiService();

  double? _conversionRate;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  /// Called when this screen becomes visible again after a pushed route pops.
  @override
  void didPopNext() {
    _fetchData();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Public so MainScreen can trigger a refresh via GlobalKey.
  Future<void> fetchData() => _fetchData();

  Future<void> _fetchData() async {
    try {
      // Parallel fetch for speed
      await Future.wait([
        _api.getRequest('/settings/conversion-rate').then((rateRes) {
          if (rateRes.statusCode == 200) {
            final data = jsonDecode(rateRes.body);
            setState(() {
              _conversionRate = data['usdtToInrRate'] != null
                  ? (data['usdtToInrRate'] as num).toDouble()
                  : null;
            });
          }
        }),
        _api.getRequest('/users/me').then((userRes) {
          if (userRes.statusCode == 200) {
            final data = jsonDecode(userRes.body);
            setState(() {
              _balance = (data['balance'] as num).toDouble();
              _hasPasscode = data['passcode'] != null;
            });
          }
        }),
        // Only fetch the last 10 for the home dashboard
        _api.getRequest('/wallet/transactions?limit=10').then((txRes) {
          if (txRes.statusCode == 200) {
            setState(() {
              _transactions = jsonDecode(txRes.body);
            });
          }
        }),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint(e.toString());
      setState(() => _isLoading = false);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  // Removed _showExchangeSheet - Use dedicated /exchange screen

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final widthScale = (size.width / 375.0).clamp(0.85, 1.2);
    final isSmall = size.width < 360;

    return Scaffold(
      backgroundColor: _bgDark,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: _primary,
              backgroundColor: _bgCard,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildAppBar(context),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      (isSmall ? 16 : 24) * widthScale,
                      8,
                      (isSmall ? 16 : 24) * widthScale,
                      100 * widthScale,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (!_hasPasscode) _buildPasscodeWarning(context),
                        _buildBalanceCard(context),
                        const SizedBox(height: 24),
                        _buildRateCard(context),
                        const SizedBox(height: 32),
                        _buildTransactionsSection(context),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRateCard(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final widthScale = (size.width / 375.0).clamp(0.85, 1.2);
    final isSmall = size.width < 360;
    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 24),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _blue.withOpacity(0.2)),
            ),
            child: const Icon(Icons.show_chart, color: _blue, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONVERSION RATE',
                  style: GoogleFonts.inter(
                    color: _textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _conversionRate != null
                      ? '₹${_conversionRate!.toStringAsFixed(2)}'
                      : 'Not Set',
                  style: GoogleFonts.outfit(
                    fontSize: 24 * widthScale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildPasscodeWarning(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      decoration: BoxDecoration(
        color: _danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _danger.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _danger, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Passcode Required',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Please add a passcode for secure exchanges.',
                  style: GoogleFonts.inter(color: _textDim, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(
              context,
              '/passcode',
            ).then((_) => _fetchData()),
            child: Text(
              'SET NOW',
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return SliverAppBar(
      pinned: true,
      backgroundColor: _bgDark.withOpacity(0.9),
      elevation: 0,
      titleSpacing: isSmall ? 16 : 24,
      title: Row(
        children: [
          Container(
            width: isSmall ? 32 : 36,
            height: isSmall ? 32 : 36,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _primary.withOpacity(0.20)),
            ),
            child: Icon(
              Icons.diamond_outlined,
              color: _primary,
              size: isSmall ? 16 : 18,
            ),
          ),
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(
                fontSize: isSmall ? 18 : 22,
                fontWeight: FontWeight.w700,
              ),
              children: [
                const TextSpan(text: 'USDT'),
                TextSpan(
                  text: '.EX',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              await _api.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            child: Container(
              width: isSmall ? 32 : 36,
              height: isSmall ? 32 : 36,
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _danger.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.logout,
                color: _danger,
                size: isSmall ? 16 : 18,
              ),
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final widthScale = (size.width / 375.0).clamp(0.85, 1.2);
    final isSmall = size.width < 360;
    final isShort = size.height < 700;

    return Container(
      padding: EdgeInsets.all(isSmall ? 20 : 28),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AVAILABLE BALANCE',
                style: GoogleFonts.inter(
                  color: _textDim,
                  fontSize: isSmall ? 9 : 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: isSmall ? 1 : 2,
                ),
              ),
              Container(
                width: isSmall ? 40 : 48,
                height: isSmall ? 40 : 48,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _primary.withOpacity(0.20)),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: _primary,
                  size: isSmall ? 18 : 22,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 8 : 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  NumberFormat('#,##0.00').format(_balance),
                  style: GoogleFonts.outfit(
                    fontSize: isSmall ? 32 * widthScale : 42 * widthScale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'USDT',
                  style: GoogleFonts.outfit(
                    color: _textDim,
                    fontSize: isSmall ? 14 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_conversionRate != null) ...[
            SizedBox(height: 4 * widthScale),
            Text(
              '≈ ₹${NumberFormat('#,##0.00').format(_balance * _conversionRate!)}',
              style: GoogleFonts.outfit(
                color: _primary.withOpacity(0.7),
                fontSize: 14 * widthScale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          SizedBox(height: isShort ? 20 * widthScale : 28 * widthScale),
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Add Money',
                      icon: Icons.add_circle_outline,
                      onPressed: () => Navigator.pushNamed(context, '/deposit'),
                    ),
                  ),
                  SizedBox(width: constraints.maxWidth * 0.04),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Exchange',
                      icon: Icons.account_balance,
                      onPressed: () async {
                        final res = await Navigator.pushNamed(
                          context,
                          '/exchange',
                        );
                        if (res == true) _fetchData();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: _primary,
                  size: isSmall ? 18 : 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Recent Activity',
                  style: GoogleFonts.outfit(
                    fontSize: isSmall ? 18 : 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            // "View All" button in the header
            if (_transactions.isNotEmpty)
              TextButton(
                onPressed: () => widget.onViewHistory?.call(),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: _primary,
                    fontSize: isSmall ? 12 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_transactions.isEmpty)
          _buildEmptyState()
        else
          ..._transactions.map((tx) => _buildTxTile(tx, context)),
        if (_transactions.isNotEmpty) ...[
          const SizedBox(height: 16),
          // Full-width "View All History" footer button
          GestureDetector(
            onTap: () => widget.onViewHistory?.call(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Full History',
                    style: TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w700,
                      fontSize: isSmall ? 13 : 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: _primary, size: 16),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(color: _textDim, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTxTile(Map<String, dynamic> tx, BuildContext context) {
    final isDeposit = tx['type'] == 'DEPOSIT';
    final status = tx['status'] as String? ?? 'PENDING';
    final isSmall = MediaQuery.of(context).size.width < 360;

    Color statusColor = _textDim;
    Color statusBg = _textDim.withOpacity(0.08);
    IconData statusIcon = Icons.help_outline;
    if (status == 'COMPLETED') {
      statusColor = _primary;
      statusBg = _primary.withOpacity(0.08);
      statusIcon = Icons.check_circle_outline;
    } else if (status == 'PENDING') {
      statusColor = _blue;
      statusBg = _blue.withOpacity(0.08);
      statusIcon = Icons.access_time;
    } else if (status == 'REJECTED') {
      statusColor = const Color(0xFFF87171);
      statusBg = const Color(0xFFF87171).withOpacity(0.08);
      statusIcon = Icons.cancel_outlined;
    }

    return GestureDetector(
      onTap: () => _showTransactionDetail(tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: isSmall ? 40 : 44,
              height: isSmall ? 40 : 44,
              decoration: BoxDecoration(
                color: isDeposit
                    ? _primary.withOpacity(0.10)
                    : _blue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                size: isSmall ? 18 : 20,
                color: isDeposit ? _primary : _blue,
              ),
            ),
            SizedBox(width: isSmall ? 10 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['type'].toString().toLowerCase().capitalize(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,

                      fontSize: isSmall ? 14 : 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'TX-${tx['id']?.toString().substring(0, 8).toUpperCase() ?? 'UNKNOWN'}',
                    style: TextStyle(
                      color: _textDim,
                      fontSize: isSmall ? 10 : 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isDeposit ? '+' : '-'}${NumberFormat('#,##0.00').format(tx['amount'] as num)} USDT',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: isSmall ? 14 : 15,
                    color: isDeposit
                        ? _primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
                          fontWeight: FontWeight.w700,
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
      builder: (context) => TransactionDetailSheet(tx: tx),
    ).then((_) => _fetchData());
  }
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
