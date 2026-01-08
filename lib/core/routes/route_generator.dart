
import 'package:flutter/material.dart';
import 'package:artist_hub/core/routes/app_routes.dart';

// Import all screens
import 'package:artist_hub/splash/splash_screen.dart';
import 'package:artist_hub/onboarding/onboarding_screen.dart';
import 'package:artist_hub/auth/role_selection/role_selection_screen.dart';
import 'package:artist_hub/auth/login/login_screen.dart';
import 'package:artist_hub/auth/register/register_screen.dart';

// Artist screens
import 'package:artist_hub/dashboards/artist_dashboard/artist_dashboard_screen.dart';
import 'package:artist_hub/artist/profile/artist_profile_screen.dart';
import 'package:artist_hub/artist/bookings/artist_booking_list_screen.dart';
import 'package:artist_hub/artist/media/upload_media_screen.dart';
import 'package:artist_hub/artist/media/media_gallery_screen.dart';
import 'package:artist_hub/artist/reviews/artist_reviews_screen.dart';

// Customer screens
import 'package:artist_hub/dashboards/customer_dashboard/customer_dashboard_screen.dart';
import 'package:artist_hub/customer/profile/customer_profile_screen.dart';
import 'package:artist_hub/customer/bookings/booking_list_screen.dart';
import 'package:artist_hub/customer/bookings/booking_screen.dart';
import 'package:artist_hub/customer/search/search_artist_screen.dart';
import 'package:artist_hub/customer/reviews/add_review_screen.dart';

import '../../artist/media/media_detail_screen.dart';
import '../../customer/search/artist_detail_screen.dart';
import '../../models/artist_model.dart';
import '../../models/media_model.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
    // ============ AUTH ROUTES ============
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case AppRoutes.roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

    // ============ ARTIST ROUTES ============
      case AppRoutes.artistDashboard:
        return MaterialPageRoute(builder: (_) => const ArtistDashboardScreen());

      case AppRoutes.artistProfile:
        return MaterialPageRoute(builder: (_) => const ArtistProfileScreen());

      case AppRoutes.artistBookings:
        return MaterialPageRoute(builder: (_) => const ArtistBookingListScreen());

      case AppRoutes.uploadMedia:
        return MaterialPageRoute(builder: (_) => const UploadMediaScreen());

      case AppRoutes.mediaGallery:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => MediaGalleryScreen(
              artistId: args['artistId'] as int,
              artistName: args['artistName'] as String,
            ),
          );
        }
        return _errorRoute();
    // Add this new case for artist media detail
      case AppRoutes.artistMediaDetail:
        final args = settings.arguments as Map<String, dynamic>;

        return MaterialPageRoute(
          builder: (_) => ArtistMediaDetailScreen(
            media: args['media'] as MediaModel,
            isOwnMedia: args['isOwnMedia'] ?? false,
          ),
        );

      case AppRoutes.artistReviews:
        return MaterialPageRoute(builder: (_) => const ArtistReviewsScreen());

    // ============ CUSTOMER ROUTES ============
      case AppRoutes.customerDashboard:
        return MaterialPageRoute(builder: (_) => const CustomerDashboardScreen());

      case AppRoutes.customerProfile:
        return MaterialPageRoute(builder: (_) => const CustomerProfileScreen());

      case AppRoutes.searchArtists:
        return MaterialPageRoute(builder: (_) => const SearchArtistScreen());

      case AppRoutes.artistDetail:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => ArtistDetailScreen(
              artistId: args['artistId'] as int,
            ),
          );
        }
        return _errorRoute();
      case AppRoutes.createBooking:
      case AppRoutes.createBooking:
        final args = settings.arguments as Map<String, dynamic>;
        final artistJson = args['artist'];
        ArtistModel artist;

        if (artistJson is Map<String, dynamic>) {
          artist = ArtistModel.fromJson(artistJson);
        } else if (artistJson is ArtistModel) {
          artist = artistJson;
        } else {
          // Try to parse from JSON string or handle error
          artist = ArtistModel.fromJson({});
        }

        return MaterialPageRoute(
          builder: (_) => BookingScreen(artist: artist),
        );
        return _errorRoute();

      case AppRoutes.customerBookings:
        return MaterialPageRoute(builder: (_) => const BookingListScreen());

      case AppRoutes.addReview:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => AddReviewScreen(
              bookingId: args['bookingId'] as int,
              artistId: args['artistId'] as int,
              artistName: args['artistName'] as String,
            ),
          );
        }
        return _errorRoute();

    // ============ DEFAULT/ERROR ROUTE ============
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Route not found!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The requested screen could not be found.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to home based on user role
                  // This would need access to SharedPref
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Navigation helper class
class NavigationHelper {
  // Push to screen
  static Future<dynamic> push(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  // Push and replace
  static Future<dynamic> pushReplacement(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  // Push and remove until
  static Future<dynamic> pushAndRemoveUntil(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
          (route) => false,
      arguments: arguments,
    );
  }

  // Pop
  static void pop(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }

  // Pop until
  static void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }

  // Check if can pop
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }

  // Go back to home based on role
  static void goToHome(BuildContext context, String role) {
    if (role == 'artist') {
      pushAndRemoveUntil(context, AppRoutes.artistDashboard);
    } else if (role == 'customer') {
      pushAndRemoveUntil(context, AppRoutes.customerDashboard);
    } else {
      pushAndRemoveUntil(context, AppRoutes.roleSelection);
    }
  }
}
