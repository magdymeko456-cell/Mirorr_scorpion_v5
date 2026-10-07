import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/localization/app_locale_policy.dart';

void main() {
  const supported = <Locale>[Locale('en'), Locale('ar')];

  test('keeps a translated device language', () {
    expect(
      resolveMirrorScorpionLocale(
        requested: const Locale('ar', 'EG'),
        supported: supported,
      ),
      const Locale('ar'),
    );
  });

  test('uses an exact translated locale when available', () {
    expect(
      resolveMirrorScorpionLocale(
        requested: const Locale('en'),
        supported: supported,
      ),
      const Locale('en'),
    );
  });

  test('falls back to English for an untranslated device language', () {
    expect(
      resolveMirrorScorpionLocale(
        requested: const Locale('fr', 'FR'),
        supported: supported,
      ),
      const Locale('en'),
    );
  });
}
