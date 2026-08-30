import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AdminTicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const AdminTicketDetailScreen({super.key, required this.ticketId});

  @override
  State<AdminTicketDetailScreen> createState() =>
      _AdminTicketDetailScreenState();
}

class _AdminTicketDetailScreenState extends State<AdminTicketDetailScreen> {
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard => Theme.of(context).cardColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).dividerColor;
  static const Color _danger = Color(0xFFF87171);

  final _api = ApiService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Map<String, dynamic>? _ticket;
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isChangingStatus = false;

  int _page = 1;
  bool _hasMore = true;
  bool _isLoadMore = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_scrollListener);
    _fetchTicketDetails();
    _fetchInitialMessages();
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
      final res = await _api.getRequest('/api/tickets/${widget.ticketId}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _ticket = data;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching ticket details: $e');
    }
  }

  Future<void> _fetchInitialMessages() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    _page = 1;
    _hasMore = true;
    try {
      final res = await _api.getRequest('/api/tickets/${widget.ticketId}/messages?page=1&limit=20');
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
      final res = await _api.getRequest('/api/tickets/${widget.ticketId}/messages?page=$nextPage&limit=20');
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
      final res = await _api.postRequest(
        '/api/tickets/${widget.ticketId}/messages',
        {'message': text},
      );

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
              content: Text('Failed to send message: ${res.statusCode}'),
              backgroundColor: _danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: _danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _updateTicketStatus(String status) async {
    setState(() => _isChangingStatus = true);
    try {
      final res = await _api.patchRequest(
        '/api/tickets/${widget.ticketId}/status',
        {'status': status},
      );

      if (res.statusCode == 200) {
        _fetchTicketDetails();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ticket status updated to $status'),
              backgroundColor: status == 'RESOLVED' ? Colors.green : _danger,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update status: ${res.statusCode}'),
              backgroundColor: _danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: _danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final readableId = _ticket?['readableId'] ?? '';
    final status = _ticket?['status'] ?? 'OPEN';
    final user = _ticket?['user'] ?? {};
    final userEmail = user['email'] ?? 'Unknown User';

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ticket #$readableId',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              userEmail,
              style: GoogleFonts.inter(fontSize: 12, color: _textDim),
            ),
          ],
        ),
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
          child: Container(height: 1, color: _border),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : Column(
              children: [
                _buildActionBar(status),
                if (status != 'OPEN') _buildStatusBanner(status),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _fetchTicketDetails();
                      await _fetchInitialMessages();
                    },
                    color: _primary,
                    child: _messages.isEmpty
                        ? const Center(child: Text('No messages yet'))
                        : ListView.builder(
                            controller: _scrollCtrl,
                            reverse: true,
                            padding: const EdgeInsets.all(24),
                            itemCount: _messages.length + (_isLoadMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _messages.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: CircularProgressIndicator(color: _primary),
                                  ),
                                );
                              }
                              final msg = _messages[index];
                              final sender = msg['sender'] ?? {};
                              final isAdminSender = msg['senderId'] != _ticket?['userId'];
                              final senderName = isAdminSender
                                  ? (sender['firstName'] != null
                                        ? '${sender['firstName']} (You)'
                                        : 'You (Admin)')
                                  : (sender['firstName'] != null
                                        ? '${sender['firstName']} (User)'
                                        : 'User');

                              final time = DateTime.parse(msg['createdAt']);

                              return _buildMessageBubble(
                                isAdminSender: isAdminSender,
                                senderName: senderName,
                                text: msg['message'] ?? '',
                                time: time,
                              );
                            },
                          ),
                  ),
                ),
                _buildMessageInput(status),
              ],
            ),
    );
  }

  Widget _buildActionBar(String currentStatus) {
    if (_isChangingStatus) {
      return Container(
        height: 52,
        color: _bgCard,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
          ),
        ),
      );
    }

    return Container(
      color: _bgCard,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Actions:',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: _textDim,
              ),
            ),
          ),
          if (currentStatus == 'OPEN') ...[
            TextButton.icon(
              onPressed: () => _updateTicketStatus('RESOLVED'),
              icon: const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 18,
              ),
              label: const Text(
                'Resolve',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => _updateTicketStatus('UNRESOLVED'),
              icon: const Icon(Icons.cancel_outlined, color: _danger, size: 18),
              label: const Text(
                'Cannot Resolve',
                style: TextStyle(color: _danger, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          if (currentStatus == 'RESOLVED' || currentStatus == 'UNRESOLVED') ...[
            TextButton.icon(
              onPressed: () => _updateTicketStatus('OPEN'),
              icon: Icon(Icons.replay_rounded, color: _primary, size: 18),
              label: Text(
                'Reopen',
                style: TextStyle(color: _primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    final isResolved = status == 'RESOLVED';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isResolved
            ? const Color(0xFFD1FAE5).withValues(alpha: 0.1)
            : const Color(0xFFFEE2E2).withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Icon(
            isResolved
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline,
            color: isResolved ? Colors.green : _danger,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isResolved
                  ? 'This ticket is marked as RESOLVED.'
                  : 'This ticket is marked as CANNOT BE RESOLVED.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isResolved ? Colors.green : _danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required bool isAdminSender,
    required String senderName,
    required String text,
    required DateTime time,
  }) {
    // In the admin app, "You" are admin, so Admin messages align to the right!
    final isRight = isAdminSender;
    final bubbleColor = isRight
        ? _primary
        : (Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF1F5F9));
    final textColor = isRight
        ? Colors.black87
        : (Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87);
    final alignment = isRight
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final margin = isRight
        ? const EdgeInsets.only(left: 48, bottom: 16)
        : const EdgeInsets.only(right: 48, bottom: 16);

    return Align(
      alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
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
                color: _textDim,
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
                  bottomLeft: Radius.circular(isRight ? 16 : 0),
                  bottomRight: Radius.circular(isRight ? 0 : 16),
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
                color: _textDim.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(String status) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: _bgCard,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _bgDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _msgCtrl,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Type reply...',
                  hintStyle: TextStyle(color: _textDim.withValues(alpha: 0.5)),
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
              backgroundColor: _primary,
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
