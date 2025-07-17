import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

class NotificationWinHelper {
  static bool _initialized = false;

  /// Call this once in `main()` before using any other method
  static Future<void> init() async {
    try {
      await localNotifier.setup(
        appName: 'Loket CTI Notifier',
        shortcutPolicy: ShortcutPolicy.requireCreate, // Windows-only
      );
      _initialized = true;
      debugPrint('✅ local_notifier initialized');
    } catch (e) {
      debugPrint('❌ Failed to init local_notifier: $e');
    }
  }

  /// Show a simple notification (title & body)
  static Future<void> showBasic(String title, String body) async {
    if (!_initialized) {
      debugPrint('⚠️ local_notifier not initialized. Call init() first.');
      return;
    }

    final notification = LocalNotification(
      title: title,
      body: body,
    );

    notification.onShow = () {
      debugPrint('🔔 Notification shown: ${notification.identifier}');
    };

    notification.onClick = () {
      debugPrint('🖱️ Notification clicked: ${notification.identifier}');
    };

    notification.onClose = (reason) {
      debugPrint(
          '❎ Notification closed: ${notification.identifier}, reason: $reason');
    };

    await notification.show();
  }
}
