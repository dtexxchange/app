import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

// Tokens
const _bgDark = Color(0xFF0A0B0D);
const _bgCard = Color(0xFF15171C);
const _primary = Color(0xFF00FF9D);
const _textDim = Color(0xFF94A3B8);
const _border = Color(0x0DFFFFFF);

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

  Future<void> _addWallet(String address, String network) async {
    try {
      final res = await _api.postRequest('/settings/admin/wallets', {
        'address': address,
        'network': network,
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
    try {
      await _api.deleteRequest('/settings/admin/wallets/$id');
      _fetchWallets();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _showAddModal() {
    final addressCtrl = TextEditingController();
    String network = 'TRC20';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Gateway',
                style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: addressCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Wallet Address',
                  labelStyle: const TextStyle(color: _textDim),
                  filled: true,
                  fillColor: _bgDark,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: network,
                dropdownColor: _bgDark,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Network',
                  labelStyle: const TextStyle(color: _textDim),
                  filled: true,
                  fillColor: _bgDark,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border)),
                ),
                items: ['TRC20', 'ERC20', 'BEP20', 'POLYGON'].map((n) {
                  return DropdownMenuItem(value: n, child: Text(n));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setLocalState(() => network = val);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (addressCtrl.text.isNotEmpty) {
                    _addWallet(addressCtrl.text, network);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Gateway',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
      appBar: AppBar(
        backgroundColor: _bgDark,
        title: Text('Settlement Gateways',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _wallets.isEmpty
              ? const Center(
                  child: Text('No wallets configured',
                      style: TextStyle(color: _textDim)))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _wallets.length,
                  itemBuilder: (ctx, i) {
                    final w = _wallets[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${w['network']} GATEWAY',
                                  style: GoogleFonts.inter(
                                      color: _textDim,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1)),
                              Switch(
                                value: w['isActive'],
                                activeColor: _primary,
                                onChanged: (val) =>
                                    _toggleWallet(w['id'], val),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(w['address'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'monospace')),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _deleteWallet(w['id']),
                              icon: const Icon(Icons.delete_outline,
                                  size: 16, color: Colors.redAccent),
                              label: const Text('Delete',
                                  style: TextStyle(
                                      color: Colors.redAccent, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModal,
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
