chore(deps): upgrade direct dependencies to patched/resolvable versions (security & compatibility)

Summary
- Upgrades multiple direct dependencies to address Dependabot-reported vulnerabilities and ensure compatibility with the current Flutter SDK (3.35.7 / Dart 3.9.2).
- Key direct upgrades: firebase_core 3.4.0 -> 4.2.1, firebase_auth 5.2.0 -> 6.1.2, cloud_firestore 5.4.0 -> 6.1.0, fl_chart 0.71.0 -> 1.1.1, font_awesome_flutter 10.9.0 -> 10.12.0, google_fonts 6.3.2, json_path 0.8.0, page_transition 2.2.1, timeago 3.7.1, provider 6.1.5+1, collection 1.19.1, plus others.

Why
- GitHub Dependabot reported multiple vulnerabilities on the default branch. These upgrades bring direct dependencies to patched/resolvable versions and reduce security exposure.

What I changed
- Updated `pubspec.yaml` and resolved dependencies (see commit history on this branch).
- Fixed one Flutter SDK API change (ThemeData.cardTheme now expects `CardThemeData`) so the app builds on the upgraded SDK.

Testing performed
- `flutter pub get` completed successfully.
- `flutter run -d chrome` compiled and launched the app; initial UI rendered without compile errors.

Recommended post-merge checks (manual QA)
- Run locally: `flutter pub get` then `flutter run -d chrome` and verify the app starts.
- Verify authentication flows (login/signup) with a Firebase test project.
- Open pages that use `fl_chart`, `rive`, and other upgraded packages to confirm no runtime issues.
- Run any existing widget/integration tests.

Notes & follow-ups
- There remain transitive/upgradable packages reported by `flutter pub outdated`. We can follow up with additional PRs to pursue those upgrades.
- GitHub reported 14 vulnerabilities on the default branch previously; merging this PR and re-running GitHub security scans will show which alerts are resolved.
- If you prefer, I can continue with deeper QA (exercise Firestore reads/writes, charts) and fix any runtime breakages before merge.

Checklist
- [x] Branch `upgrade/major-deps` created and pushed
- [x] Direct dependencies bumped and committed
- [x] Local smoke tests performed
- [ ] Deeper QA (optional)
- [ ] Merge after review
