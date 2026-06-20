import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notifications.dart';

/// Overridden in main() once SharedPreferences resolves.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// On-device order-status notifications. Overridden in main() with an
/// already-initialised instance; defaults to a fresh one (e.g. in tests,
/// where init/show no-op until initialised).
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
