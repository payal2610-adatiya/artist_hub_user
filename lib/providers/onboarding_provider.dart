// import 'package:flutter/material.dart';
// import 'package:artist_hub/core/services/storage_service.dart';
//
// class OnboardingProvider extends ChangeNotifier {
//   final StorageService _storageService = StorageService();
//
//   Future<void> completeOnboarding(BuildContext context) async {
//     await _storageService.setOnboardingCompleted(true);
//     Navigator.pushReplacementNamed(context, '/role-selection');
//   }
// }