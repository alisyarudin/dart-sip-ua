import 'dart:io' as io;
import 'package:audioplayers/audioplayers.dart';
import 'package:dart_sip_ua_example/src/incoming_call_native.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Helper class untuk memainkan dan menghentikan ringtone
class RingtoneHelper {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;

  /// Cek apakah platform adalah Android/iOS
  static bool isMobilePlatform() {
    return !kIsWeb && (io.Platform.isAndroid || io.Platform.isIOS);
  }

  /// Memutar ringtone (loop) dari asset
  static Future<void> play() async {
    if (_isPlaying) return;

    try {
      if (isMobilePlatform()) {
        IncomingCallNative.play();
        // Jika menggunakan plugin ringtone native, panggil di sini
        debugPrint('🔊 Ringtone for mobile not implemented in this helper.');
        // Contoh jika ada plugin:
        // IncomingCallNative.play();
      } else {
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.play(AssetSource('ringtone.wav'), volume: 1.0);
        _isPlaying = true;
        debugPrint('✅ Ringtone started on desktop');
      }
    } catch (e) {
      debugPrint('❌ Gagal memutar ringtone: $e');
    }
  }

  /// Menghentikan ringtone
  static Future<void> stop() async {
    try {
      if (isMobilePlatform()) {
        IncomingCallNative.stop();
        // Jika menggunakan plugin ringtone native, panggil di sini
        debugPrint('🔇 Ringtone stopped on mobile (not implemented)');
        // IncomingCallNative.stop();
      } else {
        await _player.stop();
        await _player.release();
        _isPlaying = false;
        debugPrint('🔇 Ringtone stopped on desktop');
      }
    } catch (e) {
      debugPrint('❌ Gagal menghentikan ringtone: $e');
    }
  }

  static bool get isPlaying => _isPlaying;
}
