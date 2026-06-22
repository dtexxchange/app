import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  Map<String, dynamic>? _ticket;
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _ticketId;

  int _page = 1;
  bool _hasMore = true;
  bool _isLoadMore = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_scrollListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ticketId == null) {
      _ticketId = ModalRoute.of(context)!.settings.arguments as String;
      _fetchTicketDetails();
      _fetchInitialMessages();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_scrollListener);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoadMore && !_isLoading) {
        _fetchMoreMessages();
      }
    }
  }

  Future<void> _fetchTicketDetails() async {
    try {
      final res = await _api.getRequest('/tickets/$_ticketId');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _ticket = data;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading ticket details: $e');
    }
  }

  Future<void> _fetchInitialMessages() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    _page = 1;
    _hasMore = true;
    try {
      final res = await _api.getRequest('/tickets/$_ticketId/messages?page=1&limit=20');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _messages = data;
            _isLoading = false;
            if (data.length < 20) {
              _hasMore = false;
            }
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading initial messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMoreMessages() async {
    if (!mounted) return;
    setState(() => _isLoadMore = true);
    final nextPage = _page + 1;
    try {
      final res = await _api.getRequest('/tickets/$_ticketId/messages?page=$nextPage&limit=20');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _page = nextPage;
            _messages.addAll(data);
            _isLoadMore = false;
            if (data.length < 20) {
              _hasMore = false;
            }
          });
        }
      } else {
        if (mounted) setState(() => _isLoadMore = false);
      }
    } catch (e) {
      debugPrint('Error loading more messages: $e');
      if (mounted) setState(() => _isLoadMore = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _msgCtrl.clear();

    try {
      final res = await _api.postRequest('/tickets/$_ticketId/messages', {
        'message': text,
      });

      if (res.statusCode == 201) {
        final newMsg = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _messages.insert(0, newMsg);
          });
        }
        _fetchTicketDetails();
        _scrollToBottom();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send reply: ${res.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subject = _ticket?['subject'] ?? 'Ticket';
    final readableId = _ticket?['readableId'] ?? '';
    final status = _ticket?['status'] ?? 'OPEN';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'Ticket #$readableId',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchTicketDetails();
              _fetchInitialMessages();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: theme.dividerColor),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : Column(
              children: [
                if (status != 'OPEN') _buildStatusBanner(status),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _fetchTicketDetails();
                      await _fetchInitialMessages();
                    },
                    color: theme.primaryColor,
                    child: _messages.isEmpty
                        ? const Center(child: Text('No messages yet'))
                        : ListView.builder(
                            controller: _scrollCtrl,
                            reverse: true,
                            padding: const EdgeInsets.all(20),
                            itemCount: _messages.length + (_isLoadMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _messages.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: CircularProgressIndicator(color: theme.primaryColor),
                                  ),
                                );
                              }
                              final msg = _messages[index];
                              final sender = msg['sender'] ?? {};
                              final isUser = msg['senderId'] == _ticket?['userId'];
                              final senderName = isUser
                                  ? 'You'
                                  : (sender['firstName'] != null
                                      ? '${sender['firstName']} (Support)'
                                      : 'Support Agent');
                              final time = DateTime.parse(msg['createdAt']);

                              return _buildMessageBubble(
                                isUser: isUser,
                                senderName: senderName,
                                text: msg['message'] ?? '',
                                time: time,
                                theme: theme,
                              );
                            },
                          ),
                  ),
                ),
                _buildMessageInput(theme, status),
              ],
            ),
    );
  }

  Widget _buildStatusBanner(String status) {
    final theme = Theme.of(context);
    final isResolved = status == 'RESOLVED';

    return Container(
      width: double.infinity,
      color: isResolved
          ? const Color(0xFFD1FAE5).withValues(alpha: 0.8)
          : const Color(0xFFFEE2E2).withValues(alpha: 0.8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(
            isResolved ? Icons.check_circle_outline_rounded : Icons.info_outline,
            color: isResolved ? const Color(0xFF047857) : const Color(0xFFB91C1C),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isResolved
                  ? 'This ticket is marked as Resolved. Reply below to reopen.'
                  : 'This ticket is marked as Cannot Resolve. Reply below to reopen.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isResolved ? const Color(0xFF065F46) : const Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required bool isUser,
    required String senderName,
    required String text,
    required DateTime time,
    required ThemeData theme,
  }) {
    final bubbleColor = isUser
        ? theme.primaryColor
        : (theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final textColor = isUser
        ? Colors.white
        : (theme.brightness == Brightness.dark ? Colors.white : Colors.black87);
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final margin = isUser ? const EdgeInsets.only(left: 40, bottom: 16) : const EdgeInsets.only(right: 40, bottom: 16);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: margin,
        child: Column(
          crossAxisAlignment: alignment,
          children: [
            Text(
              senderName,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 16),
                ),
              ),
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(time),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme, String status) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _msgCtrl,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: theme.primaryColor,
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
