import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyService {
  static const String _iosUrl = 'https://sites.google.com/view/emojimixmergemojiprivacypolicy/home';
  static const String _androidUrl = 'https://sites.google.com/view/emojimix-app-privacy-policy/home';

  static Future<void> openPrivacyPolicy() async {
    final String url = Platform.isIOS ? _iosUrl : _androidUrl;
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Ensures compatibility for Android 12+
      );
    } else {
      print('Could not launch: $url');
      throw 'Could not launch $url';
    }
  }
}