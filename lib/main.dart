import 'package:flutter/material.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'landing.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SaturnX Apps',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'ShareTechMono',
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark().copyWith(
          secondary: Colors.pink,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => LandingPage());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/dashboard':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => DashboardPage(
                username: args['username'],
                password: args['password'],
                role: args['role'],
                sessionKey: args['key'],
                expiredDate: args['expiredDate'],
                listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []), // ✅ aman
                listDoos: List<Map<String, dynamic>>.from(args['listDoos'] ?? []), // ✅ aman
                news: List<Map<String, dynamic>>.from(args['news'] ?? []), // ✅ aman
              ),
            );

          case '/home':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => HomePage(
                username: args['username'],
                password: args['password'],
                listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []), // ✅ aman
                role: args['role'],
                expiredDate: args['expiredDate'],
                sessionKey: args['sessionKey'],
              ),
            );

          case '/seller':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => SellerPage(
                keyToken: args['keyToken'],
              ),
            );

          case '/admin':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => AdminPage(
                sessionKey: args['sessionKey'],
              ),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text("404 - Not Found")),
              ),
            );
        }
      },
    );
  }
}
