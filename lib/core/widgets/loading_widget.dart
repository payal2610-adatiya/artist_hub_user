// import 'package:flutter/material.dart';
// import 'package:artist_hub/core/constants/app_colors.dart';
//
// class LoadingWidget extends StatelessWidget {
//   final String? message;
//   final Color? color;
//   final double? size;
//
//   const LoadingWidget({
//     Key? key,
//     this.message,
//     this.color,
//     this.size = 40,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           SizedBox(
//             width: size,
//             height: size,
//             child: CircularProgressIndicator(
//               strokeWidth: 3,
//               valueColor: AlwaysStoppedAnimation<Color>(
//                 color ?? AppColors.deepForest,
//               ),
//             ),
//           ),
//           if (message != null) ...[
//             const SizedBox(height: 16),
//             Text(
//               message!,
//               style: TextStyle(
//                 color: AppColors.textSecondary,
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }