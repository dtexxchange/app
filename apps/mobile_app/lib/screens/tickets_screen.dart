import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _tickets = [];
  List<dynamic> _contacts = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchTickets();
    _fetchSupportContacts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoadMore && !_isLoading) {
        _fetchMoreTickets();
      }
    }
  }

  Future<void> _fetchTickets({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }
    _page = 1;
    _hasMore = true;
    try {
      final response = await _api.getRequest('/tickets?page=1&limit=10');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _tickets = data;
            _isLoading = false;
            if (data.length < 10) {
              _hasMore = false;
            }
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMoreTickets() async {
    if (!mounted) return;
    setState(() => _isLoadMore = true);
    final nextPage = _page + 1;
    try {
      final response = await _api.getRequest('/tickets?page=$nextPage&limit=10');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _page = nextPage;
            _tickets.addAll(data);
            _isLoadMore = false;
            if (data.length < 10) {
              _hasMore = false;
            }
          });
        }
      } else {
        if (mounted) setState(() => _isLoadMore = false);
      }
    } catch (e) {
      debugPrint('Error fetching more tickets: $e');
      if (mounted) setState(() => _isLoadMore = false);
    }
  }

  Future<void> _fetchSupportContacts() async {
    try {
      final res = await _api.getRequest('/settings/support-contacts');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _contacts = data is List ? data : [];
          });
        }
      }
    } catch (_) {}
  }

  void _launchUrl(String url, String platform) async {
    String formattedUrl = url.trim();
    if (platform == 'WHATSAPP') {
      if (!formattedUrl.startsWith('http')) {
        String phone = formattedUrl.replaceAll(RegExp(r'[^\d+]'), '');
        if (phone.startsWith('+')) phone = phone.substring(1);
        formattedUrl = 'https://wa.me/$phone';
      }
    } else if (platform == 'TELEGRAM') {
      if (formattedUrl.startsWith('@')) {
        formattedUrl = 'https://t.me/${formattedUrl.substring(1)}';
      } else if (!formattedUrl.startsWith('http') && !formattedUrl.startsWith('mailto:')) {
        formattedUrl = 'https://t.me/$formattedUrl';
      }
    } else {
      if (!formattedUrl.startsWith('http') && !formattedUrl.startsWith('mailto:')) {
        formattedUrl = 'https://$formattedUrl';
      }
    }

    final uri = Uri.parse(formattedUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch contact URL: $formattedUrl'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching link: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCreateTicketSheet() {
    final theme = Theme.of(context);
    final subjectCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Raise Support Ticket',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please describe your issue below. Our support team will get back to you shortly.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'SUBJECT',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: subjectCtrl,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'e.g. Withdrawal issue, KYC Verification',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Subject is required' : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'DESCRIPTION & DETAILS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descriptionCtrl,
                      maxLines: 4,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Describe your issue in detail here...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please provide description details'
                          : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => isSubmitting = true);

                              try {
                                final res = await _api.postRequest('/tickets', {
                                  'subject': subjectCtrl.text.trim(),
                                  'description': descriptionCtrl.text.trim(),
                                });

                                if (res.statusCode == 201) {
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ticket created successfully'),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                  _fetchTickets();
                                } else {
                                  setSheetState(() => isSubmitting = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to create ticket: ${res.statusCode}',
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                setSheetState(() => isSubmitting = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error creating ticket: $e'),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit Ticket',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Support & Help',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: theme.dividerColor),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : Column(
              children: [
                _buildDirectSupportSection(),
                Expanded(
                  child: _tickets.isEmpty
                      ? _buildEmptyState(theme)
                      : RefreshIndicator(
                          onRefresh: () => _fetchTickets(showLoading: false),
                          color: theme.primaryColor,
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                            itemCount: _tickets.length + (_isLoadMore ? 1 : 0),
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              if (index == _tickets.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: CircularProgressIndicator(color: theme.primaryColor),
                                  ),
                                );
                              }
                              final ticket = _tickets[index];
                              final readableId = ticket['readableId'] ?? '';
                              final subject = ticket['subject'] ?? '';
                              final status = ticket['status'] ?? 'OPEN';
                              final date = DateTime.parse(ticket['updatedAt'] ?? ticket['createdAt']);

                              return InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/ticket-detail',
                                    arguments: ticket['id'],
                                  ).then((_) {
                                    _fetchTickets();
                                    _fetchSupportContacts();
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: theme.dividerColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Ticket #$readableId',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          _buildStatusBadge(status),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        subject,
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                size: 14,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                DateFormat('MMM d, hh:mm a').format(date),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 14,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTicketSheet,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('New Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDirectSupportSection() {
    final validContacts = _contacts.where((c) {
      final String url = c['url'] ?? '';
      return url.trim().isNotEmpty;
    }).toList();

    if (validContacts.isEmpty) return const SizedBox();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.headset_mic_outlined, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Direct Support Channels',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: validContacts.map((contact) {
                final String title = contact['title'] ?? 'Support';
                final String platform = contact['platform'] ?? 'LINK';
                final String url = contact['url'] ?? '';

                IconData icon;
                Color color;

                if (platform == 'TELEGRAM') {
                  icon = Icons.telegram;
                  color = const Color(0xFF0088cc);
                } else if (platform == 'WHATSAPP') {
                  icon = Icons.phone_iphone_rounded;
                  color = const Color(0xFF25D366);
                } else {
                  icon = Icons.link_rounded;
                  color = theme.primaryColor;
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildSocialButton(
                    label: title,
                    icon: icon,
                    color: color,
                    url: url,
                    platform: platform,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color color,
    required String url,
    required String platform,
  }) {
    return InkWell(
      onTap: () => _launchUrl(url, platform),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'OPEN':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF3B82F6);
        break;
      case 'RESOLVED':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF10B981);
        break;
      case 'UNRESOLVED':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFEF4444);
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.1);
        fg = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status == 'UNRESOLVED' ? 'CANNOT RESOLVE' : status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent_rounded,
                size: 40,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Support Tickets Yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'If you face any issues, tap the button below to raise a support ticket. Our team is here to assist you.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
