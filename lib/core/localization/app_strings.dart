import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/locale_provider.dart';
import 'chinese_strings.dart';
import 'english_strings.dart';
import 'malay_strings.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': EnglishStrings.strings,
    'ms': MalayStrings.strings,
    'zh': ChineseStrings.strings,
  };

  /// Translate key according to active language code
  static String tr(String key, String languageCode) {
    return _localizedValues[languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

/// Riverpod Extension for quick access in UI widgets via `ref.tr('key')`
extension TranslationX on WidgetRef {
  String tr(String key) {
    final locale = watch(localeProvider);
    return AppStrings.tr(key, locale.languageCode);
  }
}