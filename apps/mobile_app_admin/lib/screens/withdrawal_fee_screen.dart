import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class WithdrawalFeeScreen extends StatefulWidget {
  const WithdrawalFeeScreen({super.key});

  @override
  State<WithdrawalFeeScreen> createState() => _WithdrawalFeeScreenState();
}

class _WithdrawalFeeScreenState extends State<WithdrawalFeeScreen> {
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard => Theme.of(context).cardColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).dividerColor;
  static const Color _danger = Color(0xFFF87171);

  final _api = ApiService();
  final _feeCtrl = TextEditingController();
  double? _currentFee;
  List<dynamic> _history = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final feeRes = await _api.getRequest('/settings/withdrawal-fee');
      final historyRes = await _api.getRequest(
        '/settings/withdrawal-fee/history',
      );

      if (mounted) {
        setState(() {
          _currentFee = (jsonDecode(feeRes.body)['withdrawalFee'] as num?)
              ?.toDouble();
          _history = jsonDecode(historyRes.body);
          if (_currentFee != null) {
            _feeCtrl.text = _currentFee!.toStringAsFixed(2);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFee() async {
    final fee = double.tryParse(_feeCtrl.text);
    if (fee == null) return;

    setState(() => _isSaving = true);
    try {
      final res = await _api.patchRequest('/settings/withdrawal-fee', {
        'fee': fee,
      });
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Withdrawal fee updated'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update fee'),
          backgroundColor: _danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Withdrawal Fee',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEditCard(),
                  const SizedBox(height: 32),
                  Text(
                    'FEE HISTORY',
                    style: GoogleFonts.inter(
                      color: _textDim,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._history.map((h) => _buildHistoryItem(h)),
                ],
              ),
            ),
    );
  }

  Widget _buildEditCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Withdrawal Fee',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This amount (USDT) will be deducted from every withdrawal request.',
            style: TextStyle(color: _textDim, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _feeCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              suffixText: 'USDT',
              suffixStyle: TextStyle(
                color: _primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _border),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveFee,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.history, color: _primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(item['fee'] as num).toDouble().toStringAsFixed(2)} USDT',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Updated by ${item['adminEmail']}',
                  style: TextStyle(color: _textDim, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            DateFormat(
              'MMM dd, yyyy',
            ).format(DateTime.parse(item['createdAt'])),
            style: TextStyle(color: _textDim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
