import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({super.key});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard => Theme.of(context).cardColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).dividerColor;
  static const Color _blue = Color(0xFF3B82F6);
  static const Color _danger = Color(0xFFF87171);

  final _amountCtrl = TextEditingController();
  final _inrCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  final _api = ApiService();
  double _balance = 0.0;
  double? _conversionRate;
  List<dynamic> _savedAccounts = [];
  List<dynamic> _filteredAccounts = [];
  String? _selectedAccountId;
  bool _showManualForm = false;
  bool _saveNewAccount = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userRes = await _api.getRequest('/users/me');
      final settingsRes = await _api.getRequest('/settings/conversion-rate');
      final accountsRes = await _api.getRequest('/bank-accounts');

      if (mounted) {
        setState(() {
          _balance = (jsonDecode(userRes.body)['balance'] as num).toDouble();
          _conversionRate =
              (jsonDecode(settingsRes.body)['usdtToInrRate'] as num?)
                  ?.toDouble();
          _savedAccounts = jsonDecode(accountsRes.body);
          _filteredAccounts = List.from(_savedAccounts);
          if (_savedAccounts.isNotEmpty) {
            _selectedAccountId = _savedAccounts[0]['id'];
          } else {
            _showManualForm = true;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onUsdtChanged(String val) {
    if (_conversionRate == null || val.isEmpty) {
      _inrCtrl.text = "";
      return;
    }
    final usdt = double.tryParse(val) ?? 0;
    _inrCtrl.text = (usdt * _conversionRate!).toStringAsFixed(2);
    setState(() {});
  }

  void _onInrChanged(String val) {
    if (_conversionRate == null || val.isEmpty) {
      _amountCtrl.text = "";
      setState(() {});
      return;
    }
    final inr = double.tryParse(val) ?? 0;
    _amountCtrl.text = (inr / _conversionRate!).toStringAsFixed(2);
    setState(() {});
  }

  void _onSearch(String query) {
    setState(() {
      _filteredAccounts = _savedAccounts
          .where(
            (acc) =>
                acc['name'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                acc['bankName'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                acc['accountNo'].toString().contains(query),
          )
          .toList();
    });
  }

  Future<void> _proceedToPasscode() async {
    if (_amountCtrl.text.isEmpty) return;
    final amount = double.tryParse(_amountCtrl.text) ?? 0;

    if (amount < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum transaction amount is 15 USDT'),
          backgroundColor: _danger,
        ),
      );
      return;
    }

    if (amount > _balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance'),
          backgroundColor: _danger,
        ),
      );
      return;
    }

    Map<String, dynamic> bankDetails;
    if (!_showManualForm && _selectedAccountId != null) {
      final acc = _savedAccounts.firstWhere(
        (a) => a['id'] == _selectedAccountId,
      );
      bankDetails = {
        'name': acc['name'],
        'account': acc['accountNo'],
        'bank': acc['bankName'],
        'ifsc': acc['ifsc'],
      };
    } else {
      if (_nameCtrl.text.isEmpty ||
          _accountCtrl.text.isEmpty ||
          _bankCtrl.text.isEmpty ||
          _ifscCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all bank details'),
            backgroundColor: _danger,
          ),
        );
        return;
      }
      bankDetails = {
        'name': _nameCtrl.text,
        'account': _accountCtrl.text,
        'bank': _bankCtrl.text,
        'ifsc': _ifscCtrl.text,
      };
    }

    // Navigate to Passcode Screen
    final result = await Navigator.pushNamed(
      context,
      '/exchange-passcode',
      arguments: {
        'amount': amount,
        'bankDetails': bankDetails,
        'saveNewAccount': _showManualForm && _saveNewAccount,
      },
    );

    if (result == true && mounted) {
      Navigator.pop(context, true); // Go back home
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final widthScale = (size.width / 375.0).clamp(0.85, 1.2);
    final isSmall = size.width < 360;
    final isShort = size.height < 700;

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Exchange USDT',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 18 : 20,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: EdgeInsets.all(isSmall ? 20 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(context),
                  SizedBox(height: isShort ? 24 : 32),
                  _buildExchangeForm(context),
                  SizedBox(height: isShort ? 24 : 32),
                  if (_amountCtrl.text.isNotEmpty &&
                      (double.tryParse(_amountCtrl.text) ?? 0) > _balance)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _danger.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _danger.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.warning_amber,
                              color: _danger,
                              size: isSmall ? 16 : 18,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Balance Too Low',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmall ? 12 : 13,
                                  ),
                                ),
                                Text(
                                  'You cannot exchange more than your balance.',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                    fontSize: isSmall ? 10 : 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  _buildBankSelection(context),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: (isSmall ? 52 : 56) * widthScale,
                    child: ElevatedButton(
                      onPressed:
                          (_amountCtrl.text.isEmpty ||
                              (double.tryParse(_amountCtrl.text) ?? 0) < 15 ||
                              (double.tryParse(_amountCtrl.text) ?? 0) >
                                  _balance)
                          ? null
                          : _proceedToPasscode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        disabledBackgroundColor: Colors.white.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Authorize Transaction',
                        style: TextStyle(
                          color:
                              (_amountCtrl.text.isEmpty ||
                                  (double.tryParse(_amountCtrl.text) ?? 0) <
                                      15 ||
                                  (double.tryParse(_amountCtrl.text) ?? 0) >
                                      _balance)
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.24)
                              : Theme.of(context).colorScheme.surface,
                          fontWeight: FontWeight.bold,
                          fontSize: (isSmall ? 14 : 16) * widthScale,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: TextStyle(
                      color: _textDim,
                      fontSize: isSmall ? 10 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${_balance.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      fontSize: (isSmall ? 22 : 28) * widthScale,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(isSmall ? 10 : 12),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: _primary,
                  size: isSmall ? 20 : 24,
                ),
              ),
            ],
          ),
          if (_conversionRate != null) ...[
            SizedBox(height: isSmall ? 16 : 20),
            Divider(color: _border, height: 1),
            SizedBox(height: isSmall ? 16 : 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATED VALUE',
                      style: TextStyle(
                        color: _textDim,
                        fontSize: isSmall ? 9 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${(_balance * _conversionRate!).toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        color: _primary,
                        fontSize: isSmall ? 15 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'CONVERSION RATE',
                      style: TextStyle(
                        color: _textDim,
                        fontSize: isSmall ? 9 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1 USDT = ₹${_conversionRate!.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: (isSmall ? 10 : 12) * widthScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExchangeForm(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final widthScale = (size.width / 375.0).clamp(0.85, 1.2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXCHANGE DETAILS',
          style: TextStyle(color: _textDim, fontSize: 10, letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _inrCtrl,
          label: 'You Pay (INR)',
          suffix: 'INR',
          onChanged: _onInrChanged,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _amountCtrl,
          label: 'You Receive (USDT)',
          suffix: 'USDT',
          onChanged: _onUsdtChanged,
          readOnly: true,
        ),
        if (_conversionRate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Minimum exchange amount is 15 USDT',
              style: TextStyle(
                color:
                    (double.tryParse(_amountCtrl.text) ?? 0) < 15 &&
                        _amountCtrl.text.isNotEmpty
                    ? _danger
                    : _primary,
                fontSize: 12 * widthScale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required Function(String) onChanged,
    bool readOnly = false,
  }) {
    final widthScale = (MediaQuery.of(context).size.width / 375.0).clamp(
      0.85,
      1.2,
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * widthScale,
        vertical: 12 * widthScale,
      ),
      decoration: BoxDecoration(
        color: readOnly ? _bgCard.withValues(alpha: 0.5) : _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: _textDim, fontSize: 11 * widthScale),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  readOnly: readOnly,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.outfit(
                    color: readOnly
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7)
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 24 * widthScale,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * widthScale,
                  vertical: 6 * widthScale,
                ),
                decoration: BoxDecoration(
                  color: _bgDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  suffix,
                  style: GoogleFonts.inter(
                    color: _primary,
                    fontSize: 12 * widthScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SETTLEMENT DESTINATION',
              style: TextStyle(
                color: _textDim,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            TextButton(
              onPressed: () =>
                  setState(() => _showManualForm = !_showManualForm),
              child: Text(
                _showManualForm ? 'Use Saved' : '+ Add New Account',
                style: TextStyle(
                  color: _blue,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (!_showManualForm && _savedAccounts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search saved accounts...',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.24),
                ),
                icon: Icon(Icons.search, color: _textDim, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (!_showManualForm && _savedAccounts.isNotEmpty)
          ..._filteredAccounts.map((acc) {
            bool isSelected = _selectedAccountId == acc['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedAccountId = acc['id']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? _primary.withOpacity(0.05) : _bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? _primary.withValues(alpha: 0.3)
                        : _border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected ? _primary : _textDim,
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acc['name'],
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${acc['bankName']} • ${acc['accountNo']}',
                            style: TextStyle(color: _textDim, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          })
        else
          Column(
            children: [
              _buildManualField(_nameCtrl, 'Beneficiary Name'),
              const SizedBox(height: 12),
              _buildManualField(_bankCtrl, 'Bank Name'),
              const SizedBox(height: 12),
              _buildManualField(_accountCtrl, 'Account Number'),
              const SizedBox(height: 12),
              _buildManualField(_ifscCtrl, 'IFSC Code'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _saveNewAccount,
                    onChanged: (v) =>
                        setState(() => _saveNewAccount = v ?? true),
                    activeColor: _primary,
                  ),
                  Text(
                    'Save for future use',
                    style: TextStyle(color: _textDim, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildManualField(TextEditingController ctrl, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: ctrl,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24),
          ),
        ),
      ),
    );
  }
}
