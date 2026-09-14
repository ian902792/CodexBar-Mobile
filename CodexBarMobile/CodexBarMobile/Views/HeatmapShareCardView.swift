import CodexBarSync
import SwiftUI

enum HeatmapShareWindow: Int, CaseIterable, Identifiable {
    case days90 = 90
    case days180 = 180
    case days365 = 365

    var id: Int {
        self.rawValue
    }

    var displayName: String {
        switch self {
        case .days90: String(localized: "Past 90 Days")
        case .days180: String(localized: "Past 180 Days")
        case .days365: String(localized: "Past Year")
        }
    }
}

struct HeatmapShareData {
    struct Day: Identifiable {
        let date: Date
        let dayKey: String
        let tokens: Int?
        let isLowerBound: Bool

        var id: String {
            self.dayKey
        }
    }

    let sourceTitle: String
    let window: HeatmapShareWindow
    let days: [Day]
    let color: Color
    let total: TokenActivityTotal
    let activeDays: Int
    let peakTokens: Int?

    var calendarBlocks: [[Day]] {
        guard self.window == .days365 else { return [self.days] }
        let split = self.days.count / 2
        return [Array(self.days[..<split]), Array(self.days[split...])]
    }

    init(
        series: [TokenActivitySeries],
        sourceTitle: String,
        window: HeatmapShareWindow,
        color: Color,
        referenceDate: Date,
        calendar: Calendar = .current)
    {
        // CloudKit daily points always use Gregorian yyyy-MM-dd keys. Keep the
        // reader's time zone for the visual day boundary, but never let a
        // user-selected calendar change the key namespace used for lookups.
        var projectionCalendar = Calendar(identifier: .gregorian)
        projectionCalendar.timeZone = calendar.timeZone
        let end = projectionCalendar.startOfDay(for: referenceDate)
        let start = projectionCalendar.date(byAdding: .day, value: -(window.rawValue - 1), to: end)!
        let totals = TokenActivity.dailyTotals(series)
        self.sourceTitle = sourceTitle
        self.window = window
        self.color = color
        self.days = (0..<window.rawValue).compactMap { offset in
            guard let date = projectionCalendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let key = TokenActivity.dayKey(date, calendar: projectionCalendar)
            let value = totals[key]
            return Day(
                date: date,
                dayKey: key,
                tokens: value?.value,
                isLowerBound: value?.isLowerBound == true)
        }
        let known = self.days.compactMap(\.tokens)
        let sum = SyncCounterMath.saturatingSum(known)
        let incomplete = self.days.contains { $0.tokens == nil || $0.isLowerBound }
        self.total = TokenActivityTotal(
            value: known.isEmpty ? nil : sum,
            isLowerBound: !known.isEmpty && incomplete)
        self.activeDays = known.count(where: { $0 > 0 })
        self.peakTokens = known.max()
    }

    private init(
        sourceTitle: String,
        window: HeatmapShareWindow,
        days: [Day],
        color: Color,
        total: TokenActivityTotal,
        activeDays: Int,
        peakTokens: Int?)
    {
        self.sourceTitle = sourceTitle
        self.window = window
        self.days = days
        self.color = color
        self.total = total
        self.activeDays = activeDays
        self.peakTokens = peakTokens
    }

    static var preview: HeatmapShareData {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let end = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -364, to: end)!
        let days = (0..<365).map { index in
            let date = calendar.date(byAdding: .day, value: index, to: start)!
            let tokens = index < 205 ? nil : max(0, Int((sin(Double(index) * 0.37) + 1.15) * 820_000))
            return Day(
                date: date,
                dayKey: TokenActivity.dayKey(date, calendar: calendar),
                tokens: tokens,
                isLowerBound: false)
        }
        let known = days.compactMap(\.tokens)
        return HeatmapShareData(
            sourceTitle: String(localized: "All Providers"),
            window: .days365,
            days: days,
            color: .blue,
            total: .init(value: known.reduce(0, +), isLowerBound: true),
            activeDays: known.count(where: { $0 > 0 }),
            peakTokens: known.max())
    }
}

struct HeatmapShareCardView: View {
    let data: HeatmapShareData
    var theme: ShareCardTheme = .light

    private var colorScale: TokenActivityColorScale {
        TokenActivityColorScale(values: self.data.days.compactMap(\.tokens))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Token Activity"))
                        .font(.title3.bold())
                    Text(self.data.window.displayName + " · " + self.data.sourceTitle)
                        .font(.caption)
                        .foregroundStyle(self.theme.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "square.grid.3x3.square")
                    .font(.title2)
                    .foregroundStyle(self.data.color)
            }

            Text(self.data.total.text)
                .font(.system(size: 38, weight: .bold, design: .rounded).monospacedDigit())
                .minimumScaleFactor(0.72)
                .lineLimit(1)
                .padding(.top, 16)
            Text(String(localized: "Recorded tokens"))
                .font(.caption)
                .foregroundStyle(self.theme.secondary)

            HStack(spacing: 10) {
                HeatmapMetric(title: String(localized: "Active Days"), value: "\(self.data.activeDays)")
                HeatmapMetric(
                    title: String(localized: "Peak Day"),
                    value: self.data.peakTokens.map(Self.compactTokens) ?? "—")
            }
            .padding(.top, 14)

            VStack(spacing: 12) {
                ForEach(Array(self.data.calendarBlocks.enumerated()), id: \.offset) { _, days in
                    HeatmapShareBlock(days: days, color: self.data.color, scale: self.colorScale)
                }
            }
            .padding(.top, 16)

            HStack(spacing: 5) {
                Text(String(localized: "Less"))
                ForEach(0..<4, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(self.data.color.opacity(0.25 + Double(level) * 0.25))
                        .frame(width: 10, height: 10)
                }
                Text(String(localized: "More"))
                Spacer()
                Text(String(localized: "Missing history is not zero."))
            }
            .font(.system(size: 8))
            .foregroundStyle(self.theme.secondary)
            .padding(.top, 10)

            Spacer(minLength: 8)
            Divider().overlay(self.theme.divider)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CodexBar").font(.caption.bold())
                    Text(String(localized: "Your AI activity, at a glance"))
                        .font(.caption2)
                        .foregroundStyle(self.theme.secondary)
                }
                Spacer()
                Image(uiImage: QRCodeGenerator.generate(from: "https://codexbarios.o1xhack.com", size: 44))
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .padding(.top, 10)
        }
        .foregroundStyle(self.theme.foreground)
        .padding(22)
        .frame(width: 390, height: 520)
        .background(
            LinearGradient(
                colors: [self.theme.background, self.data.color.opacity(self.theme.isDark ? 0.12 : 0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing))
    }

    private static func compactTokens(_ value: Int) -> String {
        if value >= 1_000_000 { return String(format: "%.1fM", Double(value) / 1_000_000) }
        if value >= 1000 { return String(format: "%.0fK", Double(value) / 1000) }
        return "\(value)"
    }
}

private struct HeatmapMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(self.title).font(.caption2).foregroundStyle(.secondary)
            Text(self.value).font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct HeatmapShareBlock: View {
    let days: [HeatmapShareData.Day]
    let color: Color
    let scale: TokenActivityColorScale

    private var gridHeight: CGFloat {
        switch self.days.count {
        case ...100: 130
        case ...180: 95
        default: 82
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(self.days.first?.date ?? Date(), format: .dateTime.month(.abbreviated).day().year())
                Spacer()
                Text(self.days.last?.date ?? Date(), format: .dateTime.month(.abbreviated).day().year())
            }
            .font(.system(size: 8, weight: .medium))
            .foregroundStyle(.secondary)

            GeometryReader { proxy in
                let columns = Int(ceil(Double(self.days.count) / 7))
                let columnWidth = proxy.size.width / CGFloat(columns)
                let cell = max(4, min(18, min(columnWidth - 1, (self.gridHeight - 12) / 7)))
                HStack(spacing: 0) {
                    ForEach(0..<columns, id: \.self) { column in
                        VStack(spacing: 2) {
                            ForEach(0..<7, id: \.self) { row in
                                let index = column * 7 + row
                                if index < self.days.count {
                                    self.cell(for: self.days[index], size: cell)
                                } else {
                                    Color.clear.frame(width: cell, height: cell)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: self.gridHeight)
        }
    }

    private func cell(for day: HeatmapShareData.Day, size: CGFloat) -> some View {
        let fill = day.tokens.map { value in
            value == 0 ? Color.secondary.opacity(0.1) : self.color.opacity(self.scale.intensity(value))
        } ?? .clear
        let unknown = day.tokens == nil || day.isLowerBound
        return RoundedRectangle(cornerRadius: min(2, size / 4))
            .fill(fill)
            .overlay {
                RoundedRectangle(cornerRadius: min(2, size / 4))
                    .strokeBorder(
                        Color.secondary.opacity(unknown ? 0.28 : 0),
                        style: StrokeStyle(lineWidth: 0.7, dash: [1.5]))
            }
            .frame(width: size, height: size)
    }
}

#Preview("Heatmap Share") {
    HeatmapShareCardView(data: .preview)
}
