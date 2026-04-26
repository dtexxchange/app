import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'user_card.dart';

class UsersTab extends StatefulWidget {
  final List<dynamic> users;
  final String searchQuery;
  final String selectedRole;
  final Function(String) onSearchChanged;
  final Function(String) onRoleChanged;
  final VoidCallback onShowFilterSheet;
  final VoidCallback onShowAddUserSheet;
  final Function(dynamic) onUserTap;

  const UsersTab({
    super.key,
    required this.users,
    required this.searchQuery,
    required this.selectedRole,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.onShowFilterSheet,
    required this.onShowAddUserSheet,
    required this.onUserTap,
  });

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  List<dynamic> get _filteredUsers {
    if (widget.selectedRole == 'All') return widget.users;
    return widget.users.where((u) => u['role'] == widget.selectedRole).toList();
  }

  @override
  Widget build(BuildContext context) {
    final widthScale = (MediaQuery.of(context).size.width / 375.0).clamp(
      0.85,
      1.2,
    );
    final filtered = _filteredUsers;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // Header + Add button
        Row(
          children: [
            Expanded(
              child: Text(
                'User Directory',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: widget.onShowAddUserSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.black, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      'Whitelist',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (filtered.isEmpty)
          Column(
            children: [
              const SizedBox(height: 80),
              Icon(
                widget.searchQuery.isNotEmpty || widget.selectedRole != 'All'
                    ? Icons.search_off_rounded
                    : Icons.people_outline,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.05),
              ),
              const SizedBox(height: 16),
              Text(
                widget.searchQuery.isNotEmpty || widget.selectedRole != 'All'
                    ? 'No matching users found'
                    : 'No users in directory',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              if (widget.searchQuery.isNotEmpty || widget.selectedRole != 'All')
                TextButton(
                  onPressed: () {
                    widget.onSearchChanged('');
                    widget.onRoleChanged('All');
                  },
                  child: Text(
                    'Clear all filters',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
            ],
          )
        else
          ...filtered.map(
            (u) => UserCard(
              user: u,
              widthScale: widthScale,
              onTap: () => widget.onUserTap(u),
            ),
          ),
      ],
    );
  }
}
