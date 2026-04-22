import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final double widthScale;
  final VoidCallback? onTap;

  const UserCard({
    super.key,
    required this.user,
    required this.widthScale,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = user['role'] == 'ADMIN';
    final initial =
        (user['firstName']?.toString() ?? user['email']?.toString() ?? '?')
            .substring(0, 1)
            .toUpperCase();
    final joined = DateTime.tryParse(user['createdAt']?.toString() ?? '');

    final _bgCard = Theme.of(context).cardColor;
    final _border = Theme.of(context).dividerColor;
    final _primary = Theme.of(context).primaryColor;
    const _blue = Color(0xFF3B82F6);
    const _danger = Color(0xFFF87171);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10 * widthScale),
        padding: EdgeInsets.all(16 * widthScale),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 44 * widthScale,
              height: 44 * widthScale,
              decoration: BoxDecoration(
                color: (isAdmin ? _primary : _blue).withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: isAdmin ? _primary : _blue,
                    fontSize: 18 * widthScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14 * widthScale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (user['firstName'] != null || user['lastName'] != null)
                        ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                              .trim()
                        : user['email'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14 * widthScale,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4 * widthScale),
                  Wrap(
                    spacing: 8 * widthScale,
                    runSpacing: 4 * widthScale,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7 * widthScale,
                          vertical: 2 * widthScale,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isAdmin
                                      ? _primary
                                      : Theme.of(context).colorScheme.onSurface)
                                  .withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user['role'],
                          style: TextStyle(
                            color: isAdmin
                                ? _primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 9 * widthScale,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (user['status'] != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7 * widthScale,
                            vertical: 2 * widthScale,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (user['status'] == 'APPROVED'
                                        ? _primary
                                        : user['status'] == 'PENDING_APPROVAL'
                                        ? _blue
                                        : _danger)
                                    .withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (user['status'] as String).replaceAll('_', ' '),
                            style: TextStyle(
                              color: user['status'] == 'APPROVED'
                                  ? _primary
                                  : user['status'] == 'PENDING_APPROVAL'
                                  ? _blue
                                  : _danger,
                              fontSize: 9 * widthScale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      if (joined != null)
                        Text(
                          DateFormat('MMM dd, yyyy').format(joined),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 10 * widthScale,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12 * widthScale),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    NumberFormat('#,##0.00').format(user['balance'] ?? 0),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15 * widthScale,
                    ),
                  ),
                ),
                Text(
                  'USDT',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 10 * widthScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
