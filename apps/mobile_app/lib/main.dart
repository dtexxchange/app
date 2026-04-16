import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'USDT Exchange',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00FF9D),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF9D),
          secondary: Color(0xFF3B82F6),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const InitialRouteHandler(),
        '/login': (context) => const AuthScreen(),
        '/home': (context) => const MainScreen(),
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        }
        return const AuthScreen();
      },
    );
  }
}
