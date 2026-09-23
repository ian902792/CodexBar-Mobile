import Foundation

enum AppVersion {
    static let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""

    static var displayString: String {
        let version = self.shortVersion.isEmpty ? "–" : self.shortVersion
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        var result = build.map { "\(version) (\($0))" } ?? version
        // Fork builds ship a paired iOS companion version; show it everywhere the
        // Mac version is shown.
        if let mobile = Bundle.main.object(forInfoDictionaryKey: "CodexMobileVersion") as? String {
            result += " · Mobile \(mobile)"
        }
        return result
    }
}
