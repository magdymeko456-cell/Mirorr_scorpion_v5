# Mirror Scorpion v5

Mirror Scorpion v5 is the controlled rebuild of the Mirror Scorpion Flutter application. The repository is seeded from the last verified `mirror_scorpion_v4` baseline so that repairs can be made incrementally without losing the existing interface, icon, content assets, or working feature contracts.

## Repair policy

Every change must follow this order:

1. Inspect the real file paths and current dependency versions.
2. Make one focused change.
3. Run the available build and test checks.
4. Commit only after the check passes.
5. Continue to the next change only from the verified commit.

Do not apply generated or speculative patches to files that have not been inspected. Do not replace a newer dependency with an older one to hide an API mismatch. Update application code to match the declared, compatible dependency versions.

Run the local gate from the repository root:

```bash
./scripts/repair_gate.sh
./scripts/repair_gate.sh --check
```

The second command runs `flutter pub get`, `flutter analyze`, and `flutter test` when Flutter is installed. In environments without Flutter it still checks the repository structure and scans for common accidentally committed credentials.

## Termux isolated checkout

Do not paste the contents of a script directly into the shell. Pasting removes the script's file context, so variables such as `BASH_SOURCE` may be empty and the command can resolve the project root as `/`. Download or copy `termux_setup_mirror_scorpion_v5.sh`, then execute it as a file:

```bash
bash termux_setup_mirror_scorpion_v5.sh
cd "$HOME/Mirorr_scorpion_v5"
bash scripts/repair_gate.sh --check
```

The setup script creates exactly one isolated directory at `$HOME/Mirorr_scorpion_v5`, verifies that an existing directory points to the correct repository, and refuses to mix it with another checkout.

## Initial baseline

The initial v5 baseline is copied from the latest v4 `main` commit, whose current head is the independent dialogue microphone workflow. The key language contract is:

- The device locale determines the default language shown on the right side of the dialogue translator.
- The microphone uses the language currently displayed on the right/source control.
- The left/target language is selected independently by the user.
- Swapping the two language controls updates the source language used by the microphone.
- The last translation language choices remain persistent.

## Planned implementation order

The first stabilization phase is translation and dialogue microphone behavior. The next phases are document/lens translation, system TTS and audio sharing, content/data verification, chess UI and engine behavior, overlay integration, and finally optional PRO services. AI video generation, cloud activation, payments, and floating overlays remain explicitly gated until their contracts, permissions, privacy behavior, and tests are complete.

## Security note

Never commit GitHub personal access tokens, API keys, activation secrets, or private signing material. Any token pasted into chat, a terminal, an issue, or a public repository must be revoked and replaced immediately. Runtime credentials belong in the deployment environment or GitHub Actions secrets, not in source files.

## License and content

Before shipping bundled religious, literary, voice, chess, or image content, verify its provenance, license, attribution, and redistribution rights. Content references must not silently download or expose unlicensed material.
