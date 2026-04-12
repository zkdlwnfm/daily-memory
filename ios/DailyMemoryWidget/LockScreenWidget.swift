import WidgetKit
import SwiftUI

/// 잠금화면 위젯 — 기억 프리뷰 + streak
@available(iOSApplicationExtension 16.0, *)
struct LockScreenWidget: Widget {
    let kind: String = "LockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickRecordProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Engram Memories")
        .description("View memories and streak from lock screen")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Root

@available(iOSApplicationExtension 16.0, *)
struct LockScreenWidgetView: View {
    let entry: DailyMemoryEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            LockCircularView(entry: entry)
        case .accessoryRectangular:
            LockRectangularView(entry: entry)
        case .accessoryInline:
            LockInlineView(entry: entry)
        default:
            LockCircularView(entry: entry)
        }
    }
}

// MARK: - Circular: 오늘 기록 수 (게이지 링)

@available(iOSApplicationExtension 16.0, *)
struct LockCircularView: View {
    let entry: DailyMemoryEntry

    var body: some View {
        ZStack {
            // 목표 대비 게이지 (하루 5개 기준)
            Gauge(value: Double(min(entry.todayMemoryCount, 5)), in: 0...5) {
                Image(systemName: "brain.head.profile")
            } currentValueLabel: {
                Text("\(entry.todayMemoryCount)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .gaugeStyle(.accessoryCircular)
            .widgetAccentable()
        }
        .widgetURL(URL(string: "dailymemory://record?mode=voice"))
    }
}

// MARK: - Rectangular: 최근 기억 + 통계

@available(iOSApplicationExtension 16.0, *)
struct LockRectangularView: View {
    let entry: DailyMemoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 9, weight: .bold))
                    .widgetAccentable()

                Text("Engram")
                    .font(.system(size: 12, weight: .bold))

                Spacer()

                if entry.streak > 0 {
                    HStack(spacing: 1) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                        Text("\(entry.streak)")
                            .font(.system(size: 10, weight: .bold))
                    }
                }
            }

            // Memory preview
            if let preview = entry.recentMemoryPreview {
                Text(preview)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("Tap to record a memory")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            // Stats
            HStack(spacing: 4) {
                Text("\(entry.todayMemoryCount) memories today")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)

                if entry.totalMemoryCount > 0 {
                    Text("· \(entry.totalMemoryCount) total")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .widgetURL(URL(string: "dailymemory://record?mode=voice"))
    }
}

// MARK: - Inline

@available(iOSApplicationExtension 16.0, *)
struct LockInlineView: View {
    let entry: DailyMemoryEntry

    var body: some View {
        if entry.streak > 0 {
            Label(
                "Engram · \(entry.todayMemoryCount) today · \(entry.streak)d streak",
                systemImage: "brain.head.profile"
            )
        } else {
            Label(
                "Engram · \(entry.todayMemoryCount) memories today",
                systemImage: "brain.head.profile"
            )
        }
    }
}
