import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artist_hub/auth/login/login_screen.dart';
import 'package:artist_hub/splash/splash_screen.dart';
import 'package:artist_hub/auth/register/register_screen.dart';
import 'package:artist_hub/providers/auth_provider.dart';
import 'package:artist_hub/dashboards/customer_dashboard/customer_dashboard_screen.dart';
import 'package:artist_hub/dashboards/artist_dashboard/artist_dashboard_screen.dart';

class ArtistHubApp extends StatelessWidget {
  const ArtistHubApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artist Hub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          foregroundColor: Colors.black,
        ),
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashWrapper(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/customer-dashboard': (context) => const CustomerDashboardScreen(),
        '/artist-dashboard': (context) => const ArtistDashboardScreen(),
      },
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({Key? key}) : super(key: key);

  @override
  _SplashWrapperState createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Simulate splash screen delay
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      if (authProvider.isLoggedIn) {
        if (authProvider.isArtist) {
          Navigator.of(context).pushReplacementNamed('/artist-dashboard');
        } else {
          Navigator.of(context).pushReplacementNamed('/customer-dashboard');
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}