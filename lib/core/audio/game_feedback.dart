import 'package:flutter/services.dart';

import 'game_audio.dart';

class GameFeedback {
  static Future<void> letterSelected() async {
    await HapticFeedback.selectionClick();
    if (!await GameAudio.play(GameSound.letterSelect)) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  static Future<void> correct() async {
    await HapticFeedback.mediumImpact();
    if (!await GameAudio.play(GameSound.wordCorrect)) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  static Future<void> wrong() async {
    await HapticFeedback.lightImpact();
    if (!await GameAudio.play(GameSound.wordWrong)) {
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  static Future<void> hintUsed() async {
    await HapticFeedback.selectionClick();
    if (!await GameAudio.play(GameSound.hint)) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  static Future<void> stageCompleted() async {
    await HapticFeedback.heavyImpact();
    if (!await GameAudio.play(GameSound.stageComplete)) {
      await SystemSound.play(SystemSoundType.alert);
    }
  }
}
