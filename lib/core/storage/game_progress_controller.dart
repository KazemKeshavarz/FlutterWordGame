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

  Future<void> completeStage(int stageId, {int reward = 20}) async {
    if (_progress.completedStages.contains(stageId)) return;

    final completed = Set<int>.from(_progress.completedStages)..add(stageId);
    final nextStage = stageId + 1;

    _progress = _progress.copyWith(
      coins: _progress.coins + reward,
      unlockedStage: nextStage > _progress.unlockedStage
          ? nextStage
          : _progress.unlockedStage,
      completedStages: completed,
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
