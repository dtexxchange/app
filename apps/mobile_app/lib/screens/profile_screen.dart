import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

const _bgDark = Color(0xFF0A0B0D);
const _bgCard = Color(0xFF15171C);
const _primary = Color(0xFF00FF9D);
const _textDim = Color(0xFF94A3B8);
const _border = Color(0x0DFFFFFF);
const _danger = Color(0xFFF87171);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await _api.getRequest('/users/me');
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _user = jsonDecode(res.body);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await _api.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: _primary,
        backgroundColor: _bgCard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: _bgDark.withOpacity(0.9),
              elevation: 0,
              titleSpacing: 24,
              title: Text('Profile', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: _border)),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: _primary),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 60),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildAvatar(),
                    const SizedBox(height: 32),
                    _buildInfoCard(),
                    const SizedBox(height: 32),
                    _buildActionsCard(),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initial =
        _user?['email']?.toString().substring(0, 1).toUpperCase() ?? 'U';
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.10),
            shape: BoxShape.circle,
            border: Border.all(color: _primary.withOpacity(0.20), width: 2),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: GoogleFonts.outfit(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _user?['email'] ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primary.withOpacity(0.20)),
          ),
          child: Text(
            'USER WORKSPACE',
            style: GoogleFonts.inter(
              color: _primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.mail_outline,
            label: 'Email',
            value: _user?['email'] ?? '–',
          ),
          Divider(height: 1, color: _border),
          _InfoRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Account Status',
            value: 'Active',
            valueColor: _primary,
          ),
          Divider(height: 1, color: _border),
          _InfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Security',
            value: 'OTP Auth',
            valueColor: _primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 18, color: _danger),
            label: const Text(
              'Sign Out',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _danger,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _danger,
              side: BorderSide(color: _danger.withOpacity(0.30)),
              backgroundColor: _danger.withOpacity(0.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: _textDim, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _textDim, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
