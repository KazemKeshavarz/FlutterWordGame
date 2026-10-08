class PersianTextNormalizer {
  static String normalize(String value) {
    return value
        .replaceAll('ي', 'ی')
        .replaceAll('ى', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('ۀ', 'ه')
        .replaceAll('ة', 'ه')
        .replaceAll('\u0640', '')
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('\u200C', '')
        .trim();
  }
}
