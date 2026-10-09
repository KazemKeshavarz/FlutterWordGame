import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_word_game/features/game/data/local_stage_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStageRepository', () {
    test('loads all stages from the bundled JSON and validates them', () async {
      final repository = LocalStageRepository();

      await repository.load();

      expect(repository.stages, hasLength(35));
      expect(repository.stages.first.id, 1);
      expect(repository.stages.last.id, 35);
      expect(repository.getStage(6).letters, contains('د'));
    });

    test('does not expose a mutable stage list', () async {
      final repository = LocalStageRepository();
      await repository.load();

      expect(
        () => repository.stages.clear(),
        throwsUnsupportedError,
      );
    });
  });
}
