<div align="center">

<img src="assets/icon.png" width="128" alt="Subtext app icon — a floating text replacement panel for macOS">

# Subtext

**A floating, keyboard-first panel for your macOS text replacements.**
Press a shortcut, find your snippet, copy it — gone before you notice it was there.

[![Release](https://img.shields.io/github/v/release/aka-kika/Subtext?style=flat-square&color=6D80A6&label=release)](https://github.com/aka-kika/Subtext/releases/latest)
[![Platform](https://img.shields.io/badge/macOS-14%2B_·_Apple_Silicon-2b2b2b?style=flat-square)](https://github.com/aka-kika/Subtext/releases/latest)
[![Notarized](https://img.shields.io/badge/signed_%26_notarized-Apple-2b2b2b?style=flat-square)](https://github.com/aka-kika/Subtext/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-6D80A6?style=flat-square)](LICENSE)

[Download](https://github.com/aka-kika/Subtext/releases/download/v1.0.0/Subtext-1.0.dmg) · [Releases](https://github.com/aka-kika/Subtext/releases) · [akakika.com](https://akakika.com)

</div>

## Why

macOS text replacements are genuinely useful — and buried four clicks deep in
System Settings. Once you have more than a handful, you end up typing `;docs`
and hoping you remembered the right one. Subtext turns that list into a
Raycast-style overlay: summon it with a global hotkey, type a few letters to
filter, press Enter, and the snippet is on your clipboard.

No new snippet database, no sync service, no subscription. It reads the text
replacements you already have.

## Features

- **Floating panel** — a borderless, non-activating overlay that appears over
  whatever you're doing and disappears on Escape, without stealing your window
  focus.
- **Live from the system** — reads text replacements straight from macOS.
  Add one anywhere (System Settings, `defaults`, another Mac via iCloud) and
  it's in the panel the next time you open it. No relaunch, no manual sync.
- **Keyboard-first** — type to filter, arrow keys to move, Enter to copy.
  Your hands never leave the keyboard.
- **Import and remove** — drop in a `.plist` exported from System Settings,
  or remove a replacement by its shortcut, from inside the app.
- **Three panel sizes, three themes** — Mini / Normal / Big, Dark / Light /
  System.
- **Launch at login, optional menu bar item** — and the menu bar item really
  is optional.

## Install

Download **[Subtext-1.0.dmg](https://github.com/aka-kika/Subtext/releases/download/v1.0.0/Subtext-1.0.dmg)**
(2.2 MB), drag Subtext to Applications, and open it.

The app is signed with a Developer ID and notarized by Apple — it opens
without any Gatekeeper warnings.

**Checksum (SHA-256):**

```
eb504c9c324dd607037e3e77b94f8286e551f4a1cf283b7350bca64fd983e7f8
```

## Usage

1. Launch Subtext and record a global shortcut in Settings (⌘, while the
   panel is open).
2. Press the shortcut anywhere. The panel floats up.
3. Type to filter, ↓ ↑ to navigate, ↵ to copy, ⎋ to dismiss.

That's the whole app.

## FAQ

**What is Subtext?**
A small macOS utility that gives your system text replacements a fast,
searchable, keyboard-driven interface — a snippet launcher for the
replacements you already own.

**Does it replace TextExpander or Raycast snippets?**
No — it complements the built-in macOS text replacement system instead of
introducing another snippet store. Your replacements stay in System Settings
and keep syncing through iCloud to your iPhone and iPad.

**Why don't I see a replacement I just added?**
You will — close and reopen the panel. Subtext re-reads the system list every
time the panel opens.

**Does it work on Intel Macs?**
The prebuilt app is Apple Silicon. On Intel, build from source (below).

**Does it collect anything?**
Nothing. No network calls, no analytics, no accounts. It reads one macOS
preferences key and writes to your clipboard when you ask it to.

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon for the prebuilt download

## Building from source

```
git clone https://github.com/aka-kika/Subtext.git
cd Subtext
swift build -c release
```

`scripts/release.sh` builds, signs, notarizes, and staples the distributable
DMG (requires a Developer ID identity and a notarytool keychain profile).

## Contributing

Bug reports and small focused PRs are welcome —
[open an issue](https://github.com/aka-kika/Subtext/issues).

## License

MIT — see [LICENSE](LICENSE).

Built by **KIKA** ([akakika.com](https://akakika.com) · [@akakikaaa](https://x.com/akakikaaa)).
