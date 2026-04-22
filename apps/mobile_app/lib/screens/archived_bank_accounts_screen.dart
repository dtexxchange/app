import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ArchivedBankAccountsScreen extends StatefulWidget {
  const ArchivedBankAccountsScreen({super.key});

  @override
  State<ArchivedBankAccountsScreen> createState() => _ArchivedBankAccountsScreenState();
}

class _ArchivedBankAccountsScreenState extends State<ArchivedBankAccountsScreen> {
  // ─── Design Tokens ──────────────────────────────────────────────────────────
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard => Theme.of(context).cardColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).dividerColor;
  
  final _api = ApiService();
  List<dynamic> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchArchivedAccounts();
  }

  Future<void> _fetchArchivedAccounts() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getRequest('/bank-accounts/archived');
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _accounts = jsonDecode(res.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreAccount(String id) async {
    try {
      final res = await _api.postRequest('/bank-accounts/$id/restore', {});
      if ((res.statusCode == 201 || res.statusCode == 200) && mounted) {
        _fetchArchivedAccounts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account restored')),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Archived Accounts',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : _accounts.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: _accounts.length,
              itemBuilder: (ctx, i) => _buildAccountItem(_accounts[i]),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.archive_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ),
          const SizedBox(height: 16),
          Text(
            'No archived accounts found',
            style: GoogleFonts.inter(color: _textDim, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem(Map<String, dynamic> acc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                acc['bankName'].toString().toUpperCase(),
                style: GoogleFonts.inter(
                  color: _textDim,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _restoreAccount(acc['id']),
                  icon: Icon(Icons.unarchive_outlined, color: _primary, size: 20),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  tooltip: 'Restore Account',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            acc['name'],
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            acc['accountNo'],
            style: GoogleFonts.inter(
              color: _textDim,
              letterSpacing: 1.2,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ARCHIVED',
            style: GoogleFonts.inter(
              color: Colors.orange.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
