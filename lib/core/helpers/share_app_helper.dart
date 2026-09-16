// import 'dart:io';

// abstract interface class ShareAppHelper{
//   static Future<void> shareAppLink() async {
//     const androidAppLink = 'https://play.google.com/store/apps/details?id=tech.brmja.aalmny';
//     const iosAppLink = 'https://apps.apple.com/app/YOUR_APP_ID';

//     final message = 'Check out this amazing app!\n'
//         '${Platform.isAndroid ? androidAppLink : iosAppLink}';

//     await SharePlus.instance.share(ShareParams(text: message));
//   }
// }