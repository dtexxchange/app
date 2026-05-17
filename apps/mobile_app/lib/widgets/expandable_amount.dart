import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpandableAmount extends StatefulWidget {
  final num amount;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int collapsedDecimals;

  const ExpandableAmount({
    super.key,
    required this.amount,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.collapsedDecimals = 2,
  });

  @override
  State<ExpandableAmount> createState() => _ExpandableAmountState();
}

class _ExpandableAmountState extends State<ExpandableAmount> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    String displayStr;
    if (_expanded) {
      displayStr = NumberFormat('#,##0.########').format(widget.amount);
      if (displayStr.isEmpty) displayStr = '0';
    } else {
      displayStr = NumberFormat('#,##0.${'0' * widget.collapsedDecimals}').format(widget.amount);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _expanded = !_expanded;
        });
      },
      child: Text(
        '${widget.prefix}$displayStr${widget.suffix}',
        style: widget.style,
      ),
    );
  }
}
