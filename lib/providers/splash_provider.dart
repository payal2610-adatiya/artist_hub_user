// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:artist_hub/core/services/auth_service.dart';
// import 'package:artist_hub/core/services/storage_service.dart';
//
// class SplashProvider extends ChangeNotifier {
//   final AuthService _authService = AuthService();
//   final StorageService _storageService = StorageService();
//
//   Future<void> initializeApp(BuildContext context) async {
//     await Future.delayed(const Duration(seconds: 2));
//
//     final isOnboardingCompleted = await _storageService.isOnboardingCompleted();
//     final isLoggedIn = await _authService.isLoggedIn();
//
//     if (!isOnboardingCompleted) {
//       Navigator.pushReplacementNamed(context, '/onboarding');
//     } else if (!isLoggedIn) {
//       Navigator.pushReplacementNamed(context, '/role-selection');
//     } else {
//       final user = await _authService.getCurrentUser();
//       if (user?.role == 'artist') {
//         Navigator.pushReplacementNamed(context, '/artist-dashboard');
//       } else {
//         Navigator.pushReplacementNamed(context, '/customer-dashboard');
//       }
//     }
//   }
// }