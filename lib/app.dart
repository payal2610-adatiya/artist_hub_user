import 'package:flutter/material.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/services/connectivity_service.dart';
import 'package:artist_hub/splash/splash_screen.dart';
import 'package:artist_hub/core/routes/app_routes.dart';
import 'package:artist_hub/core/routes/route_generator.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _connectivityService.init();
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _connectivityService.connectionStream,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Artist Hub',
          theme: ThemeData(
            primaryColor: AppColors.primaryColor,
            scaffoldBackgroundColor: AppColors.backgroundColor,
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
            ),
            fontFamily: 'Inter',
            textTheme: const TextTheme(
              headlineMedium: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
              titleMedium: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textColor,
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textColor,
              ),
            ),
          ),
          initialRoute: AppRoutes.splash,
          onGenerateRoute: RouteGenerator.generateRoute,
          home: isConnected
              ? const SplashScreen()
              : _buildNoInternetScreen(),
        );
      },
    );
  }

  Widget _buildNoInternetScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 80, color: AppColors.grey),
              const SizedBox(height: 24),
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.darkGrey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  final isConnected =
                  await _connectivityService.checkConnection();
                  if (isConnected && mounted) {
                    Navigator.pushReplacementNamed(
                        context, AppRoutes.splash);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
