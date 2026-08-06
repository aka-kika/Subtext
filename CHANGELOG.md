<!--
Changelog Template — PER PROJECT
Keep at the repo root as CHANGELOG.md. This is the cumulative history of the
project. Append to [Unreleased] as you work; on release, rename that block to the
version + date and start a fresh [Unreleased]. Distinct from per-release notes:
this is the running ledger, newest version at the top.
Format follows Keep a Changelog; versions follow Semantic Versioning.
Style: no emojis. Monochrome. SF Symbol names noted in comments, not rendered.
Group changes under: Added / Changed / Deprecated / Removed / Fixed / Security.
-->

# Changelog

All notable changes to Subtext are recorded here.
Format: [Keep a Changelog](https://keepachangelog.com). Versioning: [SemVer](https://semver.org).

## [Unreleased]

## [1.0.0] — 2026-08-06

<!-- SF Symbol: shippingbox -->
### Added
- Floating, keyboard-first panel listing all system text replacements:
  type to filter, arrows to navigate, Enter to copy, Escape to dismiss.
- Global hotkey with an in-app recorder.
- Import replacements from a System Settings `.plist` export; remove
  entries by shortcut.
- Three panel sizes (Mini / Normal / Big) and Dark / Light / System themes.
- Launch at login and an optional menu bar item.
- About tab with version and project links.
- Release pipeline: Developer ID signing, two-pass Apple notarization,
  stapled DMG (`scripts/release.sh`).

### Fixed
- Replacements added while the app was running never appeared until
  relaunch (per-process caching of the global defaults domain; the list
  is now read fresh on every panel open).

[Unreleased]: https://github.com/aka-kika/Subtext/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/aka-kika/Subtext/releases/tag/v1.0.0
