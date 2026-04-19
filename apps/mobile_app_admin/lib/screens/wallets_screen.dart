import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

// Tokens
const _bgDark = Color(0xFF0A0B0D);
const _bgCard = Color(0xFF15171C);
const _primary = Color(0xFF00FF9D);
const _textDim = Color(0xFF94A3B8);
const _border = Color(0x0DFFFFFF);
const _blue = Color(0xFF3B82F6);

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  final _api = ApiService();
  List<dynamic> _wallets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWallets();
  }

  Future<void> _fetchWallets() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getRequest('/settings/admin/wallets');
      if (res.statusCode == 200) {
        if (mounted) setState(() => _wallets = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addWallet(String address, String network, String name) async {
    try {
      final res = await _api.postRequest('/settings/admin/wallets', {
        'address': address,
        'network': network,
        'name': name,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        _fetchWallets();
        Navigator.pop(context); // Close modal
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _toggleWallet(String id, bool active) async {
    try {
      await _api.patchRequest('/settings/admin/wallets/$id', {
        'isActive': active,
      });
      _fetchWallets();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _deleteWallet(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        title: Text(
          'Delete Gateway',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to remove this settlement address?',
          style: TextStyle(color: _textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _api.deleteRequest('/settings/admin/wallets/$id');
      _fetchWallets();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _showAddModal() {
    final addressCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String network = 'TRC20';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgCard, _bgDark.withOpacity(0.9)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Text(
                'New Gateway',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure a new treasury address for user deposits.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _textDim, fontSize: 13),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Label / Name (Private)',
                  labelStyle: const TextStyle(color: _textDim, fontSize: 13),
                  hintText: 'e.g. Finance Hub 1',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
                  filled: true,
                  fillColor: _bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressCtrl,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  labelText: 'USDT Wallet Address',
                  labelStyle: const TextStyle(color: _textDim, fontSize: 13),
                  hintText: 'TX...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
                  filled: true,
                  fillColor: _bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: network,
                dropdownColor: _bgCard,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Blockchain Network',
                  labelStyle: const TextStyle(color: _textDim, fontSize: 13),
                  filled: true,
                  fillColor: _bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _primary),
                  ),
                ),
                items: ['TRC20', 'ERC20', 'BEP20', 'POLYGON'].map((n) {
                  return DropdownMenuItem(value: n, child: Text(n));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setLocalState(() => network = val);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (addressCtrl.text.isNotEmpty) {
                    _addWallet(addressCtrl.text, network, nameCtrl.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Initialize Gateway',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Treasury nodes',
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
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
            sliver: _isLoading
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: CircularProgressIndicator(color: _primary),
                      ),
                    ),
                  )
                : _wallets.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 100),
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.05),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No treasury nodes configured',
                            style: TextStyle(color: _textDim, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, i) {
                      final w = _wallets[i];
                      final isActive = w['isActive'] as bool;
                      return _buildWalletCard(w, isActive);
                    }, childCount: _wallets.length),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddModal,
        backgroundColor: _primary,
        elevation: 8,
        label: const Text(
          'NEW GATEWAY',
          style: TextStyle(color: Colors.black, fontSize: 12, letterSpacing: 1),
        ),
        icon: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildWalletCard(dynamic w, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isActive ? _border : Colors.redAccent.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive ? _primary : Colors.redAccent).withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              w['network'] ?? 'TRC20',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (isActive ? _primary : Colors.redAccent)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? 'ACTIVE' : 'DISABLED',
                              style: GoogleFonts.inter(
                                color: isActive ? _primary : Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.people_outline,
                                    color: _blue,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${w['_count']?['assignments'] ?? 0} USERS',
                                    style: GoogleFonts.inter(
                                      color: _blue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Switch.adaptive(
                        value: isActive,
                        activeColor: _primary,
                        activeTrackColor: _primary.withOpacity(0.2),
                        onChanged: (val) => _toggleWallet(w['id'], val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (w['name'] != null && w['name'].toString().isNotEmpty) ...[
                    Text(
                      w['name'].toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: _primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          w['address'],
                          style: GoogleFonts.firaCode(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: w['address']));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Address copied'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.copy,
                          size: 16,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _deleteWallet(w['id']),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    label: const Text(
                      'REMOVE NODE',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
