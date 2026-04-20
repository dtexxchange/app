import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'signup_screen.dart';
import 'main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
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
               backgroundColor: const Color(0xFF00FF9D),
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
      debugPrint('Connection error details: $e');
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

        // Block admin users from accessing the user app
        if (body['user']?['role'] == 'ADMIN') {
          _showError('Account not registered, please register first');
          setState(() => _isLoading = false);
          return;
        }

        await _api.saveToken(body['access_token']);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        final body = jsonDecode(res.body);
        _showError(body['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      debugPrint('Verification error details: $e');
      _showError('Verification error: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFF87171),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      body: Stack(
        children: [
          // Ambient glow blobs
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00FF9D).withOpacity(0.12),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.12),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15171C),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo mark
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF9D).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF00FF9D).withOpacity(0.20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FF9D).withOpacity(0.15),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.diamond_outlined,
                          color: Color(0xFF00FF9D),
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Title
                      Text(
                        'Workspace Access',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _otpSent
                            ? 'Check your inbox for the authorization code'
                            : 'Enter your whitelisted email address',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Step indicator
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, animation) =>
                            SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: Offset(_otpSent ? 1 : -1, 0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                        child: _otpSent ? _buildOtpStep() : _buildEmailStep(),
                      ),

                      // Security disclaimer
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Protected by end-to-end encryption. Unregistered access attempts are monitored.',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'name@example.com',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(
              Icons.mail_outline,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00FF9D)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(
          onPressed: _isLoading ? null : _sendOtp,
          isLoading: _isLoading,
          label: 'Continue',
          icon: Icons.arrow_forward,
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignupScreen()),
            );
          },
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              children: [
                const TextSpan(text: "Don't have an account? "),
                TextSpan(
                  text: 'Signup here',
                  style: const TextStyle(
                    color: Color(0xFF00FF9D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
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
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 12,
          ),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.2),
              letterSpacing: 12,
              fontSize: 28,
            ),
            counterText: '',
            prefixIcon: const Icon(
              Icons.key_outlined,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00FF9D)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(
          onPressed: _isLoading ? null : _verifyOtp,
          isLoading: _isLoading,
          label: 'Verify & Sign In',
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: const Text(
            'Resend Code',
            style: TextStyle(color: Color(0xFF00FF9D), fontSize: 14),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _otpSent = false),
          child: const Text(
            'Use a different email',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final IconData? icon;

  const _PrimaryButton({
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF9D),
              foregroundColor: Colors.black,
              disabledBackgroundColor: const Color(0xFF00FF9D).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ).copyWith(
              overlayColor: MaterialStateProperty.all(
                Colors.black.withOpacity(0.1),
              ),
            ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.black,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}
