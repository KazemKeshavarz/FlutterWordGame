import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_word_game/features/game/data/stage_validator.dart';
import 'package:flutter_word_game/features/game/domain/stage.dart';

void main() {
  group('StageValidator', () {
    test('accepts words constructible from normalized Persian letters', () {
      const stage = Stage(
        id: 1,
        letters: ['ك', 'ت', 'ا', 'ب'],
        words: ['کتاب', 'تاب', 'با'],
      );

      expect(StageValidator.validate(stage), isEmpty);
    });

    test('rejects a word that needs more copies of a letter than available', () {
      const stage = Stage(
        id: 2,
        letters: ['د', 'و', 'س', 'ت', 'د'],
        words: ['دوست', 'ددد'],
      );

      final errors = StageValidator.validate(stage);
      expect(errors, hasLength(1));
      expect(errors.single, contains('ددد'));
      expect(errors.single, contains('مرحله 2'));
    });

    test('detects duplicate words after Persian normalization', () {
      const stage = Stage(
        id: 3,
        letters: ['ک', 'ت', 'ا', 'ب'],
        words: ['کتاب', 'كِتاب'],
      );

      final errors = StageValidator.validate(stage);
      expect(errors, hasLength(1));
      expect(errors.single, contains('تکراری'));
    });

    test('rejects empty stages and empty words', () {
      const stage = Stage(id: 4, letters: [], words: ['']);

      final errors = StageValidator.validate(stage);
      expect(errors, hasLength(2));
      expect(errors.join(' '), contains('هیچ حرفی ندارد'));
      expect(errors.join(' '), contains('هیچ کلمه‌ای ندارد'));
      expect(errors.join(' '), contains('کلمه خالی است'));
    });
  });
}
