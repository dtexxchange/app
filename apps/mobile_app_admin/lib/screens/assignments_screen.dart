import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

const _bgDark = Color(0xFF0A0B0D);
const _bgCard = Color(0xFF15171C);
const _primary = Color(0xFF00FF9D);
const _blue = Color(0xFF3B82F6);
const _textDim = Color(0xFF94A3B8);
const _border = Color(0x0DFFFFFF);
const _danger = Color(0xFFF87171);

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final _api = ApiService();
  List<dynamic> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getRequest('/settings/admin/assignments');
      if (res.statusCode == 200) {
        if (mounted) setState(() => _assignments = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: _bgDark,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Live QR Views',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_primary.withOpacity(0.05), _bgDark],
                  ),
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            sliver: _isLoading
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: CircularProgressIndicator(color: _primary),
                      ),
                    ),
                  )
                : _assignments.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 100),
                          Icon(
                            Icons.qr_code_scanner,
                            size: 64,
                            color: Colors.white.withOpacity(0.05),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No active QR views matching users',
                            style: TextStyle(color: _textDim, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, i) {
                      final a = _assignments[i];
                      return _buildAssignmentCard(a);
                    }, childCount: _assignments.length),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(dynamic a) {
    final user = a['user'];
    final wallet = a['wallet'];
    final expiresAt = DateTime.tryParse(a['expiresAt'] ?? '');
    final now = DateTime.now();
    final minutesLeft = expiresAt != null
        ? expiresAt.difference(now).inMinutes
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      (user['firstName'] ?? user['email'] ?? '?')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (user['firstName'] != null || user['lastName'] != null)
                            ? '${user['firstName']} ${user['lastName']}'.trim()
                            : user['email'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        user['email'],
                        style: const TextStyle(color: _textDim, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${minutesLeft}M LEFT',
                    style: GoogleFonts.inter(color: _blue, fontSize: 9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: _border, height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ASSIGNED WALLET',
                  style: TextStyle(
                    color: _textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  wallet['name']?.toString().toUpperCase() ?? wallet['network'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ADDRESS',
                  style: TextStyle(
                    color: _textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Flexible(
                  child: Text(
                    wallet['address'],
                    style: GoogleFonts.firaCode(
                      color: _primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
