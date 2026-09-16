import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
abstract interface class UriLauncher {
  static Future<void> launchUrl(String url) async {
      await launchUrl(url);

  }

  static Future<void> launchWhatsApp(String number) async {
    String url() {
      if (Platform.isIOS) {
        return "https://wa.me/$number";
      } else {
        return "https://api.whatsapp.com/send?phone=$number";
      }
    }

    if (await canLaunchUrl(Uri.parse(url()))) {
      await launchUrl(url());
    } else {
      throw 'Could not launch whatsapp://send?phone=$number';
    }
  }

  static Future<void> launchPhone(String number) async {
    final url = 'tel:$number';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static Future<void> launchBrowser(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}