import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';

/// Order-status notifications across platforms.
///
/// - Android / iOS: flutter_local_notifications.
/// - Windows: local_notifier posts a real toast to the Action Center (the
///   cross-platform plugin has no Windows backend). Its `setup` also creates
///   the Start-Menu shortcut Windows requires to attribute toasts to the app.
///
/// On-device only — they fire while the app is running (the status tracker
/// polls and calls [showOrderStatus] on a change). True push-when-closed would
/// need a push server (FCM), which conflicts with host-nothing, so it's out of
/// scope.
class NotificationService {
  static const _channelId = 'order_status';
  static const _windowsAppName = 'Restaurant Customer';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get _isWindows => !kIsWeb && Platform.isWindows;

  /// Initialises the right backend and asks for permission. Safe to call more
  /// than once; failures are swallowed so they never block app start.
  Future<void> init() async {
    if (_ready) return;
    try {
      if (_isWindows) {
        await localNotifier.setup(
          appName: _windowsAppName,
          shortcutPolicy: ShortcutPolicy.requireCreate,
        );
      } else {
        const android = AndroidInitializationSettings('@mipmap/ic_launcher');
        const darwin = DarwinInitializationSettings();
        await _plugin.initialize(
          const InitializationSettings(android: android, iOS: darwin),
        );
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
      _ready = true;
    } on Object catch (e) {
      debugPrint('NotificationService.init failed: $e');
    }
  }

  /// Shows a status notification. [id] keys it so a later update for the same
  /// order replaces the previous notification rather than stacking (mobile).
  Future<void> showOrderStatus({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      if (_isWindows) {
        await LocalNotification(title: title, body: body).show();
        return;
      }
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Order status',
          channelDescription: 'Updates about your pickup orders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.show(id, title, body, details);
    } on Object catch (e) {
      debugPrint('NotificationService.show failed: $e');
    }
  }
}
