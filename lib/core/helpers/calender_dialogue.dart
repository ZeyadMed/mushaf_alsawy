// import 'package:eb3at/core/bloc/common/calender/calender_cubit.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import '../service_locator/service_locator.dart';
// Future<DateTime?> showCalendarDialog({
//   required BuildContext context,
//   bool canSelectPast = false,
//   DateTime? initialDate,
// }) async {
//   return await showDialog<DateTime>(
//     context: context,
//     builder: (context) {
//       return Dialog(
//         backgroundColor: Colors.transparent,
//         insetPadding: const EdgeInsets.all(20),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(
//             maxWidth: 400, // Set a reasonable max width
//           ),
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: BlocProvider.value(
//                 value: getIt<CalendarCubit>(),
//                 child: EnhancedCalendar(
//                   canSelectPast: canSelectPast,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     },
//   );
// }