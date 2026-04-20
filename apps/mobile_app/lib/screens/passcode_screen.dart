import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

enum PasscodeFlowStep { enterOld, enterNew, confirmNew }

class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({super.key});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  static const Color _danger = Color(0xFFF87171);

  final List<String> _currentInput = [];
  String? _oldPasscode;
  String? _newPasscode;
  bool _isLoading = true;
  bool _userHasPasscode = false;
  PasscodeFlowStep _currentStep = PasscodeFlowStep.enterNew;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      final res = await _api.getRequest('/users/me');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _userHasPasscode = data['passcode'] != null;
          _currentStep = _userHasPasscode
              ? PasscodeFlowStep.enterOld
              : PasscodeFlowStep.enterNew;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() => _isLoading = false);
    }
  }

  void _onNumberTap(String number) {
    if (_currentInput.length < 6) {
      setState(() {
        _currentInput.add(number);
      });
      if (_currentInput.length == 6) {
        _handleStepCompletion();
      }
    }
  }

  void _onBackspace() {
    if (_currentInput.isNotEmpty) {
      setState(() {
        _currentInput.removeLast();
      });
    }
  }

  Future<void> _handleStepCompletion() async {
    final input = _currentInput.join();

    if (_currentStep == PasscodeFlowStep.enterOld) {
      // Verify old passcode
      setState(() => _isLoading = true);
      try {
        final res = await _api.postRequest('/users/me/passcode/verify', {
          'passcode': input,
        });
        final data = jsonDecode(res.body);
        if (data['isValid'] == true) {
          setState(() {
            _oldPasscode = input;
            _currentStep = PasscodeFlowStep.enterNew;
            _currentInput.clear();
            _isLoading = false;
          });
        } else {
          _showError('Incorrect current passcode');
        }
      } catch (e) {
        _showError('Network error');
      } finally {
        setState(() => _isLoading = false);
      }
    } else if (_currentStep == PasscodeFlowStep.enterNew) {
      if (_userHasPasscode && input == _oldPasscode) {
        _showError('New passcode cannot be same as old');
        return;
      }
      setState(() {
        _newPasscode = input;
        _currentStep = PasscodeFlowStep.confirmNew;
        _currentInput.clear();
      });
    } else if (_currentStep == PasscodeFlowStep.confirmNew) {
      if (input == _newPasscode) {
        _submitFinal();
      } else {
        _showError('Passcodes do not match');
        setState(() {
          _currentStep = PasscodeFlowStep.enterNew;
          _newPasscode = null;
        });
      }
    }
  }

  Future<void> _submitFinal() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.patchRequest('/users/me/passcode', {
        'passcode': _newPasscode,
        if (_oldPasscode != null) 'oldPasscode': _oldPasscode,
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passcode saved successfully')),
          );
          Navigator.pop(context, true);
        }
      } else {
        final error =
            jsonDecode(res.body)['message'] ?? 'Failed to update passcode';
        _showError(error);
      }
    } catch (e) {
      _showError('Network error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: _danger),
      );
      setState(() {
        _currentInput.clear();
      });
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case PasscodeFlowStep.enterOld:
        return 'Enter Current Passcode';
      case PasscodeFlowStep.enterNew:
        return _userHasPasscode ? 'Enter New Passcode' : 'Set 6-Digit Passcode';
      case PasscodeFlowStep.confirmNew:
        return 'Confirm New Passcode';
    }
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case PasscodeFlowStep.enterOld:
        return 'Verify your identity to change passcode';
      case PasscodeFlowStep.enterNew:
        return 'Choose a strong 6-digit pin';
      case PasscodeFlowStep.confirmNew:
        return 'Enter the new passcode again to confirm';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final widthScale = (size.width / 375.0).clamp(0.85, 1.2);
    final heightScale = (size.height / 812.0).clamp(0.8, 1.1);
    final isShort = size.height < 700;

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Security Passcode',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold, 
            fontSize: 18 * widthScale,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _primary))
            : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24 * widthScale),
                  child: Column(
                    children: [
                      SizedBox(height: (isShort ? 30 : 60) * heightScale),
                      Text(
                        _getStepTitle(),
                        style: GoogleFonts.outfit(
                          fontSize: 24 * widthScale,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 12 * heightScale),
                      Text(
                        _getStepDescription(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: _textDim, 
                          fontSize: 14 * widthScale,
                        ),
                      ),
                      SizedBox(height: (isShort ? 40 : 60) * heightScale),
                      _buildPasscodeDots(widthScale),
                      SizedBox(height: (isShort ? 60 : 80) * heightScale),
                      _buildKeyboard(widthScale, heightScale),
                      SizedBox(height: 48 * heightScale),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPasscodeDots(double widthScale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        bool isFilled = index < _currentInput.length;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 10 * widthScale),
          width: 16 * widthScale,
          height: 16 * widthScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? _primary : Colors.transparent,
            border: Border.all(
              color: isFilled ? _primary : _textDim.withOpacity(0.5),
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeyboard(double widthScale, double heightScale) {
    final btnSize = 75.0 * widthScale;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24 * widthScale),
      child: Column(
        children: [
          _buildKeyboardRow(['1', '2', '3'], widthScale),
          SizedBox(height: 20 * heightScale),
          _buildKeyboardRow(['4', '5', '6'], widthScale),
          SizedBox(height: 20 * heightScale),
          _buildKeyboardRow(['7', '8', '9'], widthScale),
          SizedBox(height: 20 * heightScale),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(width: btnSize),
              _buildKeyboardButton('0', widthScale),
              SizedBox(
                width: btnSize,
                height: btnSize,
                child: IconButton(
                  onPressed: _onBackspace,
                  icon: Icon(
                    Icons.backspace_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 24 * widthScale,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> numbers, double widthScale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((n) => _buildKeyboardButton(n, widthScale)).toList(),
    );
  }

  Widget _buildKeyboardButton(String number, double widthScale) {
    final btnSize = 75.0 * widthScale;
    return GestureDetector(
      onTap: () => _onNumberTap(number),
      child: Container(
        width: btnSize,
        height: btnSize,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            number,
            style: GoogleFonts.outfit(
              fontSize: 30 * widthScale,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
