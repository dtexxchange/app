import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart' show themeService;
import '../services/api_service.dart';

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
      if (mounted) {
        if (res.statusCode == 200) {
          setState(() {
            _user = jsonDecode(res.body);
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: theme.primaryColor,
        backgroundColor: theme.cardColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor.withValues(
                alpha: 0.9,
              ),
              elevation: 0,
              titleSpacing: 24,
              title: Text(
                'Profile',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: theme.dividerColor),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
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
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final initial =
        (_user?['firstName']?.toString() ?? _user?['email']?.toString() ?? 'U')
            .substring(0, 1)
            .toUpperCase();
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.10),
            shape: BoxShape.circle,
            border: Border.all(color: primary.withOpacity(0.20), width: 2),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.15),
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
                color: primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          (_user?['firstName'] != null || _user?['lastName'] != null)
              ? '${_user?['firstName'] ?? ''} ${_user?['lastName'] ?? ''}'
                    .trim()
              : _user?['email'] ?? '',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withOpacity(0.20)),
          ),
          child: Text(
            'USER WORKSPACE',
            style: GoogleFonts.inter(
              color: primary,
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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.tag,
            label: 'User ID',
            value: _user?['readableId']?.toString() ?? '–',
            showCopy: true,
          ),
          Divider(height: 1, color: theme.dividerColor),
          _InfoRow(
            icon: Icons.person_outline,
            label: (_user?['firstName'] != null || _user?['lastName'] != null)
                ? 'Full Name'
                : 'Identity',
            value: (_user?['firstName'] != null || _user?['lastName'] != null)
                ? '${_user?['firstName'] ?? ''} ${_user?['lastName'] ?? ''}'
                      .trim()
                : 'Not Set',
          ),
          Divider(height: 1, color: theme.dividerColor),
          _InfoRow(
            icon: Icons.mail_outline,
            label: 'Email',
            value: _user?['email'] ?? '–',
          ),
          Divider(height: 1, color: theme.dividerColor),
          _InfoRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Account Status',
            value: 'Active',
            valueColor: theme.primaryColor,
          ),
          Divider(height: 1, color: theme.dividerColor),
          _InfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Security',
            value: 'OTP Auth',
            valueColor: theme.primaryColor,
          ),
          Divider(height: 1, color: theme.dividerColor),
          // Theme Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Dark Appearance',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
                Switch(
                  value: theme.brightness == Brightness.dark,
                  activeColor: theme.primaryColor,
                  onChanged: (v) => themeService.toggleTheme(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          _ActionRow(
            icon: Icons.lock_outline,
            label: 'Passcode Settings',
            onTap: () => Navigator.pushNamed(
              context,
              '/passcode',
            ).then((_) => _fetchProfile()),
          ),
          Divider(height: 1, color: theme.dividerColor),
          _ActionRow(
            icon: Icons.account_balance_outlined,
            label: 'Saved Bank Accounts',
            onTap: () => Navigator.pushNamed(context, '/bank-accounts'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    const danger = Color(0xFFF87171);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 18, color: danger),
            label: const Text(
              'Sign Out',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: danger,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: danger,
              side: BorderSide(color: danger.withOpacity(0.30)),
              backgroundColor: danger.withOpacity(0.06),
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
  final bool showCopy;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.showCopy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showCopy && value != '–') ...[
                const SizedBox(width: 8),
                _CopyButton(label: label, value: value),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String label;
  final String value;
  const _CopyButton({required this.label, required this.value});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  void _handleCopy() {
    final primary = Theme.of(context).primaryColor;
    Clipboard.setData(ClipboardData(text: widget.value));
    setState(() => _copied = true);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.label} Copied',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 160,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: primary,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: _handleCopy,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _copied ? primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          _copied ? Icons.check_rounded : Icons.copy_rounded,
          size: 16,
          color: _copied
              ? primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurface, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
