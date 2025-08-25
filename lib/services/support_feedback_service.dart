import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static Future<void> launchEmail() async {
    String emailUrl;
    if (Platform.isIOS) {
      emailUrl = "mailto:ha8826603@gmail.com?subject=Feedback&body=Hi there";
    } else {
      emailUrl = "mailto:ha8826603@gmail.com?subject=Feedback&body=Hi there";
    }
    final Uri uri = Uri.parse(emailUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $emailUrl';
    }
  }
}
