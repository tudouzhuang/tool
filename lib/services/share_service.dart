import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';

class ShareService {
  static const String _iosAppLink = 'https://apps.apple.com/us/app/';
  static const String _androidAppLink = 'https://play.google.com/store/apps/details?id=com.scanmaster.toolkit.app';

  static void shareApp() {
    final String appLink = Platform.isIOS ? _iosAppLink : _androidAppLink;
    final String message = 'Check out this amazing app: $appLink';

    if (Platform.isIOS) {
      Share.share(
        message,
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
      );
    } else {
      Share.share(message);
    }
  }
}