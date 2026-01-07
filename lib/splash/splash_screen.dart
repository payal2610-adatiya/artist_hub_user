import 'package:flutter/material.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/constants/app_strings.dart';
import 'package:artist_hub/core/routes/app_routes.dart';
import 'package:artist_hub/core/services/shared_pref.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await SharedPref.init();

    print('SplashScreen: Checking user status...');

    // Check for logged in users first
    if (SharedPref.isLoggedIn()) {
      final userRole = SharedPref.getUserRole();
      print('SplashScreen: User is logged in as $userRole');

      if (userRole == 'artist') {
        final isApproved = SharedPref.isArtistApproved();
        print('SplashScreen: Artist approval status: $isApproved');

        if (!isApproved) {
          print('SplashScreen: Artist not approved, clearing data...');
          await SharedPref.clearUserData();
        }
      }
    }

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final isOnboardingCompleted = SharedPref.isOnboardingCompleted();
    final isLoggedIn = SharedPref.isLoggedIn();

    print('SplashScreen: Onboarding completed: $isOnboardingCompleted');
    print('SplashScreen: Logged in: $isLoggedIn');

    if (!isOnboardingCompleted) {
      print('SplashScreen: Navigating to onboarding');
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    } else if (!isLoggedIn) {
      print('SplashScreen: Navigating to role selection');
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
    } else {
      final userRole = SharedPref.getUserRole();
      print('SplashScreen: User role: $userRole');

      if (userRole == 'artist') {
        // Double check approval before navigating to dashboard
        if (SharedPref.isArtistApproved()) {
          print('SplashScreen: Artist approved, navigating to dashboard');
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.artistDashboard,
                (route) => false,
          );
        } else {
          print('SplashScreen: Artist not approved, navigating to role selection');
          Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
        }
      } else {
        print('SplashScreen: Customer, navigating to dashboard');
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.customerDashboard,
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.brush,
                size: 60,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.tagline,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}