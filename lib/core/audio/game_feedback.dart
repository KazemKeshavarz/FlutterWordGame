import 'package:flutter/services.dart';

class GameFeedback {
  static Future<void> letterSelected() async {
    await HapticFeedback.selectionClick();
    await SystemSound.play(SystemSoundType.click);
  }

  static Future<void> correct() async {
    await HapticFeedback.mediumImpact();
    await SystemSound.play(SystemSoundType.click);
  }

  static Future<void> wrong() async {
    await HapticFeedback.lightImpact();
    await SystemSound.play(SystemSoundType.click);
  }
}
