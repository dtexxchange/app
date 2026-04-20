import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveTimerWidget extends StatefulWidget {
  final DateTime expiresAt;
  final VoidCallback onExpired;
  const LiveTimerWidget({
    super.key,
    required this.expiresAt,
    required this.onExpired,
  });

  @override
  State<LiveTimerWidget> createState() => _LiveTimerWidgetState();
}

class _LiveTimerWidgetState extends State<LiveTimerWidget> {
  Timer? _timer;
  late int _timeLeft;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _startTimer();
  }

  @override
  void didUpdateWidget(LiveTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _calculateTimeLeft();
    }
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    _timeLeft = widget.expiresAt.difference(now).inSeconds;
    if (_timeLeft < 0) _timeLeft = 0;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTimeLeft();
          if (_timeLeft <= 0) {
            _timer?.cancel();
            widget.onExpired();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _timerColor() {
    if (_timeLeft < 60) return Colors.redAccent;
    if (_timeLeft < 300) return Colors.orangeAccent;
    return const Color(0xFF00FF9D);
  }

  @override
  Widget build(BuildContext context) {
    final color = _timerColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            'REFRESHING IN: ${_formatTime(_timeLeft)}',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
