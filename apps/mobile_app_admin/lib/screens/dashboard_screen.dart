import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart' show themeService;
import '../services/api_service.dart';
import '../widgets/add_user_sheet.dart';
import '../widgets/exchange_tab.dart';
import '../widgets/overview_tab.dart';
import '../widgets/settings_tab.dart';
import 'transaction_detail_screen.dart';
import '../widgets/transaction_filter_sheet.dart';
import '../widgets/transactions_tab.dart';
import '../widgets/user_filter_sheet.dart';
import '../widgets/users_tab.dart';
import 'assignments_screen.dart';
import 'user_detail_screen.dart';
import 'wallets_screen.dart';
import 'withdrawal_fee_screen.dart';
import 'news_screen.dart';

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
  Color get _onSurface => Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF0F172A);
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
  bool _isUserSearching = false;
  String _selectedUserRole = 'All';

  // Transaction search and filters
  String _transactionSearch = '';
  bool _isTransactionSearching = false;
  String _selectedTransactionType = 'All';
  String _selectedTransactionStatus = 'All';
  DateTime? _transactionStartDate;
  DateTime? _transactionEndDate;
  String _transactionSortBy = 'date';

  double? _conversionRate;
  List<dynamic> _rateHistory = [];
  final _rateController = TextEditingController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _rateController.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

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

  Future<void> _fetchAll({bool showLoader = true, int? limit}) async {
    if (showLoader) setState(() => _isLoading = true);
    try {
      final txParams = <String>[];
      if (_txStatus.isNotEmpty) txParams.add('status=$_txStatus');
      if (_txType.isNotEmpty) txParams.add('type=$_txType');

      // Default to 20 for Overview, 500 for Transactions
      final effectiveLimit = limit ?? (_tabIndex == 0 ? 20 : 500);
      txParams.add('limit=$effectiveLimit');

      final txQ = '?${txParams.join('&')}';

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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTxStatus(
    String id,
    String status, {
    bool confirmed = false,
    String? utr,
  }) async {
    if (!confirmed) {
      final result = await _showConfirmDialog(
        title: '${status == 'COMPLETED' ? 'Approve' : 'Reject'} Transaction',
        message: 'Are you sure you want to mark this transaction as $status?',
        requireUtr: status == 'COMPLETED',
      );
      if (result == null || result['confirmed'] != true) return;
      utr = result['utr'];
    }

    try {
      await _api.patchRequest('/wallet/transactions/$id/status', {
        'status': status,
        'utr': utr,
      });
      _fetchAll();
      _showSnack('Status updated to $status', success: true);
    } catch (e) {
      _showSnack('Failed to update status');
    }
  }

  Future<Map<String, dynamic>?> _showConfirmDialog({
    required String title,
    required String message,
    bool requireUtr = false,
  }) {
    final utrCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(color: _textDim, fontSize: 14),
              ),
              if (requireUtr) ...[
                const SizedBox(height: 20),
                Text(
                  'UTR NUMBER (MANDATORY)',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: utrCtrl,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter UTR / Ref No',
                    hintStyle: TextStyle(
                      color: _textDim.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: _bgDark.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'UTR is required to approve'
                      : null,
                ),
              ],
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: _textDim,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (requireUtr && !formKey.currentState!.validate()) {
                        return;
                      }
                      Navigator.pop(ctx, {
                        'confirmed': true,
                        'utr': utrCtrl.text.trim(),
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Proceed',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                : _buildTabContent(widthScale),
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
          onTap: (i) {
            setState(() => _tabIndex = i);
            if (i == 0 || i == 2) _fetchAll(); // Refresh when entering relevant tabs
          },
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
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Transactions',
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
    final isUserTab = _tabIndex == 1;
    final isTransactionTab = _tabIndex == 2;

    return Container(
      decoration: BoxDecoration(
        color: _bgDark.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24 * widthScale, 8, 24 * widthScale, 12),
          child: Row(
            children: [
              if ((_isUserSearching && isUserTab) ||
                  (_isTransactionSearching && isTransactionTab))
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() {
                    if (isUserTab) {
                      _isUserSearching = false;
                      _userSearch = '';
                    } else {
                      _isTransactionSearching = false;
                      _transactionSearch = '';
                    }
                    _searchCtrl.clear();
                    _fetchAll(showLoader: false);
                  }),
                )
              else
                _buildBranding(widthScale),

              if ((_isUserSearching && isUserTab) ||
                  (_isTransactionSearching && isTransactionTab)) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: (v) {
                      if (_debounce?.isActive ?? false) _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        setState(() {
                          if (isUserTab) {
                            _userSearch = v;
                          } else {
                            _transactionSearch = v;
                          }
                        });
                        _fetchAll(showLoader: false);
                      });
                    },
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: _onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: isUserTab
                          ? 'Search users...'
                          : 'Search transactions...',
                      hintStyle: TextStyle(
                        color: _textDim.withValues(alpha: 0.5),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ] else ...[
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/notifications'),
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: _bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Icon(Icons.notifications_outlined, color: _primary, size: 20),
                  ),
                ),
              ],

              if (isUserTab) ...[
                if (!_isUserSearching)
                  IconButton(
                    icon: Icon(Icons.search, color: _textDim, size: 22),
                    onPressed: () => setState(() => _isUserSearching = true),
                  ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.more_vert, color: _textDim, size: 22),
                      onPressed: _showUserFilterSheet,
                    ),
                    if (_userSearch.isNotEmpty || _selectedUserRole != 'All')
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: _bgDark, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ] else if (isTransactionTab) ...[
                if (!_isTransactionSearching)
                  IconButton(
                    icon: Icon(Icons.search, color: _textDim, size: 22),
                    onPressed: () =>
                        setState(() => _isTransactionSearching = true),
                  ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.filter_list, color: _textDim, size: 22),
                      onPressed: _showTransactionFilterSheet,
                    ),
                    if (_transactionSearch.isNotEmpty ||
                        _selectedTransactionType != 'All' ||
                        _selectedTransactionStatus != 'All')
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: _bgDark, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ] else
                GestureDetector(
                  onTap: () async {
                    await _api.logout();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
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

  Widget _buildBranding(double widthScale) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40 * widthScale,
          height: 40 * widthScale,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary, _primary.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.diamond_outlined,
            color: Colors.black,
            size: 20 * widthScale,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _onSurface,
                  letterSpacing: -0.5,
                ),
                children: [
                  const TextSpan(text: 'USDT'),
                  TextSpan(
                    text: '.EX',
                    style: TextStyle(color: _primary),
                  ),
                ],
              ),
            ),
            Text(
              'ADMINISTRATOR',
              style: GoogleFonts.inter(
                color: _textDim,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabContent(double widthScale) {
    switch (_tabIndex) {
      case 0:
        return OverviewTab(
          users: _users,
          transactions: _transactions,
          conversionRate: _conversionRate,
          txStatus: _txStatus,
          txType: _txType,
          onStatusChanged: (v) {
            setState(() => _txStatus = v);
            _fetchAll();
          },
          onTypeChanged: (v) {
            setState(() => _txType = v);
            _fetchAll();
          },
          onTransactionTap: _showTransactionDetail,
          onUpdateTxStatus: _updateTxStatus,
          onRefresh: _fetchAll,
          onViewAll: () {
            setState(() => _tabIndex = 2);
            _fetchAll();
          },
        );
      case 1:
        return UsersTab(
          users: _users,
          searchQuery: _userSearch,
          selectedRole: _selectedUserRole,
          onSearchChanged: (value) {
            setState(() => _userSearch = value);
            _fetchAll(showLoader: false);
          },
          onRoleChanged: (value) {
            setState(() => _selectedUserRole = value);
            _fetchAll(showLoader: false);
          },
          onShowFilterSheet: _showUserFilterSheet,
          onShowAddUserSheet: _showAddUserSheet,
          onUserTap: (user) => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  UserDetailScreen(userId: user['id'], allUsers: _users),
            ),
          ).then((_) => _fetchAll()),
        );
      case 2:
        return TransactionsTab(
          transactions: _transactions,
          searchQuery: _transactionSearch,
          selectedType: _selectedTransactionType,
          selectedStatus: _selectedTransactionStatus,
          startDate: _transactionStartDate,
          endDate: _transactionEndDate,
          sortBy: _transactionSortBy,
          onSearchChanged: (value) {
            setState(() => _transactionSearch = value);
            _fetchAll(showLoader: false);
          },
          onTypeChanged: (value) {
            setState(() => _selectedTransactionType = value);
            _fetchAll(showLoader: false);
          },
          onStatusChanged: (value) {
            setState(() => _selectedTransactionStatus = value);
            _fetchAll(showLoader: false);
          },
          onStartDateChanged: (value) {
            setState(() => _transactionStartDate = value);
            _fetchAll(showLoader: false);
          },
          onEndDateChanged: (value) {
            setState(() => _transactionEndDate = value);
            _fetchAll(showLoader: false);
          },
          onSortChanged: (value) {
            setState(() => _transactionSortBy = value);
            _fetchAll(showLoader: false);
          },
          onShowFilterSheet: _showTransactionFilterSheet,
          onTransactionAction: (transactionId, action) {
            switch (action) {
              case 'detail':
                final transaction = _transactions.firstWhere(
                  (tx) => tx['id'] == transactionId,
                );
                _showTransactionDetail(transaction);
                break;
              case 'approve':
                _updateTxStatus(transactionId, 'COMPLETED');
                break;
              case 'reject':
                _updateTxStatus(transactionId, 'REJECTED');
                break;
            }
          },
        );
      case 3:
        return ExchangeTab(
          conversionRate: _conversionRate,
          rateHistory: _rateHistory,
          rateController: _rateController,
          onSaveRate: _saveConversionRate,
        );
      case 4:
        return SettingsTab(
          conversionRate: _conversionRate,
          hasMobileKey: _hasMobileKey,
          onSaveRate: (rate) {},
          onImportKey: (type, key) {},
          onGenerateKeys: _generateKeysOnMobile,
          onToggleTheme: themeService.toggleTheme,
          onNavigateToWallets: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletsScreen()),
            );
          },
          onNavigateToAssignments: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AssignmentsScreen()),
            );
          },
          onNavigateToWithdrawalFee: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WithdrawalFeeScreen()),
            );
          },
          onNavigateToNews: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewsScreen()),
            );
          },
        );
      default:
        return const SizedBox();
    }
  }

  void _showAddUserSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddUserSheet(
        onAddUser: (email, role) async {
          await _api.postRequest('/users', {'email': email, 'role': role});
          _fetchAll();
          _showSnack('User whitelisted successfully', success: true);
        },
      ),
    );
  }

  void _showTransactionDetail(Map<String, dynamic> tx) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(
          tx: tx,
          onStatusUpdate: (s, {utr}) =>
              _updateTxStatus(tx['id'], s, confirmed: true, utr: utr),
          allUsers: _users,
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

  void _showUserFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => UserFilterSheet(
        selectedRole: _selectedUserRole,
        onRoleChanged: (value) {
          setState(() {
            _selectedUserRole = value;
          });
        },
        onReset: () {
          setState(() {
            _userSearch = '';
            _searchCtrl.clear();
            _selectedUserRole = 'All';
          });
          _fetchAll(showLoader: false);
        },
        onApply: () {
          Navigator.pop(ctx);
          _fetchAll(showLoader: false);
        },
      ),
    );
  }

  void _showTransactionFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => TransactionFilterSheet(
        selectedType: _selectedTransactionType,
        selectedStatus: _selectedTransactionStatus,
        startDate: _transactionStartDate,
        endDate: _transactionEndDate,
        sortBy: _transactionSortBy,
        onTypeChanged: (value) {
          setState(() {
            _selectedTransactionType = value;
          });
        },
        onStatusChanged: (value) {
          setState(() {
            _selectedTransactionStatus = value;
          });
        },
        onStartDateChanged: (value) {
          setState(() {
            _transactionStartDate = value;
          });
        },
        onEndDateChanged: (value) {
          setState(() {
            _transactionEndDate = value;
          });
        },
        onSortChanged: (value) {
          setState(() {
            _transactionSortBy = value;
          });
        },
        onReset: () {
          setState(() {
            _transactionSearch = '';
            _searchCtrl.clear();
            _selectedTransactionType = 'All';
            _selectedTransactionStatus = 'All';
            _transactionStartDate = null;
            _transactionEndDate = null;
            _transactionSortBy = 'date';
          });
          _fetchAll(showLoader: false);
        },
        onApply: () {
          Navigator.pop(ctx);
          _fetchAll(showLoader: false);
        },
      ),
    );
  }
}
