#ifndef RUNNER_WINDOW_CONTROL_H_
#define RUNNER_WINDOW_CONTROL_H_

#include <windows.h>

#include <flutter/flutter_engine.h>

// Registers the "pos/window_control" method channel on the main window's engine
// so the POS can drive native window state the multi-window plugin doesn't
// expose: toggling the main window to borderless fullscreen, and
// minimizing / showing / closing the customer-display sub-window. Call once
// after RegisterPlugins with the main window's top-level HWND.
void RegisterWindowControlChannel(flutter::FlutterEngine* engine,
                                  HWND main_window);

// Restyles a freshly created customer-display sub-window into a frameless,
// fullscreen kiosk window on the secondary monitor (no title bar / close
// button, so a customer can't misclick it), and remembers it so the channel
// above can control it. Call from the multi-window "window created" callback.
void WindowControlSetupDisplayWindow(HWND display_window);

#endif  // RUNNER_WINDOW_CONTROL_H_
