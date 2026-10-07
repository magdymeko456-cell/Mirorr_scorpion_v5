# Global localization policy

Mirror Scorpion is not Arabic-only. The application UI must follow the user's device language whenever a translated resource exists.

## Resolution contract

1. Use the device locale as the requested locale.
2. Prefer an exact translated locale.
3. If only the language is translated, ignore the device region (`ar-EG` uses `ar`).
4. If the language is not translated yet, use English as the deterministic fallback.
5. Never use Arabic text as an implicit fallback for an untranslated UI string.

The policy is implemented in `lib/core/localization/app_locale_policy.dart` and applied by `MirrorScorpionApp`.

## UI rules

- All card names, subtitles, settings labels, dialogs, snackbars, tooltips, and technical status messages must come from `AppLocalizations`.
- User data, model names, package IDs, app/platform names, and chess notation are not UI translations and may remain data-driven.
- Language codes used for translation engines are independent from the UI locale. A user may have an English UI while translating Arabic to Japanese.
- When adding a language, add its ARB file, regenerate Flutter localizations in CI, add it to `kTranslatedMirrorScorpionLocales`, and add a locale-resolution test.

## Current coverage

- English, Arabic, French, Spanish, German, Turkish, Portuguese, Simplified
  Chinese, Japanese, and Hindi: available in the local ARB bundle.
- Other device languages: English fallback until their ARB resources are added.

This fallback is intentional: it prevents a device set to an unsupported language from receiving a partially translated interface.
