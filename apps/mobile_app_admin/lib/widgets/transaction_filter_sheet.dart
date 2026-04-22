import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionFilterSheet extends StatefulWidget {
  final String selectedType;
  final String selectedStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortBy;
  final Function(String) onTypeChanged;
  final Function(String) onStatusChanged;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final Function(String) onSortChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;

  const TransactionFilterSheet({
    super.key,
    required this.selectedType,
    required this.selectedStatus,
    this.startDate,
    this.endDate,
    this.sortBy = 'date',
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onSortChanged,
    required this.onReset,
    required this.onApply,
  });

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late String _selectedType;
  late String _selectedStatus;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _selectedStatus = widget.selectedStatus;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _sortBy = widget.sortBy;
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
                'Transaction Filters',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.onReset();
                  setState(() {
                    _selectedType = 'All';
                    _selectedStatus = 'All';
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
          _buildFilterLabel('Transaction Type'),
          _buildFilterOptions(
            ['All', 'DEPOSIT', 'EXCHANGE', 'REFERRAL'],
            _selectedType,
            (val) {
              setState(() => _selectedType = val);
              widget.onTypeChanged(val);
            },
          ),
          const SizedBox(height: 24),
          _buildFilterLabel('Status'),
          _buildFilterOptions(
            ['All', 'PENDING', 'COMPLETED', 'REJECTED'],
            _selectedStatus,
            (val) {
              setState(() => _selectedStatus = val);
              widget.onStatusChanged(val);
            },
          ),
          const SizedBox(height: 24),
          _buildFilterLabel('Date Range'),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  'Start Date',
                  _startDate,
                  (date) {
                    setState(() => _startDate = date);
                    widget.onStartDateChanged(date);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  'End Date',
                  _endDate,
                  (date) {
                    setState(() => _endDate = date);
                    widget.onEndDateChanged(date);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFilterLabel('Sort By'),
          _buildFilterOptions(
            ['Date', 'Amount', 'Type', 'Status'],
            _sortBy,
            (val) {
              setState(() => _sortBy = val);
              widget.onSortChanged(val);
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

  Widget _buildDateField(String label, DateTime? date, Function(DateTime?) onChanged) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Select date',
              style: TextStyle(
                color: date != null
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
