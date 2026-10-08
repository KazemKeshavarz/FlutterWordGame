class GameProgress {
  final int coins;
  final int unlockedStage;
  final Set<int> completedStages;
  final Map<int, int> stageStars;

  const GameProgress({
    required this.coins,
    required this.unlockedStage,
    required this.completedStages,
    required this.stageStars,
  });

  int starsFor(int stageId) => stageStars[stageId] ?? 0;

  GameProgress copyWith({
    int? coins,
    int? unlockedStage,
    Set<int>? completedStages,
    Map<int, int>? stageStars,
  }) {
    return GameProgress(
      coins: coins ?? this.coins,
      unlockedStage: unlockedStage ?? this.unlockedStage,
      completedStages: completedStages ?? this.completedStages,
      stageStars: stageStars ?? this.stageStars,
    );
  }
}