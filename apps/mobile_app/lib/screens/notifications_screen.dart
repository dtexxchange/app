import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await _api.getRequest('/notifications');
      if (response.statusCode == 200) {
        setState(() {
          _notifications = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _api.patchRequest('/notifications/read-all', {});
      _fetchNotifications();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _api.patchRequest('/notifications/$id/read', {});
      _fetchNotifications();
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (_notifications.any((n) => !n['isRead']))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : _notifications.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  color: theme.primaryColor,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final isRead = n['isRead'] as bool;
                      final date = DateTime.parse(n['createdAt']);

                      return GestureDetector(
                        onTap: () {
                          if (!isRead) _markAsRead(n['id']);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRead
                                ? theme.cardColor.withValues(alpha: 0.6)
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRead
                                  ? theme.dividerColor.withValues(alpha: 0.5)
                                  : theme.primaryColor.withValues(alpha: 0.3),
                              width: isRead ? 1 : 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? Colors.grey.withValues(alpha: 0.1)
                                      : theme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getIcon(n['type']),
                                  color: isRead
                                      ? Colors.grey
                                      : theme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n['title'] ?? '',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.w700,
                                              color: isRead
                                                  ? theme.colorScheme.onSurface
                                                      .withValues(alpha: 0.7)
                                                  : theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          DateFormat('hh:mm a').format(date),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      n['body'] ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface
                                            .withValues(
                                                alpha: isRead ? 0.6 : 0.85),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM d, yyyy').format(date),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.grey.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'TRANSACTION_NEW':
        return Icons.add_circle_outline;
      case 'TRANSACTION_STATUS':
        return Icons.swap_horiz;
      case 'QR_ASSIGNMENT':
        return Icons.qr_code;
      default:
        return Icons.notifications_none;
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No new notifications at the moment.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
