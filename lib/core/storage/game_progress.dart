class GameProgress {
  final int coins;
  final int unlockedStage;
  final Set<int> completedStages;

  const GameProgress({
    required this.coins,
    required this.unlockedStage,
    required this.completedStages,
  });

  GameProgress copyWith({
    int? coins,
    int? unlockedStage,
    Set<int>? completedStages,
  }) {
    return GameProgress(
      coins: coins ?? this.coins,
      unlockedStage: unlockedStage ?? this.unlockedStage,
      completedStages: completedStages ?? this.completedStages,
    );
  }
}
