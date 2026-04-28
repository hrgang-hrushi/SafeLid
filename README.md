# SafeLid

SafeLid is a lightweight macOS menu bar app that arms a trap, locks the current session, watches for a clamshell sleep transition, and plays a looping alarm until the user unlocks the desktop again.

## Part 1: Xcode setup

1. Open Xcode and create a new **macOS App** project named `SafeLid`.
2. Set the interface to **SwiftUI** and the life cycle to **SwiftUI App**.
3. Delete the generated SwiftUI content view if Xcode creates one; this app does not need a window.
4. Add the source files from the `SafeLid/` folder in this repository to the target.
5. In the target’s **Info** settings, add `Application is agent (UIElement)` and set it to `YES` so the app has no Dock icon.
6. If you are using the `Info.plist` from this repo, make sure the target points to it.
7. Build and run once from Xcode. The menu bar item should appear immediately.
8. Click **Arm Alarm**. The app will lock the screen and wait for a lid-close sleep transition.
9. When the lid closes, the alarm volume is driven to maximum and the siren loops until the desktop is unlocked.

## Part 1b: Create a DMG for installation

1. Build the app in Xcode so you have a `SafeLid.app` bundle in your Release build folder.
2. Run the packaging script in this repo from macOS:

```bash
bash ./scripts/build-dmg.sh \
	--app "path/to/SafeLid.app" \
	--output "dist/SafeLid.dmg"
```

3. Open the DMG on your MacBook and drag `SafeLid.app` into `Applications`.
4. Launch SafeLid from Launchpad or Spotlight.
5. If macOS warns that the app is from an unidentified developer, right-click the app once and choose Open.

## Part 1c: Build on GitHub Actions instead of Xcode

1. Push the repository to GitHub.
2. Let the `Build DMG` workflow run on the `macos-14` runner.
3. Download the `SafeLid-dmg` artifact from the workflow run.
4. Open the DMG on your MacBook and drag the app to `Applications`.
5. This route does not require Xcode on your local machine.

## Part 2: Swift code

Create these files under a `SafeLid/` folder in the project:

- `SafeLidApp.swift`
- `AppDelegate.swift`
- `LidMonitor.swift`
- `AlarmController.swift`
- `Info.plist`

The complete source is included in the repository files alongside this README.

## Part 3: How lid-close detection works

The app does not try to read the hinge directly. Instead, it watches the system sleep transition with `NSWorkspace.willSleepNotification`, then queries IOKit for `AppleClamshellState` on the power-management root domain. If the machine is going to sleep because the lid closed, that property is `true`, and the alarm is triggered.

When the user later unlocks the session, `com.apple.screenIsUnlocked` is observed and the app disarms itself and stops audio playback. The alarm sound itself is generated as a local WAV file the first time the app runs, then played with `AVAudioPlayer` in a loop.

## Files

- `SafeLid/SafeLidApp.swift`
- `SafeLid/AppDelegate.swift`
- `SafeLid/LidMonitor.swift`
- `SafeLid/AlarmController.swift`
- `SafeLid/Info.plist`

## Packaging

- `scripts/build-dmg.sh`

## GitHub Actions

- `.github/workflows/build-dmg.yml`
- `Package.swift`

