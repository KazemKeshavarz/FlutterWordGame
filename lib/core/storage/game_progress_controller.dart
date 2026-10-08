import 'package:flutter/foundation.dart';
import 'game_progress.dart';
import 'game_progress_repository.dart';

class GameProgressController extends ChangeNotifier {
  final GameProgressRepository _repository;

  GameProgress _progress;

  GameProgressController._(this._repository, this._progress);

  static Future<GameProgressController> create() async {
    final repository = GameProgressRepository();
    final progress = await repository.load();
    return GameProgressController._(repository, progress);
  }

  GameProgress get progress => _progress;

  Future<void> completeStage(
    int stageId, {
    int reward = 20,
    int? maxStageId,
    int stars = 3,
  }) async {
    final alreadyCompleted = _progress.completedStages.contains(stageId);
    final completed = Set<int>.from(_progress.completedStages)..add(stageId);
    final previousStars = _progress.stageStars[stageId] ?? 0;
    final updatedStars = Map<int, int>.from(_progress.stageStars)
      ..[stageId] = stars > previousStars ? stars : previousStars;
    final nextStage = stageId + 1;
    final desiredUnlockedStage =
        maxStageId != null && nextStage > maxStageId ? maxStageId : nextStage;

    _progress = _progress.copyWith(
      coins: alreadyCompleted ? _progress.coins : _progress.coins + reward,
      unlockedStage: desiredUnlockedStage > _progress.unlockedStage
          ? desiredUnlockedStage
          : _progress.unlockedStage,
      completedStages: completed,
      stageStars: updatedStars,
    );

    await _repository.save(_progress);
    notifyListeners();
  }

  Future<bool> spendCoins(int amount) async {
    if (amount <= 0 || _progress.coins < amount) return false;

    _progress = _progress.copyWith(coins: _progress.coins - amount);
    await _repository.save(_progress);
    notifyListeners();
    return true;
  }
}
