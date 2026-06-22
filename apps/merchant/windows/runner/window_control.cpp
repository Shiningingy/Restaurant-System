#include "window_control.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <variant>

namespace {

// Kept alive for the lifetime of the process (mirrors the OCR channel).
std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_channel;

HWND g_main_window = nullptr;
HWND g_display_window = nullptr;

// Saved main-window state so fullscreen can be toggled back off.
bool g_main_fullscreen = false;
LONG g_saved_style = 0;
WINDOWPLACEMENT g_saved_placement = {sizeof(WINDOWPLACEMENT)};

struct MonitorSearch {
  RECT primary;
  RECT secondary;
  bool has_secondary;
};

BOOL CALLBACK MonitorEnumProc(HMONITOR monitor, HDC, LPRECT, LPARAM lparam) {
  auto* search = reinterpret_cast<MonitorSearch*>(lparam);
  MONITORINFO info = {sizeof(MONITORINFO)};
  if (!GetMonitorInfo(monitor, &info)) {
    return TRUE;
  }
  if (info.dwFlags & MONITORINFOF_PRIMARY) {
    search->primary = info.rcMonitor;
  } else {
    search->secondary = info.rcMonitor;
    search->has_secondary = true;
  }
  return TRUE;
}

// Full bounds of the monitor the customer display should fill: the secondary
// one if there is one (the usual two-screen POS), otherwise the primary.
RECT DisplayMonitorRect() {
  MonitorSearch search = {};
  search.primary = {0, 0, GetSystemMetrics(SM_CXSCREEN),
                    GetSystemMetrics(SM_CYSCREEN)};
  EnumDisplayMonitors(nullptr, nullptr, MonitorEnumProc,
                      reinterpret_cast<LPARAM>(&search));
  return search.has_secondary ? search.secondary : search.primary;
}

// Strips the title bar / borders (so there's no close button) and fills `r`.
// Not made topmost, so the main POS can still be brought forward (Alt+Tab or
// taskbar) even on a single-monitor setup.
void MakeBorderlessFullscreen(HWND hwnd, const RECT& r) {
  LONG style = GetWindowLong(hwnd, GWL_STYLE);
  style &= ~(WS_OVERLAPPEDWINDOW | WS_CAPTION | WS_THICKFRAME | WS_SYSMENU |
             WS_MINIMIZEBOX | WS_MAXIMIZEBOX);
  style |= WS_POPUP;
  SetWindowLong(hwnd, GWL_STYLE, style);
  SetWindowPos(hwnd, HWND_TOP, r.left, r.top, r.right - r.left,
               r.bottom - r.top, SWP_FRAMECHANGED | SWP_SHOWWINDOW);
}

void SetMainFullscreen(bool on) {
  if (!g_main_window || on == g_main_fullscreen) {
    return;
  }
  if (on) {
    g_saved_style = GetWindowLong(g_main_window, GWL_STYLE);
    GetWindowPlacement(g_main_window, &g_saved_placement);
    MONITORINFO mi = {sizeof(MONITORINFO)};
    HMONITOR mon = MonitorFromWindow(g_main_window, MONITOR_DEFAULTTONEAREST);
    GetMonitorInfo(mon, &mi);
    SetWindowLong(g_main_window, GWL_STYLE,
                  g_saved_style & ~WS_OVERLAPPEDWINDOW);
    SetWindowPos(g_main_window, HWND_TOP, mi.rcMonitor.left, mi.rcMonitor.top,
                 mi.rcMonitor.right - mi.rcMonitor.left,
                 mi.rcMonitor.bottom - mi.rcMonitor.top,
                 SWP_FRAMECHANGED | SWP_NOOWNERZORDER);
    g_main_fullscreen = true;
  } else {
    SetWindowLong(g_main_window, GWL_STYLE, g_saved_style);
    SetWindowPlacement(g_main_window, &g_saved_placement);
    SetWindowPos(g_main_window, nullptr, 0, 0, 0, 0,
                 SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER |
                     SWP_NOOWNERZORDER);
    g_main_fullscreen = false;
  }
}

}  // namespace

void WindowControlSetupDisplayWindow(HWND display_window) {
  g_display_window = display_window;
  MakeBorderlessFullscreen(display_window, DisplayMonitorRect());
}

void RegisterWindowControlChannel(flutter::FlutterEngine* engine,
                                  HWND main_window) {
  g_main_window = main_window;
  g_channel = std::make_shared<flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(), "pos/window_control",
      &flutter::StandardMethodCodec::GetInstance());
  g_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        const std::string& method = call.method_name();
        if (method == "setMainFullscreen") {
          bool on = false;
          if (const auto* b = std::get_if<bool>(call.arguments())) {
            on = *b;
          }
          SetMainFullscreen(on);
          result->Success(flutter::EncodableValue(g_main_fullscreen));
        } else if (method == "toggleMainFullscreen") {
          SetMainFullscreen(!g_main_fullscreen);
          result->Success(flutter::EncodableValue(g_main_fullscreen));
        } else if (method == "isMainFullscreen") {
          result->Success(flutter::EncodableValue(g_main_fullscreen));
        } else if (method == "minimizeDisplay") {
          if (g_display_window) {
            ShowWindow(g_display_window, SW_HIDE);
          }
          result->Success();
        } else if (method == "showDisplay") {
          if (g_display_window) {
            ShowWindow(g_display_window, SW_SHOW);
          }
          result->Success();
        } else if (method == "closeDisplay") {
          if (g_display_window) {
            PostMessage(g_display_window, WM_CLOSE, 0, 0);
            g_display_window = nullptr;
          }
          result->Success();
        } else {
          result->NotImplemented();
        }
      });
}
