import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard => Theme.of(context).cardColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).dividerColor;
  static const Color _danger = Color(0xFFF87171);

  final _api = ApiService();
  final _telegramCtrl = TextEditingController();
  String? _currentTelegram;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await _api.getRequest('/settings/help-telegram');

      if (mounted) {
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          setState(() {
            _currentTelegram = data['helpTelegram'];
            if (_currentTelegram != null) {
              _telegramCtrl.text = _currentTelegram!;
            }
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTelegram() async {
    final telegram = _telegramCtrl.text.trim();
    if (telegram.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Telegram account cannot be empty'),
          backgroundColor: _danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final res = await _api.patchRequest('/settings/admin/help-telegram', {
        'telegram': telegram,
      });
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Help Telegram account updated'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update account'),
            backgroundColor: _danger,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating account'),
          backgroundColor: _danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Help & Support',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEditCard(),
                  const SizedBox(height: 24),
                  _buildPreviewCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildEditCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Telegram Help Account',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the Telegram username or link that users can contact for support.',
            style: TextStyle(color: _textDim, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _telegramCtrl,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. @SupportAccount or https://t.me/Support',
              prefixIcon: Icon(Icons.telegram, color: _primary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primary, width: 2),
              ),
              filled: true,
              fillColor: _bgDark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveTelegram,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Save Help Account',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: _primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This account will be shown in the User App under Profile > Support & Help.',
              style: TextStyle(
                color: _textDim,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
