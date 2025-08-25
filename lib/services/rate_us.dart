import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  static const String _androidUrl = 'https://play.google.com/store/apps/details?id=com.scanmaster.toolkit.app';
  static const String _iosUrl = 'https://apps.apple.com/us/app/';

  static Future<void> launchAppStore() async {
    final url = Platform.isIOS ? _iosUrl : _androidUrl;

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }
}