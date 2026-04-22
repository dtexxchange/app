import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserFilterSheet extends StatefulWidget {
  final String selectedRole;
  final Function(String) onRoleChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;

  const UserFilterSheet({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onReset,
    required this.onApply,
  });

  @override
  State<UserFilterSheet> createState() => _UserFilterSheetState();
}

class _UserFilterSheetState extends State<UserFilterSheet> {
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.selectedRole;
  }

  @override
  Widget build(BuildContext context) {
    final _bgCard = Theme.of(context).cardColor;
    final _primary = Theme.of(context).primaryColor;
    final _textDim = Theme.of(context).colorScheme.onSurfaceVariant;
    final _border = Theme.of(context).dividerColor;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 40,
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
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Filters',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.onReset();
                  setState(() {
                    _selectedRole = 'All';
                  });
                },
                child: const Text(
                  'Reset',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFilterLabel('System Role'),
          _buildFilterOptions(
            ['All', 'USER', 'ADMIN'],
            _selectedRole,
            (val) {
              setState(() => _selectedRole = val);
              widget.onRoleChanged(val);
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: widget.onApply,
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
              'Apply Filters',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildFilterOptions(
    List<String> options,
    String current,
    Function(String) onSelected,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isActive = opt == current;
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isActive ? Theme.of(context).primaryColor : Theme.of(context).dividerColor),
            ),
            child: Text(
              opt,
              style: TextStyle(
                color: isActive ? Colors.black : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
