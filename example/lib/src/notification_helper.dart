import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Inisialisasi notifikasi untuk Android, Windows, dll
  static Future<void> init() async {
    if (kIsWeb) {
      debugPrint("❌ Notifikasi tidak tersedia di Web");
      return;
    }

    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
            appName: 'Flutter Local Notifications Example',
            appUserModelId: 'Com.Dexterous.FlutterLocalNotificationsExample',
            // Search online for GUID generators to make your own
            guid: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb');

    final initSettings = InitializationSettings(
      android: androidSettings,
      windows: initializationSettingsWindows,
    );

    try {
      await _plugin.initialize(initSettings,
          onDidReceiveNotificationResponse: (response) {
        debugPrint("🛎️ Notifikasi ditekan: ${response.payload}");
      });
      _initialized = true;
      debugPrint("✅ Notifikasi berhasil diinisialisasi");
    } catch (e) {
      debugPrint("❌ Gagal inisialisasi notifikasi: $e");
    }
  }

  /// Menampilkan notifikasi sederhana
  static Future<void> showBasicNotification(String title, String body) async {
    if (!_initialized) {
      debugPrint("❌ Notifikasi belum diinisialisasi");
      return;
    }
    debugPrint('🔍 isInitialized = $_initialized');

    // const androidDetails = AndroidNotificationDetails(
    //   'basic_channel',
    //   'Basic Notifications',
    //   importance: Importance.max,
    //   priority: Priority.high,
    // );

    const windowsDetails = WindowsNotificationDetails(
      actions: [
        WindowsAction(content: 'Terima', arguments: 'accept'),
        WindowsAction(content: 'Tolak', arguments: 'decline'),
      ],
    );

    const details = NotificationDetails(
      windows: windowsDetails,
    );

    await _plugin.show(
      1001,
      'Panggilan Masuk',
      'Dari Cabang Jakarta',
      details,
      payload: 'basic_payload',
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Helper untuk cek platform mobile
  static bool isMobilePlatform() {
    return !kIsWeb && (io.Platform.isAndroid || io.Platform.isIOS);
  }
}
