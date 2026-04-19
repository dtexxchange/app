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
      const SnackBar(
        content: Text('Referral code copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF00FF9D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      appBar: AppBar(
        title: Text('Referral Network', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF9D)))
        : RefreshIndicator(
            onRefresh: _fetchData,
            color: const Color(0xFF00FF9D),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReferralCard(),
                  const SizedBox(height: 32),
                  Text(
                    'Friends who joined (${_referrals.length})',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _referrals.isEmpty 
                    ? _buildEmptyState()
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _referrals.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildReferralItem(_referrals[index]),
                      ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildReferralCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00FF9D).withOpacity(0.15),
            const Color(0xFF3B82F6).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Icon(Icons.stars, color: Color(0xFF00FF9D), size: 48),
          const SizedBox(height: 24),
          Text(
            'Share the wealth',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Invite friends and track your network as it grows.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00FF9D).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _referralCode ?? '------',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00FF9D),
                    letterSpacing: 4,
                  ),
                ),
                IconButton(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy, color: Color(0xFF00FF9D)),
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
          Icon(Icons.people_outline, color: Colors.white.withOpacity(0.1), size: 64),
          const SizedBox(height: 16),
          Text(
            'No referrals yet',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
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
        color: const Color(0xFF15171C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person, color: Color(0xFF3B82F6), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (user['firstName'] != null || user['lastName'] != null)
                      ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim()
                      : user['email'],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  'Joined ${_formatDate(user['createdAt'])}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isApproved ? const Color(0xFF00FF9D).withOpacity(0.05) : Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isApproved ? const Color(0xFF00FF9D).withOpacity(0.2) : Colors.orange.withOpacity(0.2)),
            ),
            child: Text(
              isApproved ? 'APPROVED' : 'PENDING',
              style: TextStyle(
                color: isApproved ? const Color(0xFF00FF9D) : Colors.orange,
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
