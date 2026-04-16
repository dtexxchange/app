import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'transactions_screen.dart';
import 'profile_screen.dart';

const _bgDark = Color(0xFF0A0B0D);
const _primary = Color(0xFF00FF9D);
const _border = Color(0x0DFFFFFF);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    TransactionsScreen(),
    ProfileScreen(),
  ];

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
          indicatorColor: _primary.withOpacity(0.15),
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
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
    return NavigationDestination(
      icon: Icon(icon, color: Colors.white.withOpacity(0.45)),
      selectedIcon: Icon(activeIcon, color: _primary),
      label: label,
    );
  }
}
