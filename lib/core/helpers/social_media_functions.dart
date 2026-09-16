import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mushaf_alsawy/core/helpers/custom_error_message.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class SocialMediaUtils {
  // دالة عامة لإظهار SnackBar عند الخطأ
  void _showErrorSnackBar(String message, BuildContext context) {
    CustomErrorOverlay.show(context: context, text: message);
  }

  Uri _normalizeUri(String raw) {
    var urlStr = raw.trim();
    if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) {
      urlStr = 'https://$urlStr';
    }
    return Uri.parse(urlStr);
  }

  // دالة لفتح واتساب باستخدام رقم الهاتف
  Future<void> launchWhatsApp(String? phone, BuildContext context) async {
    if (phone == null || phone.isEmpty) {
      _showErrorSnackBar("noWhatsAppAvailable".tr(), context);
      return;
    }

    String formattedPhone = phone;
    // wa.me expects no plus sign in the path
    final numeric = formattedPhone.replaceAll('+', '').replaceAll(' ', '');
    final text =
        Uri.encodeComponent('مرحبا انا عميل المحامي المحترف اريد المساعدة ...');
    final uri = Uri.parse('https://wa.me/$numeric?text=$text');

    try {
      var launched = false;
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (!launched) {
        // fallback attempts
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } catch (_) {}
      }
      if (!launched) {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showErrorSnackBar("failedToOpenWhatsApp".tr(), context);
    }
  }

  // دالة لفتح فيسبوك باستخدام رابط الصفحة
  Future<void> launchFacebook(String? link, BuildContext context) async {
    if (link == null || link.isEmpty) {
      _showErrorSnackBar("noFacebookAvailable".tr(), context);
      return;
    }

    try {
      final url = _normalizeUri(link);
      var launched = false;
      if (await canLaunchUrl(url)) {
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.inAppWebView);
        } catch (_) {}
      }
      if (!launched) throw 'Could not launch Facebook';
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showErrorSnackBar("failedToOpenFacebook".tr(), context);
    }
  }

  // دالة لفتح إنستغرام باستخدام اسم المستخدم
  Future<void> launchInstagram(String? username, BuildContext context) async {
    if (username == null || username.isEmpty) {
      _showErrorSnackBar("noInstagramAvailable".tr(), context);
      return;
    }

    try {
      final url = _normalizeUri(username.contains('http')
          ? username
          : 'https://www.instagram.com/$username');
      var launched = false;
      if (await canLaunchUrl(url))
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.inAppWebView);
        } catch (_) {}
      }
      if (!launched) throw 'Could not launch Instagram';
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showErrorSnackBar("failedToOpenInstagram".tr(), context);
    }
  }

  // دالة لفتح تويتر (إكس) باستخدام اسم المستخدم
  Future<void> launchTwitter(String? username, BuildContext context) async {
    if (username == null || username.isEmpty) {
      _showErrorSnackBar("noTwitterAvailable".tr(), context);
      return;
    }

    try {
      final url = _normalizeUri(
          username.contains('http') ? username : 'https://x.com/$username');
      var launched = false;
      if (await canLaunchUrl(url))
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.inAppWebView);
        } catch (_) {}
      }
      if (!launched) throw 'Could not launch Twitter';
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showErrorSnackBar("failedToOpenTwitter".tr(), context);
    }
  }

  // دالة لفتح سناب شات باستخدام اسم المستخدم
  Future<void> launchSnapchat(String? username, BuildContext context) async {
    if (username == null || username.isEmpty) {
      _showErrorSnackBar("noSnapchatAvailable".tr(), context);
      return;
    }

    try {
      final url = _normalizeUri('https://www.snapchat.com/add/$username');
      var launched = false;
      if (await canLaunchUrl(url))
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.inAppWebView);
        } catch (_) {}
      }
      if (!launched) throw 'Could not launch Snapchat';
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showErrorSnackBar("failedToOpenSnapchat", context);
    }
  }

  // دالة لفتح تيليغرام باستخدام اسم المستخدم أو رقم الهاتف
  Future<void> launchTelegram(String? identifier, BuildContext context) async {
    if (identifier == null || identifier.isEmpty) {
      _showErrorSnackBar("noTelegramAvailable".tr(), context);
      return;
    }

    try {
      final url = _normalizeUri(identifier.startsWith('+')
          ? 'https://t.me/$identifier'
          : 'https://t.me/@$identifier');
      var launched = false;
      if (await canLaunchUrl(url))
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.inAppWebView);
        } catch (_) {}
      }
      if (!launched) throw 'Could not launch Telegram';
    } catch (e) {
      _showErrorSnackBar("failedToOpenTelegram".tr(), context);
    }
  }

  // دالة لفتح لينكدإن باستخدام رابط الملف الشخصي
  Future<void> launchLinkedIn(String? profileUrl, BuildContext context) async {
    if (profileUrl == null || profileUrl.isEmpty) {
      _showErrorSnackBar("noLinkedInAvailable".tr(), context);
      return;
    }

    try {
      final url = _normalizeUri(profileUrl.contains('http')
          ? profileUrl
          : 'https://www.linkedin.com/in/$profileUrl');
      var launched = false;
      if (await canLaunchUrl(url))
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.inAppWebView);
        } catch (_) {}
      }
      if (!launched) throw 'Could not launch LinkedIn';
    } catch (e) {
      _showErrorSnackBar("failedToOpenLinkedIn".tr(), context);
    }
  }

  // دالة لفتح الإيميل باستخدام عنوان البريد
  Future<void> launchEmail(String? email, BuildContext context) async {
    if (email == null || email.isEmpty) {
      _showErrorSnackBar("noEmailAvailable".tr(), context);
      return;
    }

    try {
      // Build a proper mailto URI with encoded query parameters
      final uri = Uri(
        scheme: 'mailto',
        path: email.trim(),
        queryParameters: {
          'subject': 'Help Request',
          'body': 'Hello, I need assistance with...'
        },
      );

      var launched = false;

      // Try a few launch modes to increase reliability across devices
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } catch (_) {}
      }

      if (!launched) throw 'Could not launch Email';
    } catch (e) {
      // Provide a friendly localized error message
      _showErrorSnackBar("failedToOpenEmail".tr(), context);
    }
  }

  // دالة لفتح تطبيق الهاتف باستخدام رقم الهاتف
  Future<void> launchPhoneNumber(
      String? phoneNumber, BuildContext context) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showErrorSnackBar("noPhoneNumberAvailable".tr(), context);
      return;
    }

    try {
      final url = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch phone dialer';
      }
    } catch (e) {
      _showErrorSnackBar("failedToOpenPhoneDialer".tr(), context);
    }
  }

  // دالة لفتح موقع ويب باستخدام رابط الموقع
  Future<void> launchWebsite(String? websiteUrl, BuildContext context) async {
    if (websiteUrl == null || websiteUrl.isEmpty) {
      _showErrorSnackBar("noWebsiteAvailable".tr(), context);
      return;
    }

    try {
      // Ensure URL has a scheme
      String urlStr = websiteUrl.trim();
      if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) {
        urlStr = 'https://$urlStr';
      }

      // Try to parse; if it fails, try encoding and parse again
      Uri url = Uri.tryParse(urlStr) ?? Uri.parse(Uri.encodeFull(urlStr));

      // If this is a PDF link, download and open it with a native PDF viewer
      final lower = urlStr.toLowerCase();
      if (lower.contains('.pdf')) {
        await openOrDownloadFile(urlStr, context, saveToDownloads: false);
        return;
      }

      // Try a few launch modes to improve reliability across devices
      bool launched = false;

      if (await canLaunchUrl(url)) {
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.inAppWebView);
        } catch (_) {}
      }

      if (!launched) throw 'Could not launch Website';
    } catch (e) {
      // Optionally log the error `e` for debugging
      _showErrorSnackBar("failedToOpenWebsite".tr(), context);
    }
  }

  /// Open or download a remote file (PDFs get downloaded and opened locally).
  Future<void> openOrDownloadFile(String? fileUrl, BuildContext context,
      {bool saveToDownloads = false}) async {
    if (fileUrl == null || fileUrl.isEmpty) {
      _showErrorSnackBar("noWebsiteAvailable".tr(), context);
      return;
    }

    try {
      // final uri = Uri.parse(fileUrl);
      final lower = fileUrl.toLowerCase();

      // Only special-case PDFs for download & open
      if (lower.contains('.pdf')) {
        await _downloadAndOpenPdf(fileUrl, context,
            saveToDownloads: saveToDownloads);
        return;
      }

      // Fallback: open via normal website launcher
      await launchWebsite(fileUrl, context);
    } catch (e) {
      _showErrorSnackBar("failedToOpenWebsite".tr(), context);
    }
  }

  Future<void> _downloadAndOpenPdf(String url, BuildContext context,
      {bool saveToDownloads = false}) async {
    try {
      final uri = Uri.parse(url);
      final filename =
          uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file.pdf';

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$filename';

      final dio = Dio();
      await dio.download(url, filePath);

      // If requested, attempt to also copy to a user-accessible Downloads-like folder
      if (saveToDownloads) {
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            final downloadsDir = Directory('${externalDir.path}/Download');
            if (!await downloadsDir.exists())
              await downloadsDir.create(recursive: true);
            final destPath = '${downloadsDir.path}/$filename';
            await File(filePath).copy(destPath);
            _showErrorSnackBar('fileSavedTo: $destPath', context);
          }
        } catch (_) {
          // ignore copy errors, continue to open temp file
        }
      }

      // Open the downloaded file with the device's default handler
      await OpenFile.open(filePath);
    } catch (e) {
      _showErrorSnackBar("failedToOpenWebsite".tr(), context);
    }
  }
}
