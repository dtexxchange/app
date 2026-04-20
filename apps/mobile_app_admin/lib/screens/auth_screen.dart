import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

const _bgDark  = Color(0xFF0A0B0D);
const _bgCard  = Color(0xFF15171C);
const _primary = Color(0xFF00FF9D);
const _textDim = Color(0xFF94A3B8);
const _border  = Color(0x0DFFFFFF);
const _danger  = Color(0xFFF87171);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _otpController   = TextEditingController();
  bool _otpSent   = false;
  bool _isLoading = false;
  final _api = ApiService();

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.postRequest('/auth/send-otp', {
        'email': _emailController.text,
      });
      if (res.statusCode == 201 || res.statusCode == 200) {
        if (_otpSent && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: const Text('OTP sent successfully', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
               backgroundColor: _primary,
               behavior: SnackBarBehavior.floating,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               margin: const EdgeInsets.all(16),
             ),
           );
        }
        setState(() => _otpSent = true);
      } else {
        final body = jsonDecode(res.body);
        _showError(body['message'] ?? 'Error sending OTP');
      }
    } catch (e) {
      debugPrint('Admin connection error: $e');
      _showError('Connection error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.postRequest('/auth/verify-otp', {
        'email': _emailController.text,
        'code': _otpController.text,
      });
      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = jsonDecode(res.body);

        // Block non-admin users from accessing the admin app
        if (body['user']?['role'] != 'ADMIN') {
          _showError('Access denied. Admin accounts only.');
          setState(() => _isLoading = false);
          return;
        }

        await _api.saveToken(body['access_token']);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        _showError('Invalid OTP');
      }
    } catch (e) {
      debugPrint('Admin verification error: $e');
      _showError('Verification error: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: _danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(children: [
        // Ambient glow blobs
        Positioned(
          top: -80, left: -60,
          child: Container(
            width: 280, height: 280,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _primary.withOpacity(0.12)),
          ),
        ),
        Positioned(
          bottom: -80, right: -60,
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF3B82F6).withOpacity(0.12)),
          ),
        ),

        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _bgCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _border),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Logo mark
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _primary.withOpacity(0.20)),
                      boxShadow: [BoxShadow(color: _primary.withOpacity(0.15), blurRadius: 30)],
                    ),
                    child: const Icon(Icons.diamond_outlined, color: _primary, size: 36),
                  ),
                  const SizedBox(height: 28),

                  Text('Admin Workspace', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    _otpSent
                        ? 'Check your inbox for the authorization code'
                        : 'Enter your administration email address',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _textDim, fontSize: 14),
                  ),
                  const SizedBox(height: 36),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _otpSent ? _buildOtpStep() : _buildEmailStep(),
                  ),

                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.shield_outlined, color: _textDim, size: 18),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Admin access only. Unauthorized attempts are monitored and recorded.',
                          style: TextStyle(color: _textDim, fontSize: 11, height: 1.6),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'admin@company.com',
            hintStyle: const TextStyle(color: _textDim),
            prefixIcon: const Icon(Icons.mail_outline, color: _textDim, size: 20),
            filled: true, fillColor: Colors.white.withOpacity(0.03),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.10))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary)),
          ),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(onPressed: _isLoading ? null : _sendOtp, label: 'Continue', isLoading: _isLoading, icon: Icons.arrow_forward),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 12),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), letterSpacing: 12, fontSize: 28),
            counterText: '',
            prefixIcon: const Icon(Icons.key_outlined, color: _textDim, size: 20),
            filled: true, fillColor: Colors.white.withOpacity(0.03),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.10))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary)),
          ),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(onPressed: _isLoading ? null : _verifyOtp, label: 'Verify & Sign In', isLoading: _isLoading),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: const Text('Resend Code', style: TextStyle(color: _primary, fontSize: 14)),
        ),
        TextButton(
          onPressed: () => setState(() => _otpSent = false),
          child: const Text('Use a different email', style: TextStyle(color: _textDim, fontSize: 14)),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final IconData? icon;
  const _PrimaryButton({required this.onPressed, required this.label, this.isLoading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.black,
          disabledBackgroundColor: _primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 18)],
              ]),
      ),
    );
  }
}
