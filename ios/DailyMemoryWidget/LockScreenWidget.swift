import WidgetKit
import SwiftUI

/// Lock Screen Widget (iOS 16+)
///
/// Simple accessory widget for lock screen:
/// - Circular: Microphone icon for quick record
/// - Rectangular: "Record" with mic icon
/// - Inline: "DailyMemory - Record"
@available(iOSApplicationExtension 16.0, *)
struct LockScreenWidget: Widget {
    let kind: String = "LockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickRecordProvider()) { entry in
            LockScreenWidgetView()
        }
        .configurationDisplayName("Quick Record")
        .description("Record memories from your lock screen")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

@available(iOSApplicationExtension 16.0, *)
struct LockScreenWidgetView: View {
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularView()
        case .accessoryRectangular:
            RectangularView()
        case .accessoryInline:
            InlineView()
        default:
            CircularView()
        }
    }
}

// MARK: - Circular View
@available(iOSApplicationExtension 16.0, *)
struct CircularView: View {
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            Image(systemName: "mic.fill")
                .font(.system(size: 20, weight: .semibold))
                .widgetAccentable()
        }
        .widgetURL(URL(string: "dailymemory://record?mode=voice"))
    }
}

// MARK: - Rectangular View
@available(iOSApplicationExtension 16.0, *)
struct RectangularView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "mic.fill")
                .font(.system(size: 24, weight: .semibold))
                .widgetAccentable()

            VStack(alignment: .leading, spacing: 2) {
                Text("DailyMemory")
                    .font(.system(size: 14, weight: .bold))
                Text("Tap to record")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .widgetURL(URL(string: "dailymemory://record?mode=voice"))
    }
}

// MARK: - Inline View
@available(iOSApplicationExtension 16.0, *)
struct InlineView: View {
    var body: some View {
        Label("DailyMemory - Record", systemImage: "mic.fill")
            .widgetURL(URL(string: "dailymemory://record?mode=voice"))
    }
}

// Previews removed - requires iOS 17+
