import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'transactions_screen.dart';
import 'referral_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // ─── Design Tokens (Dynamic) ──────────────────────────────────────────────────
  Color get _bgDark => Theme.of(context).scaffoldBackgroundColor;
  Color get _primary => Theme.of(context).primaryColor;
  Color get _border => Theme.of(context).dividerColor;

  int _currentIndex = 0;

  final _homeKey = GlobalKey<HomeScreenState>();
  final _txKey = GlobalKey<TransactionsScreenState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(
        key: _homeKey,
        // Switches to the History tab instead of pushing a new route.
        onViewHistory: () => _onTabSelected(1),
      ),
      TransactionsScreen(key: _txKey),
      const ReferralScreen(),
      const ProfileScreen(),
    ];
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) {
      // Re-tapping the active tab refreshes it.
      _refreshTab(index);
    } else {
      setState(() => _currentIndex = index);
      _refreshTab(index);
    }
  }

  void _refreshTab(int index) {
    if (index == 0) _homeKey.currentState?.fetchData();
    if (index == 1) _txKey.currentState?.fetchPage(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _bgDark,
          border: Border(top: BorderSide(color: _border, width: 1)),
        ),
        child: NavigationBar(
          backgroundColor: _bgDark,
          indicatorColor: _primary.withValues(alpha: 0.15),
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            _navDest(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: 'Home',
            ),
            _navDest(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long,
              label: 'History',
            ),
            _navDest(
              icon: Icons.share_outlined,
              activeIcon: Icons.share,
              label: 'Referrals',
            ),
            _navDest(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  NavigationDestination _navDest({
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final theme = Theme.of(context);
    return NavigationDestination(
      icon: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      selectedIcon: Icon(activeIcon, color: _primary),
      label: label,
    );
  }
}
