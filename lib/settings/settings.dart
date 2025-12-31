// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:artist_hub/core/constants/app_colors.dart';
// import 'package:artist_hub/core/constants/app_strings.dart';
// import 'package:artist_hub/providers/auth_provider.dart';
//
// class SettingsScreen extends StatefulWidget {
//   const SettingsScreen({Key? key}) : super(key: key);
//
//   @override
//   _SettingsScreenState createState() => _SettingsScreenState();
// }
//
// class _SettingsScreenState extends State<SettingsScreen> {
//   bool _notificationsEnabled = true;
//   bool _darkMode = false;
//
//   Future<void> _logout() async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Logout'),
//         content: const Text('Are you sure you want to logout?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               await authProvider.logout();
//               Navigator.pushReplacementNamed(context, '/login');
//             },
//             child: const Text(
//               'Logout',
//               style: TextStyle(color: Colors.red),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showPrivacyPolicy() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Privacy Policy'),
//         content: SingleChildScrollView(
//           child: Text(
//             'Artist Hub Privacy Policy\n\n'
//                 '1. Information Collection\n'
//                 'We collect information you provide directly to us, including name, email, phone, and address.\n\n'
//                 '2. Use of Information\n'
//                 'We use your information to provide and improve our services, communicate with you, and process transactions.\n\n'
//                 '3. Data Security\n'
//                 'We implement reasonable security measures to protect your personal information.\n\n'
//                 '4. Third-Party Services\n'
//                 'We may use third-party services for payment processing and analytics.\n\n'
//                 '5. Your Rights\n'
//                 'You have the right to access, correct, or delete your personal information.',
//             style: TextStyle(fontSize: 14, height: 1.5),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showTermsConditions() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Terms & Conditions'),
//         content: SingleChildScrollView(
//           child: Text(
//             'Artist Hub Terms & Conditions\n\n'
//                 '1. Acceptance of Terms\n'
//                 'By using Artist Hub, you agree to these terms and conditions.\n\n'
//                 '2. User Accounts\n'
//                 'You must provide accurate information and keep your account secure.\n\n'
//                 '3. Bookings and Payments\n'
//                 'All bookings are subject to artist availability. Payments are processed securely.\n\n'
//                 '4. Cancellation Policy\n'
//                 'Cancellations must be made at least 48 hours before the event for a full refund.\n\n'
//                 '5. Content Guidelines\n'
//                 'Users must not post inappropriate or offensive content.\n\n'
//                 '6. Limitation of Liability\n'
//                 'Artist Hub is not liable for disputes between artists and customers.',
//             style: TextStyle(fontSize: 14, height: 1.5),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showHelpSupport() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Help & Support'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Need help? Contact us through:\n',
//               style: TextStyle(fontSize: 14),
//             ),
//             ListTile(
//               leading: Icon(Icons.email, color: AppColors.deepForest),
//               title: Text('Email', style: TextStyle(fontWeight: FontWeight.w500)),
//               subtitle: Text('support@artisthub.com'),
//             ),
//             ListTile(
//               leading: Icon(Icons.phone, color: AppColors.deepForest),
//               title: Text('Phone', style: TextStyle(fontWeight: FontWeight.w500)),
//               subtitle: Text('+1 (555) 123-4567'),
//             ),
//             ListTile(
//               leading: Icon(Icons.access_time, color: AppColors.deepForest),
//               title: Text('Hours', style: TextStyle(fontWeight: FontWeight.w500)),
//               subtitle: Text('Mon-Fri: 9AM-6PM\nSat-Sun: 10AM-4PM'),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showAboutUs() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('About Us'),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'Artist Hub\n',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.deepForest,
//                 ),
//               ),
//               Text(
//                 'Version 1.0.0\n',
//                 style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
//               ),
//               Text(
//                 'Artist Hub connects talented artists with customers looking for entertainment for their events.\n\n'
//                     'Our mission is to make booking artists easy, secure, and reliable for everyone.\n\n'
//                     'Whether you\'re an artist looking to showcase your talent or a customer planning your next event, Artist Hub is here to help.',
//                 style: TextStyle(fontSize: 14, height: 1.5),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Settings'),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           // App Settings
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               child: Column(
//                 children: [
//                   ListTile(
//                     leading: Icon(Icons.notifications_none, color: AppColors.deepForest),
//                     title: const Text('Notifications'),
//                     trailing: Switch(
//                       value: _notificationsEnabled,
//                       onChanged: (value) {
//                         setState(() => _notificationsEnabled = value);
//                       },
//                       activeColor: AppColors.deepForest,
//                     ),
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.dark_mode_outlined, color: AppColors.deepForest),
//                     title: const Text('Dark Mode'),
//                     trailing: Switch(
//                       value: _darkMode,
//                       onChanged: (value) {
//                         setState(() => _darkMode = value);
//                       },
//                       activeColor: AppColors.deepForest,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//
//           // Legal & Support
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               child: Column(
//                 children: [
//                   ListTile(
//                     leading: Icon(Icons.privacy_tip_outlined, color: AppColors.deepForest),
//                     title: const Text('Privacy Policy'),
//                     onTap: _showPrivacyPolicy,
//                     trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.description_outlined, color: AppColors.deepForest),
//                     title: const Text('Terms & Conditions'),
//                     onTap: _showTermsConditions,
//                     trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.help_outline, color: AppColors.deepForest),
//                     title: const Text('Help & Support'),
//                     onTap: _showHelpSupport,
//                     trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.info_outline, color: AppColors.deepForest),
//                     title: const Text('About Us'),
//                     onTap: _showAboutUs,
//                     trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 32),
//
//           // Logout Button
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: ElevatedButton.icon(
//               onPressed: _logout,
//               icon: const Icon(Icons.logout, size: 20),
//               label: const Text(
//                 'Logout',
//                 style: TextStyle(fontSize: 16),
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.error,
//                 foregroundColor: Colors.white,
//                 minimumSize: const Size(double.infinity, 50),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ),
//
//           // App Version
//           const SizedBox(height: 24),
//           Center(
//             child: Text(
//               'Artist Hub v1.0.0',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: AppColors.textSecondary,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }