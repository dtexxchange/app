import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';

// ─── Design Tokens ───────────────────────────────────────────────────────────
const _bgDark   = Color(0xFF0A0B0D);
const _bgCard   = Color(0xFF15171C);
const _primary  = Color(0xFF00FF9D);
const _blue     = Color(0xFF3B82F6);
const _textDim  = Color(0xFF94A3B8);
const _border   = Color(0x0DFFFFFF); // 5% white
const _danger   = Color(0xFFF87171);

// ─── Shared Sheet Components ─────────────────────────────────────────────────
class CustomBottomSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const CustomBottomSheet({required this.title, required this.icon, required this.iconColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
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
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            ]),
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
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: '0.00',
        hintStyle: GoogleFonts.outfit(color: Colors.white.withOpacity(0.2), fontSize: 32, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.10))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00FF9D))),
      ),
    );
  }
}

class SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  const SheetField({required this.controller, required this.hint, this.keyboardType});

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
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.10))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00FF9D))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const PrimaryButton({required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00FF9D),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _balance = 0;
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  final _api = ApiService();

  // QR Logic
  String? _walletId;
  Timer? _timer;
  int _timeLeft = 300; // 5 minutes in seconds
  String _qrData = "";

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchWalletId();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 300;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
            _generateQrData();
            _timeLeft = 300;
          }
        });
      }
    });
  }

  void _generateQrData() {
    if (_walletId != null) {
      // Add a timestamp to regenerate the QR code visually even if ID is same
      setState(() {
        _qrData = '$_walletId?t=${DateTime.now().millisecondsSinceEpoch}';
      });
    }
  }

  Future<void> _fetchWalletId() async {
    try {
      final res = await _api.getRequest('/settings/wallet-id');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _walletId = data['walletId'];
          _generateQrData();
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _fetchData() async {
    try {
      final userRes = await _api.getRequest('/users/me');
      final txRes   = await _api.getRequest('/wallet/transactions');
      if (userRes.statusCode == 200 && txRes.statusCode == 200) {
        setState(() {
          _balance      = (jsonDecode(userRes.body)['balance'] as num).toDouble();
          _transactions = jsonDecode(txRes.body);
          _isLoading    = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() => _isLoading = false);
    }
  }

  // ─── Deposit Sheet ──────────────────────────────────────────────────────────
  void _showDepositSheet() {
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomBottomSheet(
        title: 'Deposit Funds',
        icon: Icons.arrow_downward,
        iconColor: _primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sheetLabel('Amount (USDT)'),
            const SizedBox(height: 8),
            AmountField(controller: amountCtrl),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: GhostButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx))),
              const SizedBox(width: 12),
              Expanded(child: PrimaryButton(
                label: 'Submit',
                onPressed: () async {
                  await _api.postRequest('/wallet/deposit', {'amount': double.parse(amountCtrl.text)});
                  Navigator.pop(ctx);
                  _fetchData();
                },
              )),
            ]),
          ],
        ),
      ),
    );
  }

  // ─── Withdraw Sheet ─────────────────────────────────────────────────────────
  void _showWithdrawSheet() {
    final amountCtrl  = TextEditingController();
    final nameCtrl    = TextEditingController();
    final accountCtrl = TextEditingController();
    final bankCtrl    = TextEditingController();
    final ifscCtrl    = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomBottomSheet(
        title: 'Withdraw Funds',
        icon: Icons.arrow_upward,
        iconColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sheetLabel('Amount (USDT)'),
            const SizedBox(height: 8),
            AmountField(controller: amountCtrl),
            const SizedBox(height: 20),
            // E2EE divider
            Row(children: [
              Expanded(child: Divider(color: _border, thickness: 1)),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _bgDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Row(children: [
                  const Icon(Icons.shield_outlined, color: _primary, size: 12),
                  const SizedBox(width: 6),
                  Text('E2EE Encrypted', style: GoogleFonts.inter(color: _primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ]),
              ),
              Expanded(child: Divider(color: _border, thickness: 1)),
            ]),
            const SizedBox(height: 16),
            SheetField(controller: nameCtrl, hint: 'Beneficiary Account Name'),
            const SizedBox(height: 12),
            SheetField(controller: accountCtrl, hint: 'Account Number', keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: SheetField(controller: bankCtrl, hint: 'Bank Name')),
              const SizedBox(width: 12),
              Expanded(child: SheetField(controller: ifscCtrl, hint: 'IFSC Code')),
            ]),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: GhostButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx))),
              const SizedBox(width: 12),
              Expanded(child: PrimaryButton(
                label: 'Confirm',
                onPressed: () async {
                  String pubKey = "";
                  if (CryptoService.enableE2EE) {
                    final keyRes = await _api.getRequest('/wallet/admin/public-key');
                    pubKey = jsonDecode(keyRes.body)['publicKey'];
                  }
                  final encrypted = CryptoService.encrypt(pubKey, {
                    'name': nameCtrl.text, 'account': accountCtrl.text,
                    'bank': bankCtrl.text, 'ifsc': ifscCtrl.text,
                  });
                  await _api.postRequest('/wallet/withdraw', {
                    'amount': double.parse(amountCtrl.text),
                    'bankDetails': encrypted,
                  });
                  Navigator.pop(ctx);
                  _fetchData();
                },
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sheetLabel(String text) => Text(
    text.toUpperCase(),
    style: GoogleFonts.inter(color: _textDim, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
  );

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
                  _buildAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                    sliver: SliverList(delegate: SliverChildListDelegate([
                      _buildBalanceCard(),
                      const SizedBox(height: 32),
                      _buildQrSection(),
                      const SizedBox(height: 32),
                      _buildTransactionsSection(),
                    ])),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQrSection() {
    if (_walletId == null) return const SizedBox();
    
    final minutes = (_timeLeft / 60).floor();
    final seconds = (_timeLeft % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(24),
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
              Text(
                'DEPOSIT ADDRESS',
                style: GoogleFonts.inter(color: _textDim, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: _primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '$minutes:$seconds',
                    style: GoogleFonts.inter(color: _primary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
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
              data: _qrData,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Scan this QR to deposit USDT',
            style: TextStyle(color: _textDim, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SelectableText(
            _walletId!,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _bgDark.withOpacity(0.9),
      elevation: 0,
      titleSpacing: 24,
      title: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _primary.withOpacity(0.20)),
          ),
          child: const Icon(Icons.diamond_outlined, color: _primary, size: 18),
        ),
        const SizedBox(width: 12),
        RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            children: [
              const TextSpan(text: 'USDT'),
              TextSpan(text: '.EX', style: TextStyle(color: Colors.white.withOpacity(0.4))),
            ],
          ),
        ),
      ]),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(28),
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
                style: GoogleFonts.inter(color: _textDim, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _primary.withOpacity(0.20)),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: _primary, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  NumberFormat('#,##0.00').format(_balance),
                  style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Text('USDT', style: GoogleFonts.outfit(color: _primary, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(child: PrimaryButton(label: 'Add Money', icon: Icons.arrow_downward, onPressed: _showDepositSheet)),
            const SizedBox(width: 12),
            Expanded(child: GhostButton(label: 'Withdraw', icon: Icons.arrow_upward, onPressed: _showWithdrawSheet)),
          ]),
        ],
      ),
    );
  }


  Widget _buildTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          const Icon(Icons.receipt_long, color: _primary, size: 22),
          const SizedBox(width: 10),
          Text('Transaction History', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        ]),
        const SizedBox(height: 16),
        if (_transactions.isEmpty)
          _buildEmptyState()
        else
          ..._transactions.map((tx) => _buildTxTile(tx)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.show_chart, size: 48, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text('No transactions found', style: TextStyle(color: _textDim, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTxTile(Map<String, dynamic> tx) {
    final isDeposit = tx['type'] == 'DEPOSIT';
    final status = tx['status'] as String? ?? 'PENDING';

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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(children: [
          // Type icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isDeposit ? _primary.withOpacity(0.10) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
              size: 20,
              color: isDeposit ? _primary : Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                tx['type'].toString().toLowerCase().capitalize(),
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 3),
              Text(
                'TX-${tx['id']?.toString().substring(0, 8).toUpperCase() ?? 'UNKNOWN'}',
                style: const TextStyle(color: _textDim, fontSize: 11),
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${isDeposit ? '+' : '-'}${NumberFormat('#,##0.00').format(tx['amount'] as num)} USDT',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: isDeposit ? _primary : Colors.white),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, size: 10, color: statusColor),
                const SizedBox(width: 4),
                Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              ]),
            ),
          ]),
        ]),
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
                      _DetailRow(
                        label: 'TYPE',
                        value: tx['type'] ?? 'Unknown',
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'AMOUNT',
                        value:
                            '${NumberFormat('#,##0.00').format(tx['amount'] as num)} USDT',
                        valueColor: isDeposit ? _primary : Colors.white,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                if (bank != null) ...[
                  const Text(
                    'WITHDRAWAL INSTRUCTIONS',
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
                    (log) =>
                        _buildLogItem(log, logs.indexOf(log) == logs.length - 1),
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
                    child: const Text('Close',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
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
                        DateFormat('MMM dd, HH:mm').format(DateTime.parse(log['createdAt'])),
                        style: const TextStyle(color: _textDim, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(log['note'] ?? 'Status updated', style: const TextStyle(color: _textDim, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('by ${log['actor']}', style: TextStyle(color: _primary.withOpacity(0.5), fontSize: 11)),
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


extension StringExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
