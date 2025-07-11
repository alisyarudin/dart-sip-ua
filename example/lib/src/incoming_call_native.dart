import 'dart:io';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class IncomingCallNative {
  static void play() {
    FlutterRingtonePlayer().playRingtone();
  }

  static void stop() {
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterRingtonePlayer().stop();
    }
  }
}
