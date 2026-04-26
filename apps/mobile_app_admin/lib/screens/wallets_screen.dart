import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _bgCard => Theme.of(context).cardColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _textDim => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _border => Theme.of(context).dividerColor;
  static const Color _blue = Color(0xFF3B82F6);

  final _api = ApiService();
  List<dynamic> _wallets = [];
  bool _isLoading = true;

  // Filter State
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedNetwork = 'All';
  String _selectedStatus = 'All';
  String _selectedTimeRange = 'All Time';

  List<dynamic> get _filteredWallets {
    return _wallets.where((w) {
      if (w == null) return false;
      final name = w['name']?.toString().toLowerCase() ?? '';
      final address = w['address']?.toString().toLowerCase() ?? '';
      final query = (_searchQuery).toLowerCase();
      final matchesSearch =
          query.isEmpty || name.contains(query) || address.contains(query);

      final matchesNetwork =
          _selectedNetwork == 'All' || w['network'] == _selectedNetwork;

      final matchesStatus =
          _selectedStatus == 'All' ||
          (_selectedStatus == 'Active' && w['isActive'] == true) ||
          (_selectedStatus == 'Disabled' && w['isActive'] == false);

      bool matchesTime = true;
      if (_selectedTimeRange != 'All Time' && w['createdAt'] != null) {
        try {
          final createdAt = DateTime.parse(w['createdAt']);
          final now = DateTime.now();
          if (_selectedTimeRange == 'Today') {
            matchesTime =
                createdAt.year == now.year &&
                createdAt.month == now.month &&
                createdAt.day == now.day;
          } else if (_selectedTimeRange == 'Last 7 Days') {
            matchesTime = createdAt.isAfter(
              now.subtract(const Duration(days: 7)),
            );
          } else if (_selectedTimeRange == 'Last 30 Days') {
            matchesTime = createdAt.isAfter(
              now.subtract(const Duration(days: 30)),
            );
          }
        } catch (_) {}
      }

      return matchesSearch && matchesNetwork && matchesStatus && matchesTime;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchWallets();
  }

  Future<void> _fetchWallets() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getRequest('/settings/admin/wallets');
      if (res.statusCode == 200) {
        if (mounted) setState(() => _wallets = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addWallet(String address, String network, String name) async {
    try {
      final res = await _api.postRequest('/settings/admin/wallets', {
        'address': address,
        'network': network,
        'name': name,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        _fetchWallets();
        Navigator.pop(context); // Close modal
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _toggleWallet(String id, bool active) async {
    try {
      await _api.patchRequest('/settings/admin/wallets/$id', {
        'isActive': active,
      });
      _fetchWallets();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _deleteWallet(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        title: Text(
          'Delete Gateway',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this settlement address?',
          style: TextStyle(color: _textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _api.deleteRequest('/settings/admin/wallets/$id');
      _fetchWallets();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 40,
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
                    'Search & Filter',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedNetwork = 'All';
                        _selectedStatus = 'All';
                        _selectedTimeRange = 'All Time';
                      });
                      setLocalState(() {});
                    },
                    child: Text(
                      'Reset',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildFilterLabel('Network'),
              _buildFilterOptions(
                ['All', 'TRC20', 'ERC20', 'BEP20', 'POLYGON'],
                _selectedNetwork,
                (val) {
                  setState(() => _selectedNetwork = val);
                  setLocalState(() {});
                },
              ),
              const SizedBox(height: 24),
              _buildFilterLabel('Status'),
              _buildFilterOptions(
                ['All', 'Active', 'Disabled'],
                _selectedStatus,
                (val) {
                  setState(() => _selectedStatus = val);
                  setLocalState(() {});
                },
              ),
              const SizedBox(height: 24),
              _buildFilterLabel('Time Range'),
              _buildFilterOptions(
                ['All Time', 'Today', 'Last 7 Days', 'Last 30 Days'],
                _selectedTimeRange,
                (val) {
                  setState(() => _selectedTimeRange = val);
                  setLocalState(() {});
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
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
        ),
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
          color: _textDim,
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
              color: isActive ? _primary : _bgDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isActive ? _primary : _border),
            ),
            child: Text(
              opt,
              style: TextStyle(
                color: isActive ? Colors.black : _textDim,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showAddModal() {
    final addressCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String network = 'TRC20';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgCard, _bgDark.withValues(alpha: 0.9)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 40,
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
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'New Gateway',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Configure a new treasury address for user deposits.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _textDim, fontSize: 13),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Label / Name (Private)',
                  labelStyle: TextStyle(color: _textDim, fontSize: 13),
                  hintText: 'e.g. Finance Hub 1',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  filled: true,
                  fillColor: _bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressCtrl,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: 'USDT Wallet Address',
                  labelStyle: TextStyle(color: _textDim, fontSize: 13),
                  hintText: 'TX...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  filled: true,
                  fillColor: _bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: network,
                dropdownColor: _bgCard,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Blockchain Network',
                  labelStyle: TextStyle(color: _textDim, fontSize: 13),
                  filled: true,
                  fillColor: _bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _primary),
                  ),
                ),
                items: ['TRC20', 'ERC20', 'BEP20', 'POLYGON'].map((n) {
                  return DropdownMenuItem(value: n, child: Text(n));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setLocalState(() => network = val);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (addressCtrl.text.isNotEmpty) {
                    _addWallet(addressCtrl.text, network, nameCtrl.text);
                  }
                },
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
                  'Initialize Gateway',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final widthScale = (size.width / 375.0).clamp(0.85, 1.2);

    return GestureDetector(
      onTap: () {
        if (_isSearching && _searchQuery.isEmpty) {
          setState(() => _isSearching = false);
        }
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: _bgDark,
        body: RefreshIndicator(
          onRefresh: _fetchWallets,
          color: _primary,
          backgroundColor: _bgCard,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: _bgDark.withValues(alpha: 0.95),
                elevation: 0,
                titleSpacing: 0,
                leading: (_isSearching)
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        onPressed: () => setState(() {
                          _isSearching = false;
                          _searchQuery = '';
                        }),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                title: (_isSearching)
                    ? TextField(
                        autofocus: true,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search gateways...',
                          hintStyle: TextStyle(
                            color: _textDim.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                        ),
                      )
                    : Text(
                        'Wallets',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                        ),
                      ),
                actions: [
                  if (!_isSearching)
                    IconButton(
                      icon: Icon(Icons.search, size: 22, color: _textDim),
                      onPressed: () => setState(() => _isSearching = true),
                    ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.more_vert, size: 22, color: _textDim),
                        onPressed: _showFilterSheet,
                      ),
                      if (_searchQuery.isNotEmpty ||
                          _selectedNetwork != 'All' ||
                          _selectedStatus != 'All' ||
                          _selectedTimeRange != 'All Time')
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: _bgDark, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: _border),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  24 * widthScale,
                  20,
                  24 * widthScale,
                  100,
                ),
                sliver: _isLoading
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 100),
                            child: CircularProgressIndicator(color: _primary),
                          ),
                        ),
                      )
                    : _filteredWallets.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 80),
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.05),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No matching gateways found',
                                style: TextStyle(color: _textDim, fontSize: 14),
                              ),
                              if (_searchQuery.isNotEmpty ||
                                  _selectedNetwork != 'All' ||
                                  _selectedStatus != 'All' ||
                                  _selectedTimeRange != 'All Time')
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedNetwork = 'All';
                                      _selectedStatus = 'All';
                                      _selectedTimeRange = 'All Time';
                                    });
                                  },
                                  child: Text(
                                    'Clear all filters',
                                    style: TextStyle(color: _primary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((ctx, i) {
                          final w = _filteredWallets[i];
                          final isActive = w['isActive'] as bool;
                          return _buildWalletCard(w, isActive, widthScale);
                        }, childCount: _filteredWallets.length),
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddModal,
          backgroundColor: _primary,
          elevation: 8,
          label: const Text(
            'NEW GATEWAY',
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          icon: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildWalletCard(dynamic w, bool isActive, double widthScale) {
    return Container(
      margin: EdgeInsets.only(bottom: 20 * widthScale),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isActive ? _border : Colors.redAccent.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive ? _primary : Colors.redAccent).withValues(
              alpha: 0.02,
            ),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(24 * widthScale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8 * widthScale,
                          runSpacing: 8 * widthScale,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * widthScale,
                                vertical: 4 * widthScale,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                w['network'] ?? 'TRC20',
                                style: GoogleFonts.inter(
                                  fontSize: 10 * widthScale,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * widthScale,
                                vertical: 4 * widthScale,
                              ),
                              decoration: BoxDecoration(
                                color: (isActive ? _primary : Colors.redAccent)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isActive ? 'ACTIVE' : 'DISABLED',
                                style: GoogleFonts.inter(
                                  color: isActive ? _primary : Colors.redAccent,
                                  fontSize: 10 * widthScale,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10 * widthScale,
                                  vertical: 4 * widthScale,
                                ),
                                decoration: BoxDecoration(
                                  color: _blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      color: _blue,
                                      size: 10 * widthScale,
                                    ),
                                    SizedBox(width: 4 * widthScale),
                                    Text(
                                      '${w['_count']?['assignments'] ?? 0} USERS',
                                      style: GoogleFonts.inter(
                                        color: _blue,
                                        fontSize: 10 * widthScale,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (w['createdAt'] != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10 * widthScale,
                                  vertical: 4 * widthScale,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: _textDim,
                                      size: 10 * widthScale,
                                    ),
                                    SizedBox(width: 4 * widthScale),
                                    Text(
                                      DateFormat(
                                        'MMM d, hh:mm a',
                                      ).format(DateTime.parse(w['createdAt'])),
                                      style: GoogleFonts.inter(
                                        color: _textDim,
                                        fontSize: 10 * widthScale,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: isActive,
                        activeColor: _primary,
                        activeTrackColor: _primary.withValues(alpha: 0.2),
                        onChanged: (val) => _toggleWallet(w['id'], val),
                      ),
                    ],
                  ),
                  SizedBox(height: 24 * widthScale),
                  if (w['name'] != null && w['name'].toString().isNotEmpty) ...[
                    Text(
                      w['name'].toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: _primary,
                        fontSize: 12 * widthScale,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 6 * widthScale),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          w['address'],
                          style: GoogleFonts.firaCode(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14 * widthScale,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * widthScale),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: w['address']));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Address copied'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.copy,
                          size: 16 * widthScale,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * widthScale,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _deleteWallet(w['id']),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    label: Text(
                      'REMOVE NODE',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10 * widthScale,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
