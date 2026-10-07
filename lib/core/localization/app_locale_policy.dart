import 'dart:ui';

/// Locale policy for the whole application:
///
/// 1. Prefer an exact device locale when it is translated.
/// 2. Prefer the translated language, even when the device has a region
///    variant such as en-GB or ar-EG.
/// 3. Use English as the deterministic fallback for currently untranslated
///    device languages.
Locale resolveMirrorScorpionLocale({
  required Locale? requested,
  required Iterable<Locale> supported,
  Locale fallback = const Locale('en'),
}) {
  final locales = supported.toList(growable: false);
  if (requested == null || locales.isEmpty) return fallback;

  for (final locale in locales) {
    if (locale == requested) return locale;
  }
  for (final locale in locales) {
    if (locale.languageCode.toLowerCase() ==
        requested.languageCode.toLowerCase()) {
      return locale;
    }
  }
  return locales.any((locale) => locale == fallback) ? fallback : locales.first;
}

/// Keep this list in the same order as the generated ARB files. Adding a new
/// translated ARB automatically becomes a supported UI language here.
const List<Locale> kTranslatedMirrorScorpionLocales = <Locale>[
  Locale('en'),
  Locale('ar'),
];
