import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ExchangeTab extends StatelessWidget {
  final double? conversionRate;
  final List<dynamic> rateHistory;
  final TextEditingController rateController;
  final VoidCallback onSaveRate;

  const ExchangeTab({
    super.key,
    this.conversionRate,
    required this.rateHistory,
    required this.rateController,
    required this.onSaveRate,
  });

  @override
  Widget build(BuildContext context) {
    final bgCard = Theme.of(context).cardColor;
    final bgDark = Theme.of(context).scaffoldBackgroundColor;
    final border = Theme.of(context).dividerColor;
    final textDim = Theme.of(context).colorScheme.onSurfaceVariant;
    final blue = const Color(0xFF3B82F6);
    final danger = const Color(0xFFF87171);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'EXCHANGE CONFIGURATION',
          style: GoogleFonts.inter(
            color: textDim,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.currency_exchange, color: blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conversion Rate',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '1 USDT = X INR',
                          style: TextStyle(color: textDim, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (conversionRate == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'LOCK ACTIVE',
                        style: TextStyle(
                          color: danger,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: rateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Current USDT/INR Rate',
                  labelStyle: TextStyle(color: textDim, fontSize: 12),
                  hintText: 'e.g. 88.5',
                  filled: true,
                  fillColor: bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: border),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSaveRate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Rate & Unlock',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (rateHistory.isNotEmpty) ...[
                const SizedBox(height: 24),
                Divider(color: border),
                const SizedBox(height: 16),
                Text(
                  'RECENT CHANGES',
                  style: TextStyle(
                    color: textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ...rateHistory
                    .take(10)
                    .map(
                      (h) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${(h['rate'] as num).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'MMM dd, hh:mm a',
                              ).format(DateTime.parse(h['createdAt'])),
                              style: TextStyle(color: textDim, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
