// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../service_locator/service_locator.dart';

// Future<TimeOfDay?> showTimePickerDialog({
//   required BuildContext context,
//   TimeOfDay? initialTime,
// }) async {
//   return await showDialog<TimeOfDay>(
//     context: context,
//     builder: (context) {
//       return Dialog(
//         insetPadding: const EdgeInsets.all(20),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: BlocProvider.value(
//           value: getIt<TimePickerCubit>(),
//           // child: const EnhancedTimePicker(),
//         ),
//       );
//     },
//   );
// }