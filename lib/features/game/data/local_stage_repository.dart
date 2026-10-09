import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/stage.dart';
import 'stage_validator.dart';

/// بارگذاری و اعتبارسنجی مرحله‌ها از فایل JSON محلی.
class LocalStageRepository {
  List<Stage> _stages = const [];

  List<Stage> get stages => List.unmodifiable(_stages);

  Future<void> load() async {
    final source = await rootBundle.loadString('assets/data/stages.json');
    final decoded = jsonDecode(source);

    if (decoded is! List) {
      throw const FormatException('ساختار فایل مراحل باید یک آرایه JSON باشد.');
    }

    final loadedStages = decoded.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('ساختار یکی از مرحله‌ها معتبر نیست.');
      }

      final id = item['id'];
      final letters = item['letters'];
      final words = item['words'];

      if (id is! int || letters is! List || words is! List) {
        throw const FormatException('شناسه، حروف یا کلمات یکی از مرحله‌ها معتبر نیست.');
      }

      return Stage(
        id: id,
        letters: letters.map((value) => value.toString()).toList(growable: false),
        words: words.map((value) => value.toString()).toList(growable: false),
      );
    }).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    if (loadedStages.isEmpty) {
      throw const FormatException('هیچ مرحله‌ای در فایل مراحل تعریف نشده است.');
    }

    final ids = loadedStages.map((stage) => stage.id).toSet();
    if (ids.length != loadedStages.length || loadedStages.any((stage) => stage.id < 1)) {
      throw const FormatException('شناسه مرحله‌ها باید یکتا و مثبت باشد.');
    }

    final errors = StageValidator.validateAll(loadedStages);
    if (errors.isNotEmpty) {
      throw FormatException(
        'محتوای فایل مراحل مشکل دارد:\n${errors.join('\n')}',
      );
    }

    _stages = List.unmodifiable(loadedStages);
  }

  Stage getStage(int id) {
    return _stages.firstWhere(
      (stage) => stage.id == id,
      orElse: () => throw ArgumentError.value(id, 'id', 'مرحله‌ای با این شناسه وجود ندارد.'),
    );
  }
}
