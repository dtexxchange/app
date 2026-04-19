import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../main.dart' show routeObserver;
import '../services/api_service.dart';
import '../services/crypto_service.dart';

// ─── Design Tokens ───────────────────────────────────────────────────────────
const _bgDark = Color(0xFF0A0B0D);
const _bgCard = Color(0xFF15171C);
const _primary = Color(0xFF00FF9D);
const _blue = Color(0xFF3B82F6);
const _textDim = Color(0xFF94A3B8);
const _border = Color(0x0DFFFFFF); // 5% white
const _danger = Color(0xFFF87171);

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
      decoration: const BoxDecoration(
        color: Color(0xFF15171C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: Colors.white.withOpacity(0.15),
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
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: '0.00',
        hintStyle: GoogleFonts.outfit(
          color: Colors.white.withOpacity(0.2),
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00FF9D)),
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
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00FF9D)),
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
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00FF9D),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.15)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback? onViewHistory;
  const HomeScreen({super.key, this.onViewHistory});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

// Exposed so MainScreen can call refresh via GlobalKey.
class HomeScreenState extends State<HomeScreen> with RouteAware {
  double _balance = 0;
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  bool _hasPasscode = true;
  final _api = ApiService();

  // QR Logic
  List<dynamic> _wallets = [];
  Timer? _timer;
  int _timeLeft = 1800; // 30 minutes in seconds
  String _qrSeed = "";
  double? _conversionRate;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchWallets();
    _fetchConversionRate();
    _startTimer();
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
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    // Default to 30 mins if not set yet, but it will be updated by _fetchWallets
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
            _fetchWallets(); // Refresh when timer hits 0 to get next assignment
          }
        });
      }
    });
  }

  void _generateQrData() {
    // Add a timestamp to regenerate the QR code visually even if ID is same
    setState(() {
      _qrSeed = '?t=${DateTime.now().millisecondsSinceEpoch}';
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _timerColor() {
    if (_timeLeft < 60) return Colors.redAccent;
    if (_timeLeft < 300) return Colors.orangeAccent;
    return _primary;
  }

  Future<void> _fetchWallets() async {
    try {
      final res = await _api.getRequest('/settings/wallets');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _wallets = data;
          if (_wallets.isNotEmpty && _wallets[0]['expiresAt'] != null) {
            final expiresAt = DateTime.parse(_wallets[0]['expiresAt']);
            final now = DateTime.now();
            _timeLeft = expiresAt.difference(now).inSeconds;
            if (_timeLeft < 0) _timeLeft = 0;
          }
          _generateQrData();
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _fetchConversionRate() async {
    try {
      final res = await _api.getRequest('/settings/conversion-rate');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _conversionRate = data['usdtToInrRate'] != null
              ? (data['usdtToInrRate'] as num).toDouble()
              : null;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /// Public so MainScreen can trigger a refresh via GlobalKey.
  Future<void> fetchData() => _fetchData();

  Future<void> _fetchData() async {
    try {
      final userRes = await _api.getRequest('/users/me');
      if (userRes.statusCode == 200) {
        final data = jsonDecode(userRes.body);
        setState(() {
          _balance = (data['balance'] as num).toDouble();
          _hasPasscode = data['passcode'] != null;
        });
      }

      // Only fetch the last 10 for the home dashboard
      final txRes = await _api.getRequest('/wallet/transactions?limit=10');
      if (txRes.statusCode == 200) {
        setState(() {
          _transactions = jsonDecode(txRes.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() => _isLoading = false);
    }
  }

  // ─── Deposit Sheet ──────────────────────────────────────────────────────────
  void _showDepositSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomBottomSheet(
        title: 'Add Money',
        icon: Icons.arrow_downward,
        iconColor: _primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rate Information
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: _primary, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _conversionRate != null
                          ? 'Current Rate: 1 USDT = ₹${_conversionRate!.toStringAsFixed(2)}'
                          : 'Rate not yet configured by admin.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_wallets.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: const Text(
                  'No deposit gateways available currently',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textDim),
                ),
              ),

            ..._wallets.map((wallet) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _bgDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (wallet['name'] != null &&
                                  wallet['name'].toString().isNotEmpty)
                              ? wallet['name'].toString().toUpperCase()
                              : '${wallet['network']} GATEWAY',
                          style: GoogleFonts.inter(
                            color: _primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: wallet['address']),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Address copied to clipboard'),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.copy, color: _primary, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'COPY',
                                style: GoogleFonts.inter(
                                  color: _primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: '${wallet['address']}$_qrSeed',
                        version: QrVersions.auto,
                        size: 140.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    Text(
                      wallet['address'],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _timerColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _timerColor().withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: _timerColor(),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'REFRESHING IN: ${_formatTime(_timeLeft)}',
                            style: GoogleFonts.inter(
                              color: _timerColor(),
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Removed _showExchangeSheet - Use dedicated /exchange screen

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;

    return Scaffold(
      backgroundColor: _bgDark,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
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
                      isSmall ? 16 : 24,
                      8,
                      isSmall ? 16 : 24,
                      100,
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
    final isSmall = MediaQuery.of(context).size.width < 360;
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
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _conversionRate != null
                      ? '₹${_conversionRate!.toStringAsFixed(2)}'
                      : 'Not Set',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0x1AFFFFFF),
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
          const Icon(Icons.warning_amber_rounded, color: _danger, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Passcode Required',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
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
            child: const Text(
              'SET NOW',
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.bold,
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
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              children: [
                const TextSpan(text: 'USDT'),
                TextSpan(
                  text: '.EX',
                  style: TextStyle(color: Colors.white.withOpacity(0.4)),
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
                  fontWeight: FontWeight.bold,
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
                    color: Colors.white,
                    fontSize: isSmall ? 32 : 42,
                    fontWeight: FontWeight.bold,
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
            const SizedBox(height: 4),
            Text(
              '≈ ₹${NumberFormat('#,##0.00').format(_balance * _conversionRate!)}',
              style: GoogleFonts.outfit(
                color: _primary.withOpacity(0.7),
                fontSize: isSmall ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          SizedBox(height: isShort ? 24 : 32),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Add Money',
                  icon: Icons.add_circle_outline,
                  onPressed: _showDepositSheet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Exchange',
                  icon: Icons.account_balance,
                  onPressed: () async {
                    final res = await Navigator.pushNamed(context, '/exchange');
                    if (res == true) _fetchData();
                  },
                ),
              ),
            ],
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
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                    fontWeight: FontWeight.bold,
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
                      fontWeight: FontWeight.bold,
                      fontSize: isSmall ? 13 : 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: _primary, size: 16),
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
            color: Colors.white.withOpacity(0.1),
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
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                size: isSmall ? 18 : 20,
                color: isDeposit ? _primary : Colors.white,
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
                      color: Colors.white,
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
                    fontWeight: FontWeight.bold,
                    fontSize: isSmall ? 14 : 15,
                    color: isDeposit ? _primary : Colors.white,
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
      builder: (context) => _TransactionDetailSheet(tx: tx),
    ).then((_) => _fetchData());
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionDetailSheet({required this.tx});

  @override
  Widget build(BuildContext context) {
    final status = tx['status'] as String? ?? 'PENDING';
    final logs = tx['logs'] as List<dynamic>? ?? [];
    final isDeposit = tx['type'] == 'DEPOSIT';
    final bank = (!isDeposit && tx['bankDetails'] != null)
        ? CryptoService.decrypt(tx['bankDetails'])
        : null;

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
                          'Transaction Details',
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

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _bgDark,
                    border: Border.all(color: _border),
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
                        valueColor: isDeposit ? _primary : Colors.white,
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
                          valueColor: _blue,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                if (bank != null) ...[
                  const Text(
                    'EXCHANGE INSTRUCTIONS',
                    style: TextStyle(
                      color: _textDim,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _bgDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primary.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _infoRow('Beneficiary', bank['name'] ?? 'Unknown'),
                        const SizedBox(height: 8),
                        _infoRow('Account', bank['account'] ?? 'Locked'),
                        const SizedBox(height: 8),
                        _infoRow('Bank', bank['bank'] ?? 'Private'),
                        const SizedBox(height: 8),
                        _infoRow(
                          'IFSC/Sort',
                          bank['ifsc'] ?? 'LOCKED',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                const Text(
                  'ACTIVITY LOGS',
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
                      'No activity history found',
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                  const SizedBox(height: 4),
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

// Removed passcode entry sheet - Use dedicated /exchange-passcode screen

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
