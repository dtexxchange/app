import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard => Theme.of(context).cardColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).dividerColor;
  static const Color _blue = Color(0xFF3B82F6);

  final _api = ApiService();
  bool _isLoading = true;
  String? _referralCode;
  List<dynamic> _referrals = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Get user info for their referral code
      final userRes = await _api.getRequest('/users/me');
      final userData = jsonDecode(userRes.body);

      // Get referrals list
      final referRes = await _api.getRequest('/users/me/referrals');
      final referData = jsonDecode(referRes.body);

      setState(() {
        _referralCode = userData['referralCode'];
        _referrals = referData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching referral data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard() {
    if (_referralCode == null) return;
    Clipboard.setData(ClipboardData(text: _referralCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Referral code copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _primary,
      ),
    );
  }

  void _copyLinkToClipboard() {
    if (_referralCode == null) return;
    final link = '${ApiService.webUrl}/signup?ref=$_referralCode';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Referral link copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final widthScale = (size.width / 375.0).clamp(0.85, 1.2);
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        title: Text(
          'Referral Network',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18 * widthScale,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: _primary,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24 * widthScale),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReferralCard(widthScale),
                    SizedBox(height: 32 * widthScale),
                    Text(
                      'Friends who joined (${_referrals.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 20 * widthScale,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _referrals.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _referrals.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _buildReferralItem(_referrals[index]),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReferralCard(double widthScale) {
    return Container(
      padding: EdgeInsets.all(32 * widthScale),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary.withOpacity(0.15), _blue.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(Icons.stars, color: _primary, size: 48 * widthScale),
          SizedBox(height: 24 * widthScale),
          Text(
            'Share the wealth',
            style: GoogleFonts.outfit(
              fontSize: 24 * widthScale,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite friends and track your network as it grows.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textDim, fontSize: 13 * widthScale),
          ),
          const SizedBox(height: 32),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20 * widthScale,
              vertical: 12 * widthScale,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _referralCode ?? '------',
                      style: GoogleFonts.outfit(
                        fontSize: 28 * widthScale,
                        fontWeight: FontWeight.bold,
                        color: _primary,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _copyToClipboard,
                  icon: Icon(
                    Icons.copy,
                    color: _primary,
                    size: 20 * widthScale,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QUICK SHARE LINK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${ApiService.webUrl}/signup?ref=${_referralCode ?? '------'}',
                        style: GoogleFonts.firaCode(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _copyLinkToClipboard,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.copy,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
            Icons.people_outline,
            color: Colors.white.withValues(alpha: 0.1),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No referrals yet',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralItem(dynamic user) {
    bool isApproved = user['status'] == 'APPROVED';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person, color: _blue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (user['firstName'] != null || user['lastName'] != null)
                      ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                            .trim()
                      : user['email'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Joined ${_formatDate(user['createdAt'])}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isApproved
                  ? _primary.withOpacity(0.05)
                  : Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isApproved
                    ? _primary.withValues(alpha: 0.2)
                    : Colors.orange.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              isApproved ? 'APPROVED' : 'PENDING',
              style: TextStyle(
                color: isApproved ? _primary : Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
