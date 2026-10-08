import '../domain/stage.dart';

class LocalStageRepository {
  static const _stages = <Stage>[
    Stage(
      id: 1,
      letters: ['س', 'ا', 'ع', 'ت'],
      words: ['ساعت', 'تاس'],
    ),
  ];

  Stage getStage(int id) {
    return _stages.firstWhere((stage) => stage.id == id);
  }
}
