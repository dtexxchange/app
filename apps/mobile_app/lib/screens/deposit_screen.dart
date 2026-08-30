import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../widgets/live_timer.dart';
import '../widgets/expandable_amount.dart';

enum DepositState {
  enterAmount,
  qrCode,
  busy,
}

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard => Theme.of(context).cardColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).dividerColor;
  Color get _onSurface => Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF0F172A);

  final _api = ApiService();
  final _amountCtrl = TextEditingController();
  
  DepositState _state = DepositState.enterAmount;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  double? _conversionRate;
  Map<String, dynamic>? _activeWallet;
  Map<String, dynamic>? _activeTransaction;
  DateTime? _expiresAt;
  DateTime? _busyAvailableAt;
  String _qrSeed = "";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _generateQrSeed() {
    setState(() {
      _qrSeed = '?t=${DateTime.now().millisecondsSinceEpoch}';
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getRequest('/api/wallet/deposit/active'),
        _api.getRequest('/api/settings/conversion-rate'),
      ]);

      if (results[1].statusCode == 200) {
        final rateData = jsonDecode(results[1].body);
        _conversionRate = rateData['usdtToInrRate'] != null
            ? (rateData['usdtToInrRate'] as num).toDouble()
            : null;
      }

      if (results[0].statusCode == 200) {
        final depositData = jsonDecode(results[0].body);
        if (depositData != null && depositData.isNotEmpty) {
          if (depositData['isBusy'] == true) {
            _busyAvailableAt = depositData['availableAt'] != null
                ? DateTime.parse(depositData['availableAt'].toString())
                : DateTime.now().add(const Duration(minutes: 5));
            _state = DepositState.busy;
          } else {
            _activeWallet = Map<String, dynamic>.from(depositData['wallet']);
            _activeTransaction = Map<String, dynamic>.from(depositData['transaction']);
            _expiresAt = depositData['expiresAt'] != null
                ? DateTime.parse(depositData['expiresAt'].toString())
                : DateTime.now().add(const Duration(minutes: 30));
            _state = DepositState.qrCode;
            _generateQrSeed();
          }
        } else {
          _state = DepositState.enterAmount;
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitDeposit() async {
    final amountText = _amountCtrl.text.trim();
    if (amountText.isEmpty) {
      setState(() => _errorMessage = "Please enter an amount");
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = "Please enter a valid amount");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await _api.postRequest('/api/wallet/deposit', {'amount': amount});
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null) {
          if (data['isBusy'] == true) {
            setState(() {
              _busyAvailableAt = data['availableAt'] != null
                  ? DateTime.parse(data['availableAt'].toString())
                  : DateTime.now().add(const Duration(minutes: 5));
              _state = DepositState.busy;
            });
          } else {
            setState(() {
              _activeWallet = Map<String, dynamic>.from(data['wallet']);
              _activeTransaction = Map<String, dynamic>.from(data['transaction']);
              _expiresAt = data['expiresAt'] != null
                  ? DateTime.parse(data['expiresAt'].toString())
                  : DateTime.now().add(const Duration(minutes: 30));
              _state = DepositState.qrCode;
              _generateQrSeed();
            });
          }
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _errorMessage = data['message'] ?? 'Failed to request deposit';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        title: Text(
          'Add Money',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Rate Card (only on enterAmount page)
                  if (_state == DepositState.enterAmount) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _primary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.show_chart,
                              color: _primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CURRENT EXCHANGE RATE',
                                  style: GoogleFonts.inter(
                                    color: _primary.withValues(alpha: 0.6),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _conversionRate != null
                                    ? ExpandableAmount(
                                        amount: _conversionRate!,
                                        prefix: '1 USDT = ₹',
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : Text(
                                        'Fetching rate...',
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Body views based on state
                  if (_state == DepositState.enterAmount)
                    _buildAmountInputForm()
                  else if (_state == DepositState.busy)
                    _buildBusyState()
                  else if (_state == DepositState.qrCode && _activeWallet != null)
                    _buildWalletCard(_activeWallet!)
                  else
                    _buildEmptyState(),

                  const SizedBox(height: 40),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How to Add Money?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStep(
                          '1',
                          'Enter the amount of USDT you want to deposit.',
                        ),
                        _buildStep(
                          '2',
                          'Scan the QR code or copy the wallet address displayed.',
                        ),
                        _buildStep(
                          '3',
                          'Transfer the exact USDT (TRC20) amount from your wallet.',
                        ),
                        _buildStep(
                          '4',
                          'Our administrators will verify and credit your balance shortly.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAmountInputForm() {
    final hasRate = _conversionRate != null;
    final usdtAmount = double.tryParse(_amountCtrl.text) ?? 0.0;
    final inrValue = hasRate ? usdtAmount * _conversionRate! : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AMOUNT TO DEPOSIT',
                style: GoogleFonts.inter(
                  color: _textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      onChanged: (val) {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: GoogleFonts.outfit(
                        color: _onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _bgDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Text(
                      'USDT',
                      style: GoogleFonts.inter(
                        color: _primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Select Amount Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [50, 100, 250, 500, 1000].map((amt) {
              final isSelected = _amountCtrl.text == amt.toString();
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text('$amt USDT'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _amountCtrl.text = amt.toString();
                        _errorMessage = null;
                      });
                    }
                  },
                  backgroundColor: _bgCard,
                  selectedColor: _primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: isSelected ? _primary : _onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? _primary : _border,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // Estimated Value Display
        if (hasRate && usdtAmount > 0) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payable Amount',
                  style: TextStyle(
                    color: _textDim,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ExpandableAmount(
                  amount: inrValue,
                  prefix: '₹',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Proceed Button
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitDeposit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  )
                : Text(
                    'Add Money',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: TextStyle(
                  color: _primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: _textDim, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text('No gateways available', style: TextStyle(color: _textDim)),
        ],
      ),
    );
  }

  Widget _buildBusyState() {
    final availableAt = _busyAvailableAt ?? DateTime.now().add(const Duration(minutes: 5));

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              color: Colors.orange,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'All Gateways Busy',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Currently all our deposit gateways are occupied. Please wait for a few minutes and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textDim, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _bgDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Text(
                  'NEXT AVAILABLE IN',
                  style: GoogleFonts.inter(
                    color: _textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                LiveTimerWidget(
                  expiresAt: availableAt,
                  onExpired: () => _fetchData(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(Map<String, dynamic> wallet) {
    final expiresAt = _expiresAt ?? DateTime.now().add(const Duration(minutes: 30));

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (wallet['name']?.toString() ?? '').isNotEmpty
                    ? wallet['name'].toString().toUpperCase()
                    : '${wallet['network']} GATEWAY',
                style: GoogleFonts.inter(
                  color: _primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              _CopyButton(address: wallet['address']?.toString() ?? ''),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: '${wallet['address'] ?? ''}$_qrSeed',
              version: QrVersions.auto,
              size: 200.0,
              gapless: false,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            wallet['address']?.toString() ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 14, letterSpacing: 0.5),
          ),
          
          if (_activeTransaction != null) ...[
            const SizedBox(height: 24),
            Divider(color: _border, height: 1),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AMOUNT TO SEND',
                  style: GoogleFonts.inter(
                    color: _textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                ExpandableAmount(
                  amount: (_activeTransaction!['amount'] as num).toDouble(),
                  suffix: ' USDT',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ],
            ),
            if (_activeTransaction!['conversionRate'] != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PAYABLE AMOUNT',
                    style: GoogleFonts.inter(
                      color: _textDim,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  ExpandableAmount(
                    amount: (_activeTransaction!['amount'] as num).toDouble() *
                        (_activeTransaction!['conversionRate'] as num).toDouble(),
                    prefix: '₹',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
          
          const SizedBox(height: 24),
          LiveTimerWidget(expiresAt: expiresAt, onExpired: () => _fetchData()),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String address;
  const _CopyButton({required this.address});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: widget.address));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied to clipboard')),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    return GestureDetector(
      onTap: _handleCopy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(_copied ? Icons.check : Icons.copy, color: primary, size: 12),
            const SizedBox(width: 6),
            Text(
              _copied ? 'COPIED' : 'COPY',
              style: GoogleFonts.inter(
                color: primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
