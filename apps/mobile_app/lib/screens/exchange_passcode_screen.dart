import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';

class ExchangePasscodeScreen extends StatefulWidget {
  const ExchangePasscodeScreen({super.key});

  @override
  State<ExchangePasscodeScreen> createState() => _ExchangePasscodeScreenState();
}

class _ExchangePasscodeScreenState extends State<ExchangePasscodeScreen> {
  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  static const Color _danger = Color(0xFFF87171);

  final List<String> _passcode = [];
  bool _isLoading = false;
  final _api = ApiService();

  void _onNumberTap(String number) {
    if (_passcode.length < 6) {
      setState(() => _passcode.add(number));
      if (_passcode.length == 6) {
        _submitTransaction();
      }
    }
  }

  void _onBackspace() {
    if (_passcode.isNotEmpty) {
      setState(() => _passcode.removeLast());
    }
  }

  Future<void> _submitTransaction() async {
    setState(() => _isLoading = true);
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final amount = args['amount'] as double;
    final bankDetails = args['bankDetails'] as Map<String, dynamic>;
    final save = args['saveNewAccount'] as bool;
    final passcodeStr = _passcode.join();

    try {
      // 1. Get Public Key if needed
      String pubKey = "";
      if (CryptoService.enableE2EE) {
          final keyRes = await _api.getRequest('/wallet/admin/public-key');
          pubKey = jsonDecode(keyRes.body)['publicKey'];
      }

      // 2. Encrypt
      final encrypted = CryptoService.encrypt(pubKey, bankDetails);

      // 3. Save Bank Account if requested
      if (save) {
          await _api.postRequest('/bank-accounts', {
            'name': bankDetails['name'],
            'bankName': bankDetails['bank'],
            'accountNo': bankDetails['account'],
            'ifsc': bankDetails['ifsc'],
          });
      }

      // 4. Submit Exchange
      final res = await _api.postRequest('/wallet/exchange', {
        'amount': amount,
        'bankDetails': encrypted,
        'passcode': passcodeStr,
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/success', arguments: {
              'amount': amount,
              'type': 'EXCHANGE',
          });
        }
      } else {
        final msg = jsonDecode(res.body)['message'] ?? 'Transaction Failed';
        _showError(msg);
      }
    } catch (e) {
      _showError('Network error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: _danger),
    );
    setState(() => _passcode.clear());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isShort = size.height < 700;
    
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top - kToolbarHeight - MediaQuery.of(context).padding.bottom),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(height: isShort ? 20 : 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.shield_outlined, color: _primary, size: isShort ? 32 : 40),
                ),
                const SizedBox(height: 24),
                Text(
                  'Authorization', 
                  style: GoogleFonts.outfit(
                    fontSize: isShort ? 20 : 24, 
                    fontWeight: FontWeight.bold, 
                    color: Theme.of(context).colorScheme.onSurface
                  )
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your 6-digit security passcode\nto authorize this exchange.', 
                  textAlign: TextAlign.center, 
                  style: TextStyle(color: _textDim, fontSize: isShort ? 12 : 13)
                ),
                SizedBox(height: isShort ? 32 : 48),
                _buildDots(),
                SizedBox(height: isShort ? 40 : 60),
                if (_isLoading)
                   Padding(
                     padding: const EdgeInsets.symmetric(vertical: 40),
                     child: CircularProgressIndicator(color: _primary),
                   )
                else
                   _buildKeyboard(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        bool isFilled = index < _passcode.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? _primary : Colors.transparent,
            border: Border.all(color: isFilled ? _primary : _textDim.withOpacity(0.3), width: 2),
          ),
        );
      }),
    );
  }

  Widget _buildKeyboard(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 380;
    final keySize = isSmall ? 64.0 : 72.0;
    final spacing = isSmall ? 16.0 : 24.0;

    return Container(
      child: Column(
        children: [
          _keyRow(['1', '2', '3'], keySize),
          SizedBox(height: spacing),
          _keyRow(['4', '5', '6'], keySize),
          SizedBox(height: spacing),
          _keyRow(['7', '8', '9'], keySize),
          SizedBox(height: spacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: keySize + 30), // Placeholder
              _key('0', keySize),
              SizedBox(
                width: keySize + 30,
                child: Center(
                  child: IconButton(
                    onPressed: _onBackspace, 
                    icon: Icon(Icons.backspace_outlined, color: Theme.of(context).colorScheme.onSurface)
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keyRow(List<String> keys, double keySize) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: keys.map((k) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: _key(k, keySize),
    )).toList()
  );

  Widget _key(String val, double size) => GestureDetector(
    onTap: () => _onNumberTap(val),
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), shape: BoxShape.circle),
      child: Center(
        child: Text(
          val, 
          style: GoogleFonts.outfit(
            fontSize: size * 0.35, 
            fontWeight: FontWeight.bold, 
            color: Theme.of(context).colorScheme.onSurface
          )
        )
      ),
    ),
  );
}
