import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // User data
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _prefs.setString('user_id', userData['id'].toString());
    await _prefs.setString('user_name', userData['name'] ?? '');
    await _prefs.setString('user_email', userData['email'] ?? '');
    await _prefs.setString('user_phone', userData['phone'] ?? '');
    await _prefs.setString('user_address', userData['address'] ?? '');
    await _prefs.setString('user_role', userData['role'] ?? '');

    // FIXED: Better conversion for is_approved
    final isApproved = userData['is_approved'];
    bool approvedBool = false;

    if (isApproved is bool) {
      approvedBool = isApproved;
    } else if (isApproved is int) {
      approvedBool = isApproved == 1;
    } else if (isApproved is String) {
      approvedBool = isApproved == '1' || isApproved.toLowerCase() == 'true';
    }

    print('Saving is_approved: $isApproved -> $approvedBool');
    await _prefs.setBool('is_approved', approvedBool);
    await _prefs.setBool('is_logged_in', true);
  }

  static Map<String, dynamic> getUserData() {
    return {
      'id': _prefs.getString('user_id') ?? '',
      'name': _prefs.getString('user_name') ?? '',
      'email': _prefs.getString('user_email') ?? '',
      'phone': _prefs.getString('user_phone') ?? '',
      'address': _prefs.getString('user_address') ?? '',
      'role': _prefs.getString('user_role') ?? '',
      'is_approved': _prefs.getBool('is_approved') ?? false,
    };
  }

  static bool isLoggedIn() {
    return _prefs.getBool('is_logged_in') ?? false;
  }

  static String getUserRole() {
    return _prefs.getString('user_role') ?? '';
  }

  static String getUserId() {
    return _prefs.getString('user_id') ?? '';
  }

  static String getUserName() {
    return _prefs.getString('user_name') ?? '';
  }

  static bool isArtistApproved() {
    final approved = _prefs.getBool('is_approved') ?? false;
    print('Checking artist approval: $approved');
    return approved;
  }

  static Future<void> clearUserData() async {
    await _prefs.remove('user_id');
    await _prefs.remove('user_name');
    await _prefs.remove('user_email');
    await _prefs.remove('user_phone');
    await _prefs.remove('user_address');
    await _prefs.remove('user_role');
    await _prefs.remove('is_approved');
    await _prefs.remove('is_logged_in');
  }

  // Onboarding
  static Future<void> setOnboardingCompleted() async {
    await _prefs.setBool('onboarding_completed', true);
  }

  static bool isOnboardingCompleted() {
    return _prefs.getBool('onboarding_completed') ?? false;
  }
}