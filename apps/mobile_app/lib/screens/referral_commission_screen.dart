import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'transaction_detail_screen.dart';

class ReferralCommissionScreen extends StatefulWidget {
  final Map<String, dynamic> referredUser;

  const ReferralCommissionScreen({super.key, required this.referredUser});

  @override
  State<ReferralCommissionScreen> createState() => _ReferralCommissionScreenState();
}

class _ReferralCommissionScreenState extends State<ReferralCommissionScreen> {
  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard => Theme.of(context).cardColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).dividerColor;
  static const Color _blue = Color(0xFF3B82F6);

  final _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _commissions = [];
  double _totalCommission = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCommissions();
  }

  Future<void> _fetchCommissions() async {
    setState(() => _isLoading = true);
    try {
      // Fetch transactions of type REFERRAL_COMMISSION related to this user
      final res = await _api.getRequest(
        '/wallet/transactions?type=REFERRAL_COMMISSION&relatedUserId=${widget.referredUser['id']}',
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        
        // Calculate total
        double total = 0;
        for (var tx in data) {
          total += (tx['amount'] as num).toDouble();
        }

        setState(() {
          _commissions = data;
          _totalCommission = total;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching commissions: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final widthScale = (size.width / 375.0).clamp(0.85, 1.2);
    final userName = (widget.referredUser['firstName'] != null || widget.referredUser['lastName'] != null)
        ? '${widget.referredUser['firstName'] ?? ''} ${widget.referredUser['lastName'] ?? ''}'.trim()
        : widget.referredUser['email'];

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        title: Text(
          'Commissions',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18 * widthScale,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: _fetchCommissions,
              color: _primary,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.all(24 * widthScale),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildHeaderCard(userName, widthScale),
                        SizedBox(height: 32 * widthScale),
                        Text(
                          'History',
                          style: GoogleFonts.outfit(
                            fontSize: 18 * widthScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_commissions.isEmpty)
                          _buildEmptyState()
                        else
                          ..._commissions.map((tx) => _buildCommissionTile(tx, widthScale)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(String userName, double widthScale) {
    return Container(
      padding: EdgeInsets.all(24 * widthScale),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primary.withValues(alpha: 0.15),
            _blue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30 * widthScale,
            backgroundColor: _blue.withValues(alpha: 0.1),
            child: Icon(Icons.person, color: _blue, size: 30 * widthScale),
          ),
          SizedBox(height: 16 * widthScale),
          Text(
            userName,
            style: GoogleFonts.outfit(
              fontSize: 20 * widthScale,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Total Earnings from this user',
            style: TextStyle(color: _textDim, fontSize: 12 * widthScale),
          ),
          SizedBox(height: 24 * widthScale),
          Text(
            '${NumberFormat('#,##0.00').format(_totalCommission)} USDT',
            style: GoogleFonts.outfit(
              fontSize: 32 * widthScale,
              fontWeight: FontWeight.bold,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: Colors.white.withValues(alpha: 0.1),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No commissions yet',
            style: TextStyle(
              color: _textDim,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionTile(Map<String, dynamic> tx, double widthScale) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionDetailScreen(tx: tx),
        ),
      ),
      child: Container(
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_downward, color: _primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Referral Commission',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(tx['createdAt'])),
                    style: TextStyle(color: _textDim, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '+${NumberFormat('#,##0.00').format(tx['amount'])} USDT',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: _primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
