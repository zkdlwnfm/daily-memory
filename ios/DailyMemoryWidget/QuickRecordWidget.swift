import WidgetKit
import SwiftUI

/// Small Widget (1x1) - Quick Voice Record
///
/// Simple one-tap widget to start voice recording:
/// - Primary color background (#6366F1)
/// - Microphone icon
/// - "Record" label
/// - Deep links to voice recording screen
struct QuickRecordWidget: Widget {
    let kind: String = "QuickRecordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickRecordProvider()) { entry in
            QuickRecordWidgetView()
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Record")
        .description("One tap to start voice recording")
        .supportedFamilies([.systemSmall])
    }
}

struct QuickRecordWidgetView: View {
    @Environment(\.widgetFamily) var family

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(WidgetColors.primary)

                // Content
                VStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: min(geometry.size.width, geometry.size.height) * 0.35))
                        .foregroundColor(.white)

                    Text("Record")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .widgetURL(URL(string: "dailymemory://record?mode=voice"))
        }
    }
}

// Preview removed - requires iOS 17+
