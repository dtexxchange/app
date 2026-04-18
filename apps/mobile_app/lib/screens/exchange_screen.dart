import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

const _bgDark = Color(0xFF0A0B0D);
const _bgCard = Color(0xFF15171C);
const _primary = Color(0xFF00FF9D);
const _textDim = Color(0xFF94A3B8);
const _border = Color(0x0DFFFFFF);
const _blue = Color(0xFF3B82F6);
const _danger = Color(0xFFF87171);

class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({super.key});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  final _amountCtrl = TextEditingController();
  final _inrCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  final _api = ApiService();
  double _balance = 0.0;
  double? _conversionRate;
  List<dynamic> _savedAccounts = [];
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
      return;
    }
    final inr = double.tryParse(val) ?? 0;
    _amountCtrl.text = (inr / _conversionRate!).toStringAsFixed(6);
    setState(() {});
  }

  Future<void> _proceedToPasscode() async {
    if (_amountCtrl.text.isEmpty) return;
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
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
          ? const Center(child: CircularProgressIndicator(color: _primary))
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
                        border: Border.all(color: _danger.withOpacity(0.2)),
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
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmall ? 12 : 13,
                                  ),
                                ),
                                Text(
                                  'You cannot exchange more than your balance.',
                                  style: TextStyle(
                                    color: Colors.white70,
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
                    height: isSmall ? 52 : 56,
                    child: ElevatedButton(
                      onPressed:
                          (_amountCtrl.text.isEmpty ||
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
                                  (double.tryParse(_amountCtrl.text) ?? 0) >
                                      _balance)
                              ? Colors.white24
                              : _bgDark,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmall ? 14 : 16,
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
    final isSmall = MediaQuery.of(context).size.width < 360;
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
                      fontSize: isSmall ? 22 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(isSmall ? 10 : 12),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
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
                        color: Colors.white70,
                        fontSize: isSmall ? 10 : 12,
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
    final isSmall = MediaQuery.of(context).size.width < 360;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EXCHANGE DETAILS',
          style: TextStyle(color: _textDim, fontSize: 10, letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _amountCtrl,
          label: 'You Pay',
          suffix: 'USDT',
          onChanged: _onUsdtChanged,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _inrCtrl,
          label: 'You Receive',
          suffix: 'INR',
          onChanged: _onInrChanged,
        ),
        if (_conversionRate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Rate: 1 USDT = ₹${_conversionRate!.toStringAsFixed(2)}',
              style: const TextStyle(
                color: _primary,
                fontSize: 12,
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _textDim, fontSize: 11)),
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              suffixText: suffix,
              suffixStyle: const TextStyle(color: _textDim, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankSelection(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
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
                style: const TextStyle(
                  color: _blue,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (!_showManualForm && _savedAccounts.isNotEmpty)
          ..._savedAccounts.map((acc) {
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
                    color: isSelected ? _primary.withOpacity(0.3) : _border,
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${acc['bankName']} • ${acc['accountNo']}',
                            style: const TextStyle(
                              color: _textDim,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList()
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
                  const Text(
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
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
        ),
      ),
    );
  }
}
