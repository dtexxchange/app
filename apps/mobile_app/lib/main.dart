import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/bank_accounts_screen.dart';
import 'screens/deposit_screen.dart';
import 'screens/exchange_passcode_screen.dart';
import 'screens/exchange_screen.dart';
import 'screens/main_screen.dart';
import 'screens/passcode_screen.dart';
import 'screens/success_screen.dart';
import 'screens/transactions_screen.dart';
import 'services/api_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
final ThemeService themeService = ThemeService();

void main() {
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
          },
        );
      },
    );
  }
}

class InitialRouteHandler extends StatelessWidget {
  const InitialRouteHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ApiService().getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        }
        return const AuthScreen();
      },
    );
  }
}
