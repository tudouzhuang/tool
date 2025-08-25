import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize(BuildContext context) async {
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSInit = DarwinInitializationSettings(
      requestAlertPermission: false, // Don't request automatically
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iOSInit,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        debugPrint('notification_tapped'.tr);
      },
    );
  }

  static Future<bool> requestPermissions() async {
    bool permissionGranted = false;

    try {
      // Request permissions for Android
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final androidResult = await androidPlugin.requestNotificationsPermission();
        permissionGranted = androidResult ?? false;
      }

      // Request permissions for iOS
      final iOSPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iOSPlugin != null) {
        final iOSResult = await iOSPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        permissionGranted = iOSResult ?? false;
      }

      // Save permission status
      if (permissionGranted) {
        await _saveNotificationPermissionStatus(true);
      }

      return permissionGranted;
    } catch (e) {
      debugPrint('error_requesting_permissions'.tr);
      return false;
    }
  }

  static Future<bool> areNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notifications_enabled') ?? false;
    } catch (e) {
      debugPrint('error_checking_notification_status'.tr);
      return false;
    }
  }

  static Future<void> _saveNotificationPermissionStatus(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', enabled);
    } catch (e) {
      debugPrint('error_saving_notification_status'.tr);
    }
  }

  static Future<void> setNotificationEnabled(bool enabled) async {
    await _saveNotificationPermissionStatus(enabled);
  }

  static Future<void> showExportNotification() async {
    // Check if notifications are enabled before showing
    if (!await areNotificationsEnabled()) {
      debugPrint('notifications_disabled_skipping'.tr);
      return;
    }

    final AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'export_channel',
      'export_notifications_channel_name'.tr,
      channelDescription: 'export_notifications_channel_description'.tr,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        'cv_exported_successfully_message'.tr,
        htmlFormatBigText: false,
        contentTitle: 'export_complete_title'.tr,
        htmlFormatContentTitle: false,
      ),
      ticker: 'cv_export_complete_ticker'.tr,
    );

    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      subtitle: 'cv_export_complete_subtitle'.tr,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    try {
      await _notificationsPlugin.show(
        0,
        'export_complete_title'.tr,
        'cv_exported_successfully_message'.tr,
        notificationDetails,
        payload: 'export_complete',
      );
    } catch (e) {
      debugPrint('error_showing_export_notification'.tr);
    }
  }

  static Future<void> showExportStartNotification() async {
    // Check if notifications are enabled before showing
    if (!await areNotificationsEnabled()) {
      debugPrint('notifications_disabled_skipping'.tr);
      return;
    }

    final AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'export_channel',
      'export_notifications_channel_name'.tr,
      channelDescription: 'export_notifications_channel_description'.tr,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      showProgress: true,
      indeterminate: true,
    );

    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      subtitle: 'exporting_cv_subtitle'.tr,
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    try {
      await _notificationsPlugin.show(
        1,
        'exporting_cv_title'.tr,
        'exporting_cv_message'.tr,
        notificationDetails,
        payload: 'export_started',
      );
    } catch (e) {
      debugPrint('error_showing_export_start_notification'.tr);
    }
  }

  static Future<void> cancelExportProgressNotification() async {
    try {
      await _notificationsPlugin.cancel(1);
    } catch (e) {
      debugPrint('error_canceling_progress_notification'.tr);
    }
  }

  static Future<void> showErrorNotification(String error) async {
    // Check if notifications are enabled before showing
    if (!await areNotificationsEnabled()) {
      debugPrint('notifications_disabled_skipping'.tr);
      return;
    }

    final AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'export_channel',
      'export_notifications_channel_name'.tr,
      channelDescription: 'export_notifications_channel_description'.tr,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        'export_error_message'.tr,
        htmlFormatBigText: false,
        contentTitle: 'export_failed_title'.tr,
        htmlFormatContentTitle: false,
      ),
    );

    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      subtitle: 'export_failed_subtitle'.tr,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    try {
      await _notificationsPlugin.show(
        2,
        'export_failed_title'.tr,
        'export_error_brief_message'.tr,
        notificationDetails,
        payload: 'export_failed',
      );
    } catch (e) {
      debugPrint('error_showing_error_notification'.tr);
    }
  }
}