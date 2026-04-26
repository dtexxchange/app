import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard => Theme.of(context).cardColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).dividerColor;
  static const Color _blue = Color(0xFF3B82F6);
  static const Color _danger = Color(0xFFF87171);

  final _amountCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  final _api = ApiService();
  double _balance = 0.0;
  double _withdrawalFee = 0.0;
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
      final feeRes = await _api.getRequest('/settings/withdrawal-fee');
      final rateRes = await _api.getRequest('/settings/conversion-rate');
      final accountsRes = await _api.getRequest('/bank-accounts');

      if (mounted) {
        setState(() {
          _balance = (jsonDecode(userRes.body)['balance'] as num).toDouble();
          _withdrawalFee = (jsonDecode(feeRes.body)['withdrawalFee'] as num?)?.toDouble() ?? 0.0;
          _conversionRate = (jsonDecode(rateRes.body)['usdtToInrRate'] as num?)?.toDouble();
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

  void _onAmountChanged(String val) {
    setState(() {});
  }

  void _onSearch(String query) {
    setState(() {
      _filteredAccounts = _savedAccounts
          .where(
            (acc) =>
                acc['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
                acc['bankName'].toString().toLowerCase().contains(query.toLowerCase()) ||
                acc['accountNo'].toString().contains(query),
          )
          .toList();
    });
  }

  Future<void> _proceedToPasscode() async {
    if (_amountCtrl.text.isEmpty) return;
    final amount = double.tryParse(_amountCtrl.text) ?? 0;

    if (amount <= _withdrawalFee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Amount must be greater than the fee (\$$_withdrawalFee)'),
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
      final acc = _savedAccounts.firstWhere((a) => a['id'] == _selectedAccountId);
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

    // Pass 'withdrawal' type so passcode screen knows which endpoint to call
    final result = await Navigator.pushNamed(
      context,
      '/exchange-passcode', // Reusing exchange-passcode which handles both exchange and withdrawal
      arguments: {
        'type': 'withdrawal',
        'amount': amount,
        'bankDetails': bankDetails,
        'saveNewAccount': _showManualForm && _saveNewAccount,
      },
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final widthScale = (size.width / 375.0).clamp(0.85, 1.2);
    final isSmall = size.width < 360;

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Withdraw Funds',
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
                  _buildBalanceCard(),
                  const SizedBox(height: 32),
                  _buildWithdrawalForm(),
                  const SizedBox(height: 32),
                  _buildBankSelection(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56 * widthScale,
                    child: ElevatedButton(
                      onPressed: _amountCtrl.text.isEmpty || 
                                (double.tryParse(_amountCtrl.text) ?? 0) > _balance ||
                                (double.tryParse(_amountCtrl.text) ?? 0) <= _withdrawalFee
                          ? null
                          : _proceedToPasscode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Request Withdrawal',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16 * widthScale,
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

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Balance',
                style: TextStyle(color: _textDim, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_balance.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.account_balance_wallet, color: _primary, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalForm() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    final netAmount = (amount - _withdrawalFee).clamp(0.0, double.infinity);
    final inrValue = _conversionRate != null ? netAmount * _conversionRate! : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WITHDRAWAL DETAILS',
          style: TextStyle(color: _textDim, fontSize: 10, letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _amountCtrl,
          label: 'Total Amount to Withdraw',
          suffix: 'USDT',
          onChanged: _onAmountChanged,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Withdrawal Fee', '-\$${_withdrawalFee.toStringAsFixed(2)}', isNegative: true),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              _buildSummaryRow('You Will Receive', '\$${netAmount.toStringAsFixed(2)}', isBold: true),
              if (_conversionRate != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '≈ ₹${inrValue.toStringAsFixed(2)}',
                      style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isNegative = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: _textDim, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: isNegative ? _danger : Theme.of(context).colorScheme.onSurface,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: _textDim, fontSize: 11)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _bgDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  suffix,
                  style: GoogleFonts.inter(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SETTLEMENT DESTINATION',
              style: TextStyle(color: _textDim, fontSize: 10, letterSpacing: 1.5),
            ),
            TextButton(
              onPressed: () => setState(() => _showManualForm = !_showManualForm),
              child: Text(
                _showManualForm ? 'Use Saved' : '+ Add New Account',
                style: TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.bold),
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
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search saved accounts...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                icon: Icon(Icons.search, color: _textDim, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._filteredAccounts.map((acc) {
            bool isSelected = _selectedAccountId == acc['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedAccountId = acc['id']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? _primary.withValues(alpha: 0.05) : _bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? _primary.withValues(alpha: 0.3) : _border),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
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
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                          ),
                          Text('${acc['bankName']} • ${acc['accountNo']}', style: TextStyle(color: _textDim, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ] else
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
                    onChanged: (v) => setState(() => _saveNewAccount = v ?? true),
                    activeColor: _primary,
                  ),
                  Text('Save for future use', style: TextStyle(color: _textDim, fontSize: 12)),
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
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
        ),
      ),
    );
  }
}
