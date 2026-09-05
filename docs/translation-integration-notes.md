# Translation Integration Notes

## Expo Localization

Source: `/home/ubuntu/mirror_scorpion_mobile_v3_helper/docs/system/localization/DOCS.md` (Expo SDK 54 documentation mirror).

The documented package is `expo-localization`. `getLocales()` and `useLocales()` expose the preferred device locale. Android locale settings can change while the app is running, so the app should refresh locale data when returning to the foreground. The config plugin is added through `"expo-localization"` in the Expo plugins array.

## Expo DocumentPicker

Source: `/home/ubuntu/mirror_scorpion_mobile_v3_helper/docs/storage/document-picker/DOCS.md` (Expo SDK 54 documentation mirror).

The documented package is `expo-document-picker`. File selection must handle `result.canceled` before reading `result.assets`. `copyToCacheDirectory: true` allows immediate access by filesystem APIs. The picker supports MIME filters such as `audio/*`. On web, `base64: true` can provide the file data; on native, a cache URI can be read using Expo FileSystem.

## Server voice transcription

Source: `/home/ubuntu/mirror_scorpion_mobile_v3/server/_core/voiceTranscription.ts` and `/home/ubuntu/skills/webdev-readme-mobile-backend/SKILL.md`.

The preconfigured transcription helper accepts a publicly reachable audio URL, supports webm, mp3, wav, ogg, and m4a, and enforces a 16 MB limit before calling the internal Whisper-compatible service. The implemented server flow uploads bytes with `storagePut`, obtains a signed URL with `storageGetSignedUrl`, transcribes the audio, then translates the transcript with the server-side `invokeLLM` helper.

## Scope boundary

A true cross-application Android overlay requires native overlay permission and platform-specific integration. The current implementation provides an in-app floating translator with paste input and system sharing; it does not claim to overlay arbitrary third-party apps. Real paid subscriptions require selecting a billing provider and configuring store product identifiers; the settings screen currently presents the plans and explicitly reports that no charge is performed until that provider configuration exists.
