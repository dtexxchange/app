import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'screens/auth_screen.dart';
import 'screens/bank_accounts_screen.dart';
import 'screens/deposit_screen.dart';
import 'screens/exchange_passcode_screen.dart';
import 'screens/exchange_screen.dart';
import 'screens/main_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/passcode_screen.dart';
import 'screens/success_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/withdrawal_screen.dart';
import 'screens/tickets_screen.dart';
import 'screens/ticket_detail_screen.dart';
import 'screens/update_warning_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
final ThemeService themeService = ThemeService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [routeObserver],
          title: 'USDT Exchange',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: themeService.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const InitialRouteHandler(),
            '/login': (context) => const AuthScreen(),
            '/home': (context) => const MainScreen(),
            '/bank-accounts': (context) => const BankAccountsScreen(),
            '/history': (context) => const TransactionsScreen(),
            '/passcode': (context) => const PasscodeScreen(),
            '/exchange': (context) => const ExchangeScreen(),
            '/exchange-passcode': (context) => const ExchangePasscodeScreen(),
            '/success': (context) => const SuccessScreen(),
            '/deposit': (context) => const DepositScreen(),
            '/withdraw': (context) => const WithdrawalScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/tickets': (context) => const TicketsScreen(),
            '/ticket-detail': (context) => const TicketDetailScreen(),
          },
        );
      },
    );
  }
}

class InitialRouteHandler extends StatefulWidget {
  const InitialRouteHandler({super.key});

  @override
  State<InitialRouteHandler> createState() => _InitialRouteHandlerState();
}

class _InitialRouteHandlerState extends State<InitialRouteHandler> {
  bool _isLoading = true;
  bool _needsUpdate = false;
  String _latestVersion = '';
  String? _token;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Check App Version
      final latestRelease = await ApiService().getLatestVersion();
      if (latestRelease != null && latestRelease['version'] != null) {
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        final latestVersion = latestRelease['version'] as String;

        // Simple comparison: if versions don't match, require update
        if (currentVersion != latestVersion) {
          setState(() {
            _needsUpdate = true;
            _latestVersion = latestVersion;
            _isLoading = false;
          });
          return;
        }
      }

      // 2. Check Auth Token
      _token = await ApiService().getToken();
    } catch (e) {
      debugPrint('Initialization error: $e');
    } finally {
      if (mounted && !_needsUpdate) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_needsUpdate) {
      return UpdateWarningScreen(latestVersion: _latestVersion);
    }

    if (_token != null) {
      return const MainScreen();
    }

    return const AuthScreen();
  }
}
