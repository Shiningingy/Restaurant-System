import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Drives native window state that the desktop_multi_window plugin doesn't
/// expose (Windows only): toggling the main POS window to borderless
/// fullscreen, and showing / hiding / closing the customer-display sub-window
/// entirely from the POS — so a customer can't misclick a close button on the
/// frameless second screen. All calls no-op off Windows.
class WindowControl {
  static const _channel = MethodChannel('pos/window_control');

  bool get _supported => Platform.isWindows;

  /// Hides the customer display (bring it back with [showDisplay]).
  Future<void> minimizeDisplay() => _invoke('minimizeDisplay');

  /// Re-shows a hidden customer display.
  Future<void> showDisplay() => _invoke('showDisplay');

  /// Closes (destroys) the customer-display window.
  Future<void> closeDisplay() => _invoke('closeDisplay');

  /// Sets the main POS window to borderless fullscreen (or restores it).
  /// Returns the resulting fullscreen state.
  Future<bool> setMainFullscreen(bool on) async =>
      await _invokeBool('setMainFullscreen', on) ?? on;

  /// Toggles the main POS window's fullscreen; returns the new state.
  Future<bool> toggleMainFullscreen() async =>
      await _invokeBool('toggleMainFullscreen') ?? false;

  Future<void> _invoke(String method, [dynamic args]) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod(method, args);
    } on PlatformException catch (_) {
    } on MissingPluginException catch (_) {}
  }

  Future<bool?> _invokeBool(String method, [dynamic args]) async {
    if (!_supported) return null;
    try {
      return await _channel.invokeMethod<bool>(method, args);
    } catch (_) {
      return null;
    }
  }
}

final windowControlProvider = Provider<WindowControl>((ref) => WindowControl());

/// Whether the main POS window is currently borderless-fullscreen (drives the
/// Settings switch + the F11 toggle). Set by whoever toggles fullscreen.
class MainFullscreenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final mainFullscreenProvider = NotifierProvider<MainFullscreenNotifier, bool>(
  MainFullscreenNotifier.new,
);
