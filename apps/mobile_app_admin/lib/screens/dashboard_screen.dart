import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../main.dart' show themeService;
import '../services/api_service.dart';
import '../widgets/transaction_detail_sheet.dart';
import 'assignments_screen.dart';
import 'user_detail_screen.dart';
import 'wallets_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard => Theme.of(context).cardColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).dividerColor;
  Color get _onSurface => Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A);
  static const Color _blue = Color(0xFF3B82F6);
  static const Color _danger = Color(0xFFF87171);

  final _api = ApiService();
  int _tabIndex = 0;

  List<dynamic> _users = [];
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  // Filters
  String _txStatus = '';
  String _txType = '';
  String _userSearch = '';

  double? _conversionRate;
  List<dynamic> _rateHistory = [];
  final _rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAll();
    _checkMobileKeys();
    _fetchConversionRate();
    _fetchRateHistory();
  }

  bool _hasMobileKey = false;
  final _storage = const FlutterSecureStorage();

  Future<void> _checkMobileKeys() async {
    final key = await _storage.read(key: 'admin_private_key');
    if (mounted) setState(() => _hasMobileKey = key != null);
  }

  Future<void> _fetchConversionRate() async {
    try {
      final res = await _api.getRequest('/settings/conversion-rate');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _conversionRate = data['usdtToInrRate'] != null
                ? (data['usdtToInrRate'] as num).toDouble()
                : null;
            if (_conversionRate != null) {
              _rateController.text = _conversionRate!.toStringAsFixed(2);
            }
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _fetchRateHistory() async {
    try {
      final res = await _api.getRequest('/settings/conversion-rate/history');
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _rateHistory = jsonDecode(res.body);
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _saveConversionRate() async {
    try {
      final rate = double.tryParse(_rateController.text);
      if (rate == null) {
        _showSnack('Invalid rate value');
        return;
      }
      final res = await _api.patchRequest('/settings/conversion-rate', {
        'rate': rate,
      });
      if (res.statusCode == 200) {
        _showSnack('Conversion rate updated', success: true);
        _fetchConversionRate();
        _fetchRateHistory();
      } else {
        _showSnack('Failed to update rate');
      }
    } catch (e) {
      _showSnack('Error updating rate');
    }
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    try {
      final txParams = <String>[];
      if (_txStatus.isNotEmpty) txParams.add('status=$_txStatus');
      if (_txType.isNotEmpty) txParams.add('type=$_txType');
      final txQ = txParams.isEmpty ? '' : '?${txParams.join('&')}';

      final uParams = _userSearch.isNotEmpty ? '?search=$_userSearch' : '';

      final txRes = await _api.getRequest('/wallet/transactions$txQ');
      final uRes = await _api.getRequest('/users$uParams');

      if (mounted) {
        setState(() {
          if (txRes.statusCode == 200) _transactions = jsonDecode(txRes.body);
          if (uRes.statusCode == 200) _users = jsonDecode(uRes.body);
          _isLoading = false;
        });
      }
      _fetchConversionRate(); // Keep rate fresh
      _fetchRateHistory();
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTxStatus(
    String id,
    String status, {
    bool confirmed = false,
  }) async {
    if (!confirmed) {
      final proceed = await _showConfirmDialog(
        title: '${status == 'COMPLETED' ? 'Approve' : 'Reject'} Transaction',
        message: 'Are you sure you want to mark this transaction as $status?',
      );
      if (proceed != true) return;
    }

    try {
      await _api.patchRequest('/wallet/transactions/$id/status', {
        'status': status,
      });
      _fetchAll();
      _showSnack('Status updated to $status', success: true);
    } catch (e) {
      _showSnack('Failed to update status');
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: TextStyle(color: _textDim, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: _textDim)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Proceed',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: success ? _primary : _danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final widthScale = (size.width / 375.0).clamp(0.85, 1.2);

    return Scaffold(
      backgroundColor: _bgDark,
      body: Column(
        children: [
          _buildTopBar(widthScale),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _primary))
                : RefreshIndicator(
                    onRefresh: _fetchAll,
                    color: _primary,
                    backgroundColor: _bgCard,
                    child: _buildTabContent(widthScale),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (i) => setState(() => _tabIndex = i),
          backgroundColor: _bgDark,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _primary,
          unselectedItemColor: _textDim,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.currency_exchange_outlined),
              activeIcon: Icon(Icons.currency_exchange),
              label: 'Exchange',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(double widthScale) {
    return Container(
      decoration: BoxDecoration(
        color: _bgDark.withOpacity(0.9),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24 * widthScale,
            16,
            24 * widthScale,
            16,
          ),
          child: Row(
            children: [
              Container(
                width: 36 * widthScale,
                height: 36 * widthScale,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _primary.withOpacity(0.20)),
                ),
                child: Icon(
                  Icons.diamond_outlined,
                  color: _primary,
                  size: 18 * widthScale,
                ),
              ),
              const SizedBox(width: 12),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _onSurface,
                  ),
                  children: [
                    const TextSpan(text: 'USDT'),
                    TextSpan(
                      text: '.EX',
                      style: TextStyle(color: _onSurface.withOpacity(0.4)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primary.withOpacity(0.20)),
                ),
                child: Text(
                  'ADMIN',
                  style: GoogleFonts.inter(
                    color: _primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  await _api.logout();
                  if (mounted)
                    Navigator.pushReplacementNamed(context, '/login');
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _danger.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.logout, color: _danger, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(double widthScale) {
    switch (_tabIndex) {
      case 0:
        return _buildOverview(widthScale);
      case 1:
        return _buildUsers(widthScale);
      case 2:
        return _buildExchange(widthScale);
      case 3:
        return _buildSettings(widthScale);
      default:
        return const SizedBox();
    }
  }

  // ─── EXCHANGE TAB ─────────────────────────────────────────────────────────────
  Widget _buildExchange(double widthScale) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'EXCHANGE CONFIGURATION',
          style: GoogleFonts.inter(
            color: _textDim,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.currency_exchange, color: _blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conversion Rate',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '1 USDT = X INR',
                          style: TextStyle(color: _textDim, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (_conversionRate == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LOCK ACTIVE',
                        style: TextStyle(
                          color: _danger,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Current USDT/INR Rate',
                  labelStyle: TextStyle(color: _textDim, fontSize: 12),
                  hintText: 'e.g. 88.5',
                  filled: true,
                  fillColor: _bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _border),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveConversionRate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Rate & Unlock',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (_rateHistory.isNotEmpty) ...[
                const SizedBox(height: 24),
                Divider(color: _border),
                const SizedBox(height: 16),
                Text(
                  'RECENT CHANGES',
                  style: TextStyle(
                    color: _textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ..._rateHistory
                    .take(10)
                    .map(
                      (h) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${(h['rate'] as num).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'MMM dd, hh:mm a',
                              ).format(DateTime.parse(h['createdAt'])),
                              style: TextStyle(color: _textDim, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── SETTINGS TAB ─────────────────────────────────────────────────────────────
  Widget _buildSettings(double widthScale) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'PLATFORM CONFIGURATION',
          style: GoogleFonts.inter(
            color: _textDim,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settlement Gateways',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Manage active deposit addresses',
                          style: TextStyle(color: _textDim, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WalletsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Manage Gateways',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.history_toggle_off, color: _blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live QR Assignments',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'See who currently has a wallet assigned',
                          style: TextStyle(color: _textDim, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AssignmentsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View Assignments',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appearance',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Toggle between Light and Dark mode',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: Theme.of(context).brightness == Brightness.dark,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (v) => themeService.toggleTheme(),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        Text(
          'SECURITY & INFRASTRUCTURE',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hasMobileKey
                  ? _primary.withOpacity(0.2)
                  : _danger.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (_hasMobileKey ? _primary : _danger).withOpacity(
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _hasMobileKey
                          ? Icons.shield_outlined
                          : Icons.shield_moon_outlined,
                      color: _hasMobileKey ? _primary : _danger,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasMobileKey
                              ? 'Active Security'
                              : 'Insecure Terminal',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _hasMobileKey
                              ? 'E2EE Decryption Enabled'
                              : 'Private Key Missing',
                          style: TextStyle(color: _textDim, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'End-to-End Encryption ensures exchange details are only visible to authorized administrators. You must possess the matching Private Key for the current Public Key.',
                style: TextStyle(color: _textDim, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showImportKeyModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.05),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: const Text('Import PEM'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _hasMobileKey ? null : _generateKeysOnMobile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Setup New Keys',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showImportKeyModal() {
    final ctrl = TextEditingController();
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
            Text(
              'Import Private Key',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Paste the content of your .pem file below to enable decryption on this device.',
              style: TextStyle(color: _textDim, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: ctrl,
              maxLines: 8,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '-----BEGIN PRIVATE KEY-----\n...',
                hintStyle: TextStyle(color: _textDim.withOpacity(0.3)),
                filled: true,
                fillColor: _bgDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _border),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.contains('BEGIN PRIVATE KEY')) {
                  await _storage.write(
                    key: 'admin_private_key',
                    value: ctrl.text,
                  );
                  await _checkMobileKeys();
                  Navigator.pop(ctx);
                  _showSnack('Key imported successfully!', success: true);
                } else {
                  _showSnack('Invalid PEM format');
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
                'Save Master Key',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateKeysOnMobile() async {
    final proceed = await _showConfirmDialog(
      title: 'Infrastructure Reset',
      message:
          'Generating new keys will invalidate active pending exchanges. You must save the .pem content immediately after generation. This is a ONE-TIME process. Proceed?',
    );
    if (proceed != true) return;

    setState(() => _isLoading = true);
    try {
      // For this demo, we'll suggest using Web for Gen, but here we'll mock the mobile generation
      // as RSA generation is heavy for Flutter main thread without isolates.
      await Future.delayed(const Duration(seconds: 2));
      const mockPriv =
          '-----BEGIN PRIVATE KEY-----\nMOCK_MOBILE_KEY_DATA\n-----END PRIVATE KEY-----';
      const mockPub = 'MOCK_PUBLIC_KEY';

      await _api.patchRequest('/wallet/admin/public-key', {
        'publicKey': mockPub,
      });
      await _storage.write(key: 'admin_private_key', value: mockPriv);
      await _checkMobileKeys();

      _showSnack('Infrastructure Reset Complete', success: true);
      _showKeySuccessModal(mockPriv);
    } catch (e) {
      _showSnack('Failed to generate keys');
    }
    setState(() => _isLoading = false);
  }

  void _showKeySuccessModal(String pem) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Master Key Ready',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Private Key is valid. Copy this content and save it as admin_private_key.pem securely. You will NOT see this again.',
              style: TextStyle(color: _textDim, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bgDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                pem,
                style: TextStyle(
                  color: _primary,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('I Have Saved It Safely'),
          ),
        ],
      ),
    );
  }

  // ─── OVERVIEW TAB ─────────────────────────────────────────────────────────────
  Widget _buildOverview(double widthScale) {
    final pending = _transactions.where((t) => t['status'] == 'PENDING').length;
    final isSmall = MediaQuery.of(context).size.width < 360;

    return ListView(
      padding: EdgeInsets.fromLTRB(22 * widthScale, 8, 22 * widthScale, 100),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // Stats row
        if (isSmall) ...[
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Users',
                  value: _users.length.toString(),
                  icon: Icons.people_outline,
                  iconColor: _blue,
                  widthScale: widthScale,
                ),
              ),
              SizedBox(width: 12 * widthScale),
              Expanded(
                child: _StatCard(
                  label: 'Pending',
                  value: pending.toString(),
                  icon: Icons.access_time,
                  iconColor: _blue,
                  widthScale: widthScale,
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * widthScale),
          _StatCard(
            label: 'Current Conversion Rate',
            value: _conversionRate != null
                ? '₹${_conversionRate!.toStringAsFixed(2)}'
                : '---',
            icon: Icons.show_chart,
            iconColor: _blue,
            widthScale: widthScale,
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Users',
                  value: _users.length.toString(),
                  icon: Icons.people_outline,
                  iconColor: _blue,
                  widthScale: widthScale,
                ),
              ),
              SizedBox(width: 12 * widthScale),
              Expanded(
                child: _StatCard(
                  label: 'Pending',
                  value: pending.toString(),
                  icon: Icons.access_time,
                  iconColor: _blue,
                  widthScale: widthScale,
                ),
              ),
              SizedBox(width: 12 * widthScale),
              Expanded(
                child: _StatCard(
                  label: 'USD Rate',
                  value: _conversionRate != null
                      ? '₹${_conversionRate!.toStringAsFixed(2)}'
                      : '---',
                  icon: Icons.show_chart,
                  iconColor: _blue,
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
              child: _DropFilter(
                label: 'Status',
                value: _txStatus,
                options: const {
                  '': 'All',
                  'PENDING': 'Pending',
                  'COMPLETED': 'Done',
                  'REJECTED': 'Rejected',
                },
                onChanged: (v) {
                  setState(() => _txStatus = v);
                  _fetchAll();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DropFilter(
                label: 'Type',
                value: _txType,
                options: const {
                  '': 'All Types',
                  'DEPOSIT': 'Deposit',
                  'EXCHANGE': 'Exchange',
                },
                onChanged: (v) {
                  setState(() => _txType = v);
                  _fetchAll();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Transactions list
        SizedBox(height: 12 * widthScale),
        Row(
          children: [
            Icon(Icons.show_chart, color: _primary, size: 20 * widthScale),
            SizedBox(width: 10 * widthScale),
            Text(
              'Global Transactions',
              style: GoogleFonts.outfit(
                fontSize: 20 * widthScale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 12 * widthScale),

        if (_transactions.isEmpty)
          _emptyState('No transactions', Icons.show_chart)
        else
          ..._transactions.map((tx) => _buildTxCard(tx, widthScale)),
      ],
    );
  }

  Widget _buildTxCard(Map<String, dynamic> tx, double widthScale) {
    final isDeposit = tx['type'] == 'DEPOSIT';
    final status = tx['status'] as String;
    final isPending = status == 'PENDING';

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
        margin: EdgeInsets.only(bottom: 10 * widthScale),
        padding: EdgeInsets.all(16 * widthScale),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
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
                        ? _primary.withOpacity(0.10)
                        : _blue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 18 * widthScale,
                    color: isDeposit ? _primary : _blue,
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
                        'TX-${tx['id']?.toString().substring(0, 8).toUpperCase() ?? 'UNKNOWN'} • ${DateFormat('MMM dd, hh:mm a').format(DateTime.tryParse(tx['createdAt']?.toString() ?? '') ?? DateTime.now())}',
                        style: TextStyle(
                          color: _textDim,
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
                            ? _primary
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
                        color: statusColor.withOpacity(0.08),
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
              Container(height: 1, color: _border),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      label: 'Approve',
                      icon: Icons.check_circle_outline,
                      color: _primary,
                      filled: true,
                      onPressed: () => _updateTxStatus(tx['id'], 'COMPLETED'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionBtn(
                      label: 'Reject',
                      icon: Icons.cancel_outlined,
                      color: _danger,
                      onPressed: () => _updateTxStatus(tx['id'], 'REJECTED'),
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

  void _showTransactionDetail(Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TransactionDetailSheet(
        tx: tx,
        onStatusUpdate: (s) => _updateTxStatus(tx['id'], s),
        allUsers: _users,
      ),
    );
  }

  // ─── USERS TAB ────────────────────────────────────────────────────────────────
  Widget _buildUsers(double widthScale) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // Header + Add button
        Row(
          children: [
            Expanded(
              child: Text(
                'User Directory',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: _showAddUserSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.black, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      'Whitelist',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search
        TextField(
          onChanged: (v) {
            setState(() => _userSearch = v);
            _fetchAll();
          },
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search users by name or email...',
            hintStyle: TextStyle(color: _textDim, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: _textDim, size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primary),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 16),

        if (_users.isEmpty)
          _emptyState('No users found', Icons.people_outline)
        else
          ..._users.map((u) => _buildUserCard(u, widthScale)),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> u, double widthScale) {
    final isAdmin = u['role'] == 'ADMIN';
    final initial =
        (u['firstName']?.toString() ?? u['email']?.toString() ?? '?')
            .substring(0, 1)
            .toUpperCase();
    final joined = DateTime.tryParse(u['createdAt']?.toString() ?? '');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserDetailScreen(userId: u['id'], allUsers: _users),
        ),
      ).then((_) => _fetchAll()),
      child: Container(
        margin: EdgeInsets.only(bottom: 10 * widthScale),
        padding: EdgeInsets.all(16 * widthScale),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 44 * widthScale,
              height: 44 * widthScale,
              decoration: BoxDecoration(
                color: (isAdmin ? _primary : _blue).withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: isAdmin ? _primary : _blue,
                    fontSize: 18 * widthScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14 * widthScale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (u['firstName'] != null || u['lastName'] != null)
                        ? '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'
                              .trim()
                        : u['email'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14 * widthScale,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4 * widthScale),
                  Wrap(
                    spacing: 8 * widthScale,
                    runSpacing: 4 * widthScale,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7 * widthScale,
                          vertical: 2 * widthScale,
                        ),
                        decoration: BoxDecoration(
                          color: (isAdmin
                                  ? _primary
                                  : Theme.of(context).colorScheme.onSurface)
                              .withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          u['role'],
                          style: TextStyle(
                            color: isAdmin
                                ? _primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 9 * widthScale,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (u['status'] != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7 * widthScale,
                            vertical: 2 * widthScale,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (u['status'] == 'APPROVED'
                                        ? _primary
                                        : u['status'] == 'PENDING_APPROVAL'
                                        ? _blue
                                        : _danger)
                                    .withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (u['status'] as String).replaceAll('_', ' '),
                            style: TextStyle(
                              color: u['status'] == 'APPROVED'
                                  ? _primary
                                  : u['status'] == 'PENDING_APPROVAL'
                                  ? _blue
                                  : _danger,
                              fontSize: 9 * widthScale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      if (joined != null)
                        Text(
                          DateFormat('MMM dd, yyyy').format(joined),
                          style: TextStyle(
                            color: _textDim,
                            fontSize: 10 * widthScale,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12 * widthScale),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    NumberFormat('#,##0.00').format(u['balance'] ?? 0),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15 * widthScale,
                    ),
                  ),
                ),
                Text(
                  'USDT',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 10 * widthScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserSheet() {
    final emailCtrl = TextEditingController();
    String role = 'USER';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: StatefulBuilder(
          builder: (ctx, setLocal) => Column(
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
              Text(
                'Register User',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add a new email to the access whitelist.',
                style: TextStyle(color: _textDim, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'user@example.com',
                  hintStyle: TextStyle(color: _textDim),
                  prefixIcon: Icon(
                    Icons.mail_outline,
                    color: _textDim,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.03),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.10),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Role selector
              Row(
                children: [
                  _RoleChip(
                    label: 'User',
                    selected: role == 'USER',
                    onTap: () => setLocal(() => role = 'USER'),
                  ),
                  const SizedBox(width: 12),
                  _RoleChip(
                    label: 'Admin',
                    selected: role == 'ADMIN',
                    onTap: () => setLocal(() => role = 'ADMIN'),
                    color: _primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.15)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await _api.postRequest('/users', {
                            'email': emailCtrl.text,
                            'role': role,
                          });
                          Navigator.pop(ctx);
                          _fetchAll();
                          _showSnack(
                            'User whitelisted successfully',
                            success: true,
                          );
                        } catch (e) {
                          _showSnack('Failed to add user');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Whitelist',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SETTINGS TAB ─────────────────────────────────────────────────────────────

  Widget _emptyState(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(color: _textDim, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final double widthScale;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.widthScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final _bgCard = Theme.of(context).cardColor;
    final _border = Theme.of(context).dividerColor;
    final _textDim = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.all(16 * widthScale),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36 * widthScale,
            height: 36 * widthScale,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
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
              color: _textDim,
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

class _DropFilter extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  const _DropFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final _bgCard = Theme.of(context).cardColor;
    final _primary = Theme.of(context).primaryColor;
    final _textDim = Theme.of(context).colorScheme.onSurfaceVariant;
    final _border = Theme.of(context).dividerColor;

    return GestureDetector(
      onTap: () async {
        final chosen = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: _bgCard,
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
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
                            ? _primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: value == e.key
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: value == e.key
                        ? Icon(Icons.check, color: _primary, size: 18)
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
          color: _bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value.isNotEmpty ? _primary.withOpacity(0.4) : _border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              options[value] ?? label,
              style: TextStyle(
                color: value.isNotEmpty ? _primary : _textDim,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: value.isNotEmpty ? _primary : _textDim,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = const Color(0x00000001),
  });

  @override
  Widget build(BuildContext context) {
    final _textDim = Theme.of(context).colorScheme.onSurfaceVariant;
    final _border = Theme.of(context).dividerColor;
    final color = this.color == const Color(0x00000001) ? _textDim : this.color;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.15)
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color.withOpacity(0.40) : _border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? color : _textDim,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
