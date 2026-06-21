import 'dart:async';
import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers.dart';
import 'core/secure/secure_store.dart';
import 'features/customer_display/presentation/customer_display_app.dart';
import 'features/printing/application/providers.dart';
import 'features/sync/application/providers.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // The customer-display sub-window carries non-empty arguments; the main POS
  // window has none. It owns no database/cloud — it just renders what the POS
  // window pushes it. fromCurrentEngine can fail on the main window on some
  // setups, so treat any failure as "main window".
  WindowController? windowController;
  try {
    windowController = await WindowController.fromCurrentEngine();
  } catch (_) {
    windowController = null;
  }
  final argStr = windowController?.arguments ?? '';
  if (windowController != null && argStr.isNotEmpty) {
    runApp(
      CustomerDisplayApp(
        windowController: windowController,
        args: jsonDecode(argStr) as Map<String, dynamic>,
      ),
    );
    return;
  }
  final prefs = await SharedPreferences.getInstance();
  // Read (or create on first run) the database encryption key from OS-encrypted
  // secure storage before the provider graph opens the database.
  final dbKey = await SecureStore().getOrCreateDbKey();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      dbKeyProvider.overrideWithValue(dbKey),
    ],
  );
  // Load the cloud refresh token from secure storage (migrating any token left
  // in shared_preferences by an older build) before sync reads it.
  await container.read(syncSettingsProvider).warmRefreshToken();
  // Resume any print jobs interrupted by the last shutdown.
  await container.read(printServiceProvider).start();
  // Best-effort cloud sync on launch (no-op when not configured); never
  // blocks startup and failures are surfaced in Settings, not here.
  unawaited(container.read(syncServiceProvider).syncNow());
  runApp(
    UncontrolledProviderScope(container: container, child: const MerchantApp()),
  );
}
