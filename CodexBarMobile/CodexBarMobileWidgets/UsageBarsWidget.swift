import AppIntents
import SwiftUI
import WidgetKit

// Research/056 — per-window usage bars with reset countdowns, always dark.

struct UsageBarsWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "CodexBarUsageBarsWidget",
            intent: UsageBarsConfigurationIntent.self,
            provider: UsageBarsTimelineProvider()
        ) { entry in
            UsageBarsWidgetView(entry: entry)
        }
        .configurationDisplayName("Usage Bars")
        .description("Rate-limit bars and reset times for your providers.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Configuration

struct UsageBarsProviderEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Provider"
    static let defaultQuery = UsageBarsProviderQuery()

    /// `CodexBarWidgetProviderSummary.id` ("providerID|account").
    let id: String
    let name: String
    let subtitle: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(self.name)",
            subtitle: self.subtitle.map { "\($0)" })
    }
}

struct UsageBarsProviderQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [UsageBarsProviderEntity] {
        try await self.suggestedEntities().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [UsageBarsProviderEntity] {
        await CodexBarWidgetProvider.fetchSnapshot(now: .now).topProviders
            .filter { !($0.windows ?? []).isEmpty }
            .map { UsageBarsProviderEntity(id: $0.id, name: $0.providerName, subtitle: $0.loginMethod) }
    }
}

struct UsageBarsConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Usage Bars"
    static let description = IntentDescription("Rate-limit bars and reset times for your providers.")

    /// Empty = the provider with the highest usage.
    @Parameter(title: "Provider")
    var provider: UsageBarsProviderEntity?

    init() {}
}

// MARK: - Timeline

struct UsageBarsEntry: TimelineEntry {
    let date: Date
    let providerID: String?
    let snapshot: CodexBarWidgetSnapshot
}

struct UsageBarsTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in _: Context) -> UsageBarsEntry {
        UsageBarsEntry(date: .now, providerID: nil, snapshot: .placeholder())
    }

    func snapshot(for configuration: UsageBarsConfigurationIntent, in context: Context) async -> UsageBarsEntry {
        if context.isPreview {
            return self.placeholder(in: context)
        }
        return await self.entry(for: configuration)
    }

    func timeline(for configuration: UsageBarsConfigurationIntent, in _: Context) async -> Timeline<UsageBarsEntry> {
        let entry = await self.entry(for: configuration)
        return Timeline(entries: [entry], policy: .after(entry.date.addingTimeInterval(15 * 60)))
    }

    private func entry(for configuration: UsageBarsConfigurationIntent) async -> UsageBarsEntry {
        let now = Date()
        return UsageBarsEntry(
            date: now,
            providerID: configuration.provider?.id,
            snapshot: await CodexBarWidgetProvider.fetchSnapshot(now: now))
    }
}

// MARK: - View

struct UsageBarsWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: UsageBarsEntry

    /// Providers with at least one window; the configured one first, then by usage.
    private var providers: [CodexBarWidgetProviderSummary] {
        let all = self.entry.snapshot.topProviders.filter { !($0.windows ?? []).isEmpty }
        guard let id = self.entry.providerID, let chosen = all.first(where: { $0.id == id }) else {
            return all
        }
        return [chosen] + all.filter { $0.id != id }
    }

    var body: some View {
        Group {
            if let first = self.providers.first {
                if self.family == .systemSmall {
                    self.small(first)
                } else {
                    self.medium(Array(self.providers.prefix(3)))
                }
            } else {
                self.empty
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Always dark so ProviderColorPalette resolves its dark-mode (lifted) tints.
        .environment(\.colorScheme, .dark)
        .containerBackground(for: .widget) { Color.black }
    }

    private func small(_ provider: CodexBarWidgetProviderSummary) -> some View {
        let tint = self.tint(provider)
        let windows = provider.windows ?? []
        // `providers` only keeps summaries with at least one window.
        let headline = windows.max { $0.usedPercent < $1.usedPercent }!
        let others = windows.filter { $0 != headline }
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(provider.providerName).font(.caption.bold()).lineLimit(1)
                Spacer(minLength: 4)
                Self.updated(provider.lastUpdated)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(headline.label).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                Spacer(minLength: 4)
                Text(Self.percent(headline.usedPercent))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
                    .minimumScaleFactor(0.7)
            }
            Self.bar(headline.usedPercent, tint: tint, height: 6)
            HStack {
                Text("\(String(localized: "Remaining")) \(Self.percent(100 - headline.usedPercent))")
                Spacer(minLength: 4)
                if let resetsAt = headline.resetsAt {
                    Self.reset(resetsAt)
                }
            }
            .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            Spacer(minLength: 0)
            ForEach(Array(others.prefix(2).enumerated()), id: \.offset) { _, window in
                VStack(spacing: 3) {
                    HStack {
                        Text(window.label).foregroundStyle(.secondary).lineLimit(1)
                        Spacer(minLength: 4)
                        Text(Self.percent(window.usedPercent)).bold().foregroundStyle(tint)
                    }
                    .font(.caption2)
                    Self.bar(window.usedPercent, tint: tint, height: 4)
                }
            }
        }
    }

    private func medium(_ providers: [CodexBarWidgetProviderSummary]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CodexBar").font(.caption2.bold()).foregroundStyle(.secondary)
                Spacer()
                if let latestSyncAt = self.entry.snapshot.latestSyncAt {
                    Self.updated(latestSyncAt)
                }
            }
            ForEach(providers) { provider in
                let tint = self.tint(provider)
                let windows = Array((provider.windows ?? []).prefix(2))
                let headline = windows.max { $0.usedPercent < $1.usedPercent }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(provider.providerName).font(.caption.bold()).lineLimit(1)
                        Spacer(minLength: 4)
                        if let resetsAt = headline?.resetsAt {
                            Self.reset(resetsAt).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Text(windows.map { Self.percent($0.usedPercent) }.joined(separator: " / "))
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(tint)
                    }
                    HStack(spacing: 4) {
                        ForEach(Array(windows.enumerated()), id: \.offset) { _, window in
                            Self.bar(window.usedPercent, tint: tint, height: 6)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "macbook.and.iphone").font(.title3)
            Text(String(localized: "No Data")).font(.caption.bold())
            Text(String(localized: "Open CodexBar on your iPhone after your Mac syncs usage."))
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func tint(_ provider: CodexBarWidgetProviderSummary) -> Color {
        ProviderColorPalette.color(providerID: provider.providerID, tintHex: provider.tintHex)
    }

    /// Static "5 分鐘前"; `.relative` would tick every second.
    private static func updated(_ date: Date) -> some View {
        Text(date, format: .relative(presentation: .named))
            .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
    }

    private static func percent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    private static func bar(_ percent: Double, tint: Color, height: CGFloat) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                if percent > 0 {
                    Capsule().fill(tint)
                        .frame(width: max(height, geometry.size.width * min(percent, 100) / 100))
                }
            }
        }
        .frame(height: height)
    }

    @ViewBuilder
    private static func reset(_ date: Date) -> some View {
        // A past reset would count up; hide it until the next sync.
        if date > .now {
            HStack(spacing: 2) {
                Image(systemName: "clock.arrow.circlepath")
                Text(date, style: .relative)
            }
        }
    }
}
