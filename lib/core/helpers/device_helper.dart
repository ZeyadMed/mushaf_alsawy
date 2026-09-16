// import 'dart:io';
// import 'dart:math';
// import 'package:device_info_plus/device_info_plus.dart';

// abstract interface class DeviceIdHelper {
//   static Future<String> getDeviceIdentifier() async {
//     try {
//       final deviceInfo = DeviceInfoPlugin();

//       if (Platform.isAndroid) {
//         final androidInfo = await deviceInfo.androidInfo;
//         return androidInfo.id; // Android ID (resets on factory reset)
//       }
//       else if (Platform.isIOS) {
//         final iosInfo = await deviceInfo.iosInfo;
//         return iosInfo.identifierForVendor ?? _generateRandomCode();
//       }

//       return _generateRandomCode(); // Fallback for other platforms
//     } catch (e) {
//       return _generateRandomCode(); // Fallback if any error occurs
//     }
//   }

//   static String _generateRandomCode({int length = 8}) {
//     const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
//     final random = Random();
//     return String.fromCharCodes(
//       Iterable.generate(
//         length,
//             (_) => chars.codeUnitAt(random.nextInt(chars.length)),
//       ),
//     );
//   }
// }