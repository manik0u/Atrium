/// Lightweight, dependency-free localization runtime for Atrium.
///
/// All user-visible strings live in per-language tables (see
/// `strings_en.dart`, `strings_fr.dart`) keyed by a stable slug. Widget and
/// non-widget code alike call [S.t] with the key; the active language is a
/// process-wide setting ([S.setLanguageCode]) resolved by the app shell from
/// the persisted preference (or the system locale), and the app root is
/// re-keyed on change so every [S.t] call re-evaluates.
///
/// Adding a language = adding one more `strings_xx.dart` table plus one
/// entry in [S.supportedLanguageCodes].
library;

import 'strings_en.dart';
import 'strings_fr.dart';

/// Localization runtime: string tables + active language.
final class S {
  S._();

  /// Language codes with a complete string table, source language first.
  static const List<String> supportedLanguageCodes = <String>['en', 'fr'];

  static const Map<String, Map<String, String>> _tables =
      <String, Map<String, String>>{
    'en': atriumStringsEn,
    'fr': atriumStringsFr,
  };

  static String _languageCode = 'en';

  /// Currently active language code (defaults to English until the app shell
  /// resolves the preference / system locale).
  static String get languageCode => _languageCode;

  /// Sets the active language. Unknown codes are ignored.
  static void setLanguageCode(String code) {
    if (_tables.containsKey(code)) {
      _languageCode = code;
    }
  }

  /// Resolves [code] against [supportedLanguageCodes], falling back to
  /// [fallback] (itself falling back to English). Used for the "system"
  /// preference.
  static String resolveLanguageCode(String? code, String fallback) {
    if (code != null && _tables.containsKey(code)) return code;
    if (_tables.containsKey(fallback)) return fallback;
    return 'en';
  }

  /// Looks up [key] in the active language, falling back to English, then to
  /// the key itself. Positional [args] replace `{0}`, `{1}`, ... in order.
  static String t(String key, [List<Object?> args = const <Object?>[]]) {
    final Map<String, String> table =
        _tables[_languageCode] ?? atriumStringsEn;
    String value = table[key] ?? atriumStringsEn[key] ?? key;
    for (int i = 0; i < args.length; i++) {
      value = value.replaceAll('{$i}', args[i].toString());
    }
    return value;
  }
}
