import Foundation

#if os(macOS)
import SwiftUI

@main
struct SafeLidApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
#else
@main
struct SafeLidLinuxFallback {
    static func main() {
        print("SafeLid is a macOS-only app.")
    }
}
#endif
