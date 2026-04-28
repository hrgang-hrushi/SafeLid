#if os(macOS)
import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let alarmController = AlarmController()
    private let lidMonitor = LidMonitor()
    private var statusItem: NSStatusItem!
    private var isArmed = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configureMonitoring()
        refreshMenu()
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "SafeLid")
            button.imagePosition = .imageLeft
            button.title = "SafeLid"
        }

        let menu = NSMenu()
        menu.autoenablesItems = false
        statusItem.menu = menu
    }

    private func configureMonitoring() {
        lidMonitor.onPotentialClamshellSleep = { [weak self] in
            self?.triggerAlarmIfNeeded()
        }

        lidMonitor.onUnlockedSession = { [weak self] in
            self?.disarm(stopAudio: true)
        }

        lidMonitor.start()
    }

    private func refreshMenu() {
        guard let menu = statusItem.menu else { return }
        menu.removeAllItems()

        let armTitle = isArmed ? "Armed" : "Arm Alarm"
        let armItem = NSMenuItem(title: armTitle, action: #selector(handleArmToggle), keyEquivalent: "")
        armItem.target = self
        armItem.isEnabled = !isArmed
        menu.addItem(armItem)

        let disarmItem = NSMenuItem(title: "Disarm", action: #selector(handleDisarmToggle), keyEquivalent: "")
        disarmItem.target = self
        disarmItem.isEnabled = isArmed
        menu.addItem(disarmItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit SafeLid", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func handleArmToggle() {
        guard !isArmed else { return }
        isArmed = true
        refreshMenu()
        lockSessionImmediately()
    }

    @objc private func handleDisarmToggle() {
        disarm(stopAudio: true)
    }

    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }

    private func triggerAlarmIfNeeded() {
        guard isArmed else { return }
        alarmController.startAlarm()
        refreshMenu()
    }

    private func disarm(stopAudio: Bool) {
        guard isArmed else { return }
        isArmed = false

        if stopAudio {
            alarmController.stopAlarm()
        }

        refreshMenu()
    }

    private func lockSessionImmediately() {
        let lockCommand = "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
        let task = Process()
        task.executableURL = URL(fileURLWithPath: lockCommand)
        task.arguments = ["-suspend"]
        try? task.run()
    }
}
#endif
