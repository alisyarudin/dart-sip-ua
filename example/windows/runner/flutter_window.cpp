#include "flutter_window.h"
#include <optional>
#include <shellapi.h>
#include "flutter/generated_plugin_registrant.h"

#define WM_TRAYICON (WM_USER + 1)

NOTIFYICONDATA nid = {};
HWND global_hwnd = nullptr;
HMENU hTrayMenu = nullptr;

FlutterWindow::FlutterWindow(const flutter::DartProject &project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

void AddTrayIcon(HWND hwnd)
{
  nid.cbSize = sizeof(NOTIFYICONDATA);
  nid.hWnd = hwnd;
  nid.uID = 1;
  nid.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
  nid.uCallbackMessage = WM_TRAYICON;
  nid.hIcon = LoadIcon(nullptr, IDI_INFORMATION); // Ganti dengan ikon kustom jika perlu
  wcscpy_s(nid.szTip, L"Aplikasi Flutter Kamu");

  Shell_NotifyIcon(NIM_ADD, &nid);
}

void RemoveTrayIcon()
{
  Shell_NotifyIcon(NIM_DELETE, &nid);
  if (hTrayMenu)
  {
    DestroyMenu(hTrayMenu);
    hTrayMenu = nullptr;
  }
}

void ShowTrayMenu(HWND hwnd)
{
  if (!hTrayMenu)
  {
    hTrayMenu = CreatePopupMenu();
    AppendMenu(hTrayMenu, MF_STRING, 1, L"Show");
    AppendMenu(hTrayMenu, MF_STRING, 2, L"Exit");
  }

  POINT cursor;
  GetCursorPos(&cursor);
  SetForegroundWindow(hwnd); // Penting agar menu muncul dengan benar
  TrackPopupMenu(hTrayMenu, TPM_RIGHTBUTTON, cursor.x, cursor.y, 0, hwnd, NULL);
}

bool FlutterWindow::OnCreate()
{
  if (!Win32Window::OnCreate())
  {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);

  if (!flutter_controller_->engine() || !flutter_controller_->view())
  {
    return false;
  }

  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]()
                                                      { this->Show(); });

  flutter_controller_->ForceRedraw();

  global_hwnd = GetHandle();     // Simpan handle
  AddTrayIcon(global_hwnd);      // Tambahkan tray icon

  return true;
}

void FlutterWindow::OnDestroy()
{
  RemoveTrayIcon(); // Hapus tray saat aplikasi tutup

  if (flutter_controller_)
  {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept
{
  switch (message)
  {
  case WM_SYSCOMMAND:
    if (wparam == SC_CLOSE)
    {
      int result = MessageBox(hwnd,
                              L"Yakin ingin keluar dari aplikasi?",
                              L"Konfirmasi",
                              MB_YESNO | MB_ICONQUESTION | MB_DEFBUTTON2);
      if (result == IDYES)
      {
        PostQuitMessage(0);
      }
      else
      {
        return 0;
      }
    }
    else if (wparam == SC_MINIMIZE)
    {
      ShowWindow(hwnd, SW_HIDE); // Sembunyikan saat minimize
      return 0;
    }
    break;

  case WM_TRAYICON:
    switch (lparam)
    {
    case WM_LBUTTONDBLCLK:
      ShowWindow(hwnd, SW_SHOW);
      SetForegroundWindow(hwnd);
      break;
    case WM_RBUTTONUP:
      ShowTrayMenu(hwnd);
      break;
    }
    return 0;

  case WM_COMMAND:
    switch (LOWORD(wparam))
    {
    case 1: // Show
      ShowWindow(hwnd, SW_SHOW);
      SetForegroundWindow(hwnd);
      break;
    case 2: // Exit
      PostQuitMessage(0);
      break;
    }
    return 0;
  }

  if (flutter_controller_)
  {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam, lparam);
    if (result)
    {
      return *result;
    }
  }

  if (message == WM_FONTCHANGE && flutter_controller_)
  {
    flutter_controller_->engine()->ReloadSystemFonts();
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
