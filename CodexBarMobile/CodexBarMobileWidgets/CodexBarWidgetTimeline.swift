import CodexBarSync
import WidgetKit

struct CodexBarWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in _: Context) -> CodexBarWidgetEntry {
        CodexBarWidgetEntry(
            date: .now,
            configuration: CodexBarWidgetConfigurationIntent(mode: .overview),
            snapshot: .placeholder())
    }

    func snapshot(
        for configuration: CodexBarWidgetConfigurationIntent,
        in context: Context
    ) async -> CodexBarWidgetEntry {
        if context.isPreview {
            return CodexBarWidgetEntry(
                date: .now,
                configuration: configuration,
                snapshot: .placeholder())
        }
        return CodexBarWidgetEntry(
            date: .now,
            configuration: configuration,
            snapshot: .syncing())
    }

    func timeline(
        for configuration: CodexBarWidgetConfigurationIntent,
        in _: Context
    ) async -> Timeline<CodexBarWidgetEntry> {
        let now = Date()
        let snapshot = await Self.fetchSnapshot(now: now)
        let entry = CodexBarWidgetEntry(
            date: now,
            configuration: configuration,
            snapshot: snapshot)
        let refreshInterval: TimeInterval = switch snapshot.state {
        case .loaded: 15 * 60
        case .placeholder, .syncing: 5 * 60
        case .noData, .error: 10 * 60
        }
        return Timeline(
            entries: [entry],
            policy: .after(now.addingTimeInterval(refreshInterval)))
    }

    static func fetchSnapshot(now: Date) async -> CodexBarWidgetSnapshot {
        #if targetEnvironment(simulator)
        if ProcessInfo.processInfo.environment["CODEXBAR_WIDGET_DISABLE_SIMULATOR_MOCK"] != "1" {
            return .simulatorMock(now: now)
        }
        #endif
        let syncManager = CloudSyncManager.shared
        async let result = syncManager.fetchAllDeviceSnapshots()
        async let providerLinkages = syncManager.fetchProviderAccountLinkages()
        async let deviceLifecycleEvents = syncManager.fetchDeviceLifecycleEvents()
        let fallback = syncManager.fetchKVSSnapshot()
        let syncResult = await result
        let linkages = await providerLinkages
        let lifecycleEvents = await deviceLifecycleEvents
        return CodexBarWidgetSnapshotBuilder.makeSnapshot(
            from: syncResult,
            fallbackKVSSnapshot: fallback,
            providerLinkages: linkages,
            deviceLifecycleEvents: lifecycleEvents,
            now: now)
    }
}
