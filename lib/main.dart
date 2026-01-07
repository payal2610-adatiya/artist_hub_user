import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/shared_pref.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPref.init();

  final userData = SharedPref.getUserData();
  if (userData != null && userData['role'] == 'artist') {
    if (userData['is_approved'] != true) {
      await SharedPref.clearUserData();
    }
  }
  runApp(const App());
}
