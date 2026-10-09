import 'package:audioplayers/audioplayers.dart';

enum GameSound {
  letterSelect,
  wordCorrect,
  wordWrong,
  hint,
  stageComplete,
}

/// پخش صداهای کوتاه بازی؛ در صورت خطای پخش، لایه بازخورد می‌تواند fallback کند.
class GameAudio {
  GameAudio._();

  static final Map<GameSound, AudioPlayer> _players = {};

  static const Map<GameSound, String> _assets = {
    GameSound.letterSelect: 'audio/letter_select.wav',
    GameSound.wordCorrect: 'audio/word_correct.wav',
    GameSound.wordWrong: 'audio/word_wrong.wav',
    GameSound.hint: 'audio/hint.wav',
    GameSound.stageComplete: 'audio/stage_complete.wav',
  };

  static Future<bool> play(GameSound sound) async {
    try {
      final player = _players.putIfAbsent(sound, AudioPlayer.new);
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setVolume(0.75);
      await player.play(AssetSource(_assets[sound]!));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> dispose() async {
    final players = _players.values.toList(growable: false);
    _players.clear();
    for (final player in players) {
      await player.dispose();
    }
  }
}
