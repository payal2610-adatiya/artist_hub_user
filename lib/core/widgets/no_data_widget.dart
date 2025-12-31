// import 'package:flutter/material.dart';
// import 'package:artist_hub/core/constants/app_colors.dart';
// import 'package:artist_hub/core/constants/app_strings.dart';
//
// class NoDataWidget extends StatelessWidget {
//   final String message;
//   final String? assetPath;
//   final double imageSize;
//   final Widget? actionButton;
//
//   const NoDataWidget({
//     Key? key,
//     required this.message,
//     this.assetPath,
//     this.imageSize = 150,
//     this.actionButton,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (assetPath != null)
//               Image.asset(
//                 assetPath!,
//                 width: imageSize,
//                 height: imageSize,
//                 color: AppColors.textDisabled.withOpacity(0.5),
//               )
//             else
//               Icon(
//                 Icons.inbox_outlined,
//                 size: imageSize,
//                 color: AppColors.textDisabled.withOpacity(0.5),
//               ),
//             const SizedBox(height: 24),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.textSecondary,
//               ),
//             ),
//             const SizedBox(height: 8),
//             if (actionButton != null) ...[
//               const SizedBox(height: 16),
//               actionButton!,
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }