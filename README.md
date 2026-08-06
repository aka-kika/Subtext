# Subtext

A floating, keyboard-first macOS app that lists your system text replacements. Press a global shortcut, find what you need, copy it — no more typing `;docs` and hoping you remember.

## Features

- **Floating panel** — Raycast-style overlay, summoned with a global hotkey
- **Live from system** — reads your text replacements directly from System Settings
- **Keyboard-first** — type to filter, arrow keys to navigate, Enter to copy
- **Three sizes** — Mini / Normal / Big
- **Themes** — Dark, Light, System
- **Launch at login** — always ready
- **Customizable shortcut** — record any key combo to summon the panel

## How to build

1. Open `Subtext.xcodeproj` in Xcode 15+
2. Select your team for signing
3. Build & Run (⌘R)

## How to use

1. Launch Subtext — it lives in the menu bar
2. Press your global shortcut (default: not set — configure in Settings)
3. The floating panel appears. Type to filter, ↓↑ to navigate, ↵ to copy
4. Press ⎋ to dismiss

## Settings

Open Settings from the menu bar or with ⌘, while the panel is open.

- **Theme**: Dark / Light / System
- **Panel Size**: Mini / Normal / Big
- **Shortcut**: Click the recorder, type your combo
- **Launch at login**: Toggle
- **Show in menu bar**: Toggle

## Importing from System Settings

1. Open System Settings → Keyboard → Text Replacements
2. Select all your replacements, drag them to the Finder to export a `.plist`
3. The app reads from the system automatically — no import needed

## Architecture

Built following Tinycast's patterns:
- `NSPanel` subclass for the floating window (non-activating, borderless)
- `Carbon.HIToolbox` `RegisterEventHotKey` for global shortcuts
- `NSVisualEffectView` for Liquid Glass materials
- `@MainActor` AppCore singleton
- SwiftUI throughout
