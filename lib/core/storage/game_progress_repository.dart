import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_progress.dart';

class GameProgressRepository {
  static const _coinsKey = 'game_coins';
  static const _unlockedStageKey = 'game_unlocked_stage';
  static const _completedStagesKey = 'game_completed_stages';
  static const _stageStarsKey = 'game_stage_stars';

  Future<GameProgress> load() async {
    final preferences = await SharedPreferences.getInstance();
    final starsJson = preferences.getString(_stageStarsKey);
    final decoded = starsJson == null
        ? <String, dynamic>{}
        : (jsonDecode(starsJson) as Map<String, dynamic>);

    return GameProgress(
      coins: preferences.getInt(_coinsKey) ?? 100,
      unlockedStage: preferences.getInt(_unlockedStageKey) ?? 1,
      completedStages:
          (preferences.getStringList(_completedStagesKey) ?? const [])
              .map(int.parse)
              .toSet(),
      stageStars: decoded.map(
        (key, value) => MapEntry(int.parse(key), (value as num).toInt()),
      ),
    );
  }

  Future<void> save(GameProgress progress) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setInt(_coinsKey, progress.coins);
    await preferences.setInt(_unlockedStageKey, progress.unlockedStage);
    await preferences.setStringList(
      _completedStagesKey,
      progress.completedStages.map((id) => id.toString()).toList(),
    );
    await preferences.setString(
      _stageStarsKey,
      jsonEncode(
        progress.stageStars.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
    );
  }
}