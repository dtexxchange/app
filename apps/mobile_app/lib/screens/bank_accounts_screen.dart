import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

const _bgDark = Color(0xFF0A0B0D);
const _bgCard = Color(0xFF15171C);
const _primary = Color(0xFF00FF9D);
const _blue = Color(0xFF3B82F6);
const _textDim = Color(0xFF94A3B8);
const _border = Color(0x0DFFFFFF);
const _danger = Color(0xFFF87171);

class BankAccountsScreen extends StatefulWidget {
  const BankAccountsScreen({super.key});

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  final _api = ApiService();
  List<dynamic> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getRequest('/bank-accounts');
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

  Future<void> _deleteAccount(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to remove this bank account?', style: TextStyle(color: _textDim)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: _danger)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await _api.deleteRequest('/bank-accounts/$id');
      if (res.statusCode == 200) {
        _fetchAccounts();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account removed')));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _showAddEditModal([Map<String, dynamic>? account]) {
    final nameCtrl = TextEditingController(text: account?['name']);
    final bankCtrl = TextEditingController(text: account?['bankName']);
    final accNoCtrl = TextEditingController(text: account?['accountNo']);
    final ifscCtrl = TextEditingController(text: account?['ifsc']);
    final isEdit = account != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? 'Edit Bank Account' : 'Add Bank Account', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            _buildField(nameCtrl, 'Account Holder Name'),
            const SizedBox(height: 16),
            _buildField(bankCtrl, 'Bank Name'),
            const SizedBox(height: 16),
            _buildField(accNoCtrl, 'Account Number'),
            const SizedBox(height: 16),
            _buildField(ifscCtrl, 'IFSC Code / Routing'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': nameCtrl.text,
                  'bankName': bankCtrl.text,
                  'accountNo': accNoCtrl.text,
                  'ifsc': ifscCtrl.text,
                };
                final res = isEdit 
                  ? await _api.patchRequest('/bank-accounts/${account['id']}', data)
                  : await _api.postRequest('/bank-accounts', data);
                
                if (res.statusCode == 200 || res.statusCode == 201) {
                  Navigator.pop(ctx);
                  _fetchAccounts();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isEdit ? 'Update Account' : 'Save Account', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textDim, fontSize: 14),
        filled: true,
        fillColor: _bgDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        title: Text(
          'My Bank Accounts', 
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 18 : 20,
          )
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddEditModal(),
            icon: const Icon(Icons.add_circle_outline, color: _primary),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: _primary))
        : _accounts.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(isSmall ? 16 : 24),
              itemCount: _accounts.length,
              itemBuilder: (ctx, i) => _buildAccountItem(_accounts[i], context),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance, size: 64, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          const Text('No saved bank accounts', style: TextStyle(color: _textDim)),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => _showAddEditModal(),
            icon: const Icon(Icons.add),
            label: const Text('Add your first account'),
            style: TextButton.styleFrom(foregroundColor: _primary),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem(Map<String, dynamic> acc, BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isSmall ? 16 : 20),
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
              Text(acc['bankName'], style: GoogleFonts.inter(color: _primary, fontWeight: FontWeight.bold, fontSize: isSmall ? 10 : 12, letterSpacing: 1)),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showAddEditModal(acc), 
                    icon: Icon(Icons.edit_outlined, size: isSmall ? 16 : 18, color: _textDim),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  IconButton(
                    onPressed: () => _deleteAccount(acc['id']), 
                    icon: Icon(Icons.delete_outline, size: isSmall ? 16 : 18, color: _danger),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(acc['name'], style: GoogleFonts.outfit(fontSize: isSmall ? 16 : 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(acc['accountNo'], style: TextStyle(color: _textDim, letterSpacing: 1.2, fontSize: isSmall ? 13 : 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: _textDim),
              const SizedBox(width: 6),
              Text('IFSC: ${acc['ifsc']}', style: TextStyle(color: _textDim, fontSize: isSmall ? 11 : 12)),
              const Spacer(),
              TextButton(
                onPressed: () => _showLogs(acc['id']),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Logs', style: TextStyle(fontSize: isSmall ? 11 : 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogs(String id) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => FutureBuilder(
        future: _api.getRequest('/bank-accounts/$id/logs'),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final logs = jsonDecode(snapshot.data!.body) as List;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modification History', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 24),
                if (logs.isEmpty) const Text('No logs available', style: TextStyle(color: _textDim)),
                ...logs.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l['action'], style: TextStyle(color: l['action'] == 'DELETE' ? _danger : _primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(l['createdAt'])), style: const TextStyle(color: _textDim, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}
