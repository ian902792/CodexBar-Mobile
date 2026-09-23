import Foundation

/// Display preferences the app mirrors into the shared App Group so the
/// widget extension (a separate process) renders the same way.
enum WidgetDisplayPreferences {
    static let appGroupID = "group.com.ian902792.codexbar.mobile"
    private static let showRemainingUsageKey = "showRemainingUsage"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: self.appGroupID)
    }

    static var showRemainingUsage: Bool {
        get { self.defaults?.bool(forKey: self.showRemainingUsageKey) ?? false }
        set { self.defaults?.set(newValue, forKey: self.showRemainingUsageKey) }
    }
}
