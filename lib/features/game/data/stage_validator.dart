import '../../../core/utils/persian_text_normalizer.dart';
import '../domain/stage.dart';

/// اعتبارسنجی محتوای مراحل برای جلوگیری از ورود کلمه‌های غیرقابل‌ساخت.
class StageValidator {
  const StageValidator._();

  static List<String> validate(Stage stage) {
    final errors = <String>[];
    final normalizedLetters = stage.letters
        .map(PersianTextNormalizer.normalize)
        .where((letter) => letter.isNotEmpty);
    final letterCounts = _counts(normalizedLetters);

    if (stage.letters.isEmpty) {
      errors.add('مرحله ${stage.id}: هیچ حرفی ندارد.');
    }

    if (stage.words.isEmpty) {
      errors.add('مرحله ${stage.id}: هیچ کلمه‌ای ندارد.');
    }

    final normalizedWords = <String>{};

    for (final rawWord in stage.words) {
      final word = PersianTextNormalizer.normalize(rawWord);

      if (word.isEmpty) {
        errors.add('مرحله ${stage.id}: کلمه خالی است.');
        continue;
      }

      if (!normalizedWords.add(word)) {
        errors.add('مرحله ${stage.id}: کلمه تکراری «$rawWord».');
      }

      final wordCounts = _counts(word.split(''));
      for (final entry in wordCounts.entries) {
        final available = letterCounts[entry.key] ?? 0;
        if (entry.value > available) {
          errors.add(
            'مرحله ${stage.id}: کلمه «$rawWord» با حروف مرحله قابل ساخت نیست '
            '(حرف «${entry.key}» به ${entry.value} عدد نیاز دارد و فقط ${available} عدد وجود دارد).',
          );
        }
      }
    }

    return errors;
  }

  static List<String> validateAll(Iterable<Stage> stages) =>
      stages.expand(validate).toList(growable: false);

  static Map<String, int> _counts(Iterable<String> values) {
    final counts = <String, int>{};
    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    return counts;
  }
}
