import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper over flutter_local_notifications for order-status alerts.
///
/// On-device notifications only — they fire while the app is running (the
/// status tracker polls and calls [showOrderStatus] on a change). True
/// push-when-closed would need a push server (FCM), which conflicts with the
/// host-nothing model, so it's intentionally out of scope.
class NotificationService {
  static const _channelId = 'order_status';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Initialises the plugin and asks for permission. Safe to call more than
  /// once; a failure (e.g. unsupported platform) is swallowed so it never
  /// blocks app start.
  Future<void> init() async {
    if (_ready) return;
    try {
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
      _ready = true;
    } on Object catch (e) {
      debugPrint('NotificationService.init failed: $e');
    }
  }

  /// Shows a status notification. [id] keys the notification so a later update
  /// for the same order replaces the previous one rather than stacking.
  Future<void> showOrderStatus({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
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
    try {
      await _plugin.show(id, title, body, details);
    } on Object catch (e) {
      debugPrint('NotificationService.show failed: $e');
    }
  }
}
