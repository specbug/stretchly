# Stretchly for iPad

A native SwiftUI build of *Stretchly* for iPadOS 17 and later. It shares the desktop app's translations, break ideas, fonts, sounds, icons and themes. Those files stay where they are in `app/` and are copied into the iPad build when the Xcode project is generated.

## Building

Requirements: macOS with Xcode 16 or later, [XcodeGen](https://github.com/yonaskolb/XcodeGen) and the Node.js version from `package.json`.

```sh
brew install xcodegen
cd ios
xcodegen
open Stretchly.xcodeproj
```

`xcodegen` runs `scripts/sync-shared.mjs` first. The script copies `app/locales`, the Noto Sans fonts, the break sounds and the SVG icons into `Stretchly/Generated`, and draws the app icon from `app/images/stretchly.svg`. Run `xcodegen` again after changing any of those files. `Stretchly/Generated` and the `.xcodeproj` are not committed.

To run on a device, choose your team under *Signing & Capabilities*.

The break schedule, postpone and skip rules, translations and plural rules live in the `StretchlyCore` Swift package. It depends only on Foundation and has its own tests:

```sh
cd ios/StretchlyCore
swift test
```

## How it differs from the desktop app

iPadOS does not let an app draw over other apps or keep a timer running in the background. So the iPad build plans breaks ahead of time and hands them to the system:

- Each break is a local notification. Up to 60 are scheduled, covering at most the next 12 hours. The schedule is refreshed whenever Stretchly is opened or a notification is answered.
- When a break starts while Stretchly is open, the full break screen appears, the same as on desktop. When Stretchly is in the background, tapping the notification opens the break screen with the time remaining. The notification also offers *Postpone this break* while postponing is allowed.
- The break sound plays with the notification, since that is the only signal while Stretchly is in the background. When Stretchly is open, the sound plays when the break ends, as on desktop.
- *Show breaks even in Do Not Disturb mode* sends breaks as Time Sensitive notifications, which can come through a Focus.
- *Strict mode* hides the option to skip a break, but iPadOS cannot keep you from leaving the app.
- Hardware keyboard: `⌘X` postpones or skips the current break, like the desktop shortcut, and `⌘,` opens Preferences.

Not available on iPad: natural breaks (idle detection), app exclusions, multiple monitors, the tray icon, start at login, transparency, update checks and Contributor Preferences.

## Layout

```
ios/
  project.yml                XcodeGen spec (iPad only, TARGETED_DEVICE_FAMILY 2)
  scripts/sync-shared.mjs    copies shared resources from app/ into the build
  StretchlyCore/             schedule, rules, translations (Foundation only, tested)
  Stretchly/                 SwiftUI app: home, break screen, welcome, preferences
```

Adding iPhone support later should mostly mean setting `TARGETED_DEVICE_FAMILY` to `1,2` and adapting the layouts. It does not need a second codebase.
