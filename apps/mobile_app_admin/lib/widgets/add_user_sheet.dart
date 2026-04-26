import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddUserSheet extends StatefulWidget {
  final Future<void> Function(String email, String role) onAddUser;

  const AddUserSheet({super.key, required this.onAddUser});

  @override
  State<AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends State<AddUserSheet> {
  final _emailCtrl = TextEditingController();
  String _role = 'USER';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final textDim = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
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
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Register User',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a new email to the access whitelist.',
            style: TextStyle(color: textDim, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'user@example.com',
              hintStyle: TextStyle(color: textDim),
              prefixIcon: Icon(Icons.mail_outline, color: textDim, size: 20),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.03),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Role selector
          Row(
            children: [
              _RoleChip(
                label: 'User',
                selected: _role == 'USER',
                onTap: () => setState(() => _role = 'USER'),
              ),
              const SizedBox(width: 12),
              _RoleChip(
                label: 'Admin',
                selected: _role == 'ADMIN',
                onTap: () => setState(() => _role = 'ADMIN'),
                color: primary,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Whitelist',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_emailCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onAddUser(_emailCtrl.text, _role);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Error handled by parent
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = const Color(0x00000001),
  });

  @override
  Widget build(BuildContext context) {
    final textDim = Theme.of(context).colorScheme.onSurfaceVariant;
    final border = Theme.of(context).dividerColor;
    final roleColor = color == const Color(0x00000001) ? textDim : color;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? roleColor.withValues(alpha: 0.15)
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? roleColor.withValues(alpha: 0.40) : border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? roleColor : textDim,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
