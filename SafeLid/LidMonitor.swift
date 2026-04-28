#if os(macOS)
import AppKit
import Foundation
import IOKit

final class LidMonitor {
    var onPotentialClamshellSleep: (() -> Void)?
    var onUnlockedSession: (() -> Void)?

    private var observers: [NSObjectProtocol] = []

    func start() {
        stop()

        let workspaceCenter = NSWorkspace.shared.notificationCenter

        let willSleep = workspaceCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePotentialClamshellTransition()
        }

        let didWake = workspaceCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleWake()
        }

        let unlocked = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onUnlockedSession?()
        }

        observers = [willSleep, didWake, unlocked]
    }

    func stop() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        observers.forEach { observer in
            workspaceCenter.removeObserver(observer)
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        observers.removeAll()
    }

    deinit {
        stop()
    }

    private func handlePotentialClamshellTransition() {
        guard isClamshellClosed() else { return }
        onPotentialClamshellSleep?()
    }

    private func handleWake() {
        // No-op: the unlock notification is what disarms the trap.
    }

    private func isClamshellClosed() -> Bool {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard service != 0 else { return false }
        defer { IOObjectRelease(service) }

        guard let value = IORegistryEntryCreateCFProperty(
            service,
            "AppleClamshellState" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? CFBoolean else {
            return false
        }

        return value.boolValue
    }
}
#endif
