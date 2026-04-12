import WidgetKit
import SwiftUI

/// Small Widget — Engram 브랜드 녹음 위젯
struct QuickRecordWidget: Widget {
    let kind: String = "QuickRecordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickRecordProvider()) { entry in
            SmallWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "3D5A50"), location: 0),
                            .init(color: Color(hex: "2D4339"), location: 0.6),
                            .init(color: Color(hex: "1F2F28"), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Quick Record")
        .description("One tap to start voice recording")
        .supportedFamilies([.systemSmall])
    }
}

struct SmallWidgetView: View {
    let entry: DailyMemoryEntry

    var body: some View {
        VStack(spacing: 0) {
                // 상단: 브랜드명
                HStack {
                    Text("engram")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1.5)
                    Spacer()
                }
                .padding(.top, 2)

                Spacer()

                // 중앙: 마이크 아이콘
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 2)
                        .frame(width: 64, height: 64)

                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 54, height: 54)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }

                Spacer()

                // 하단: 통계
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(entry.todayMemoryCount)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("today")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    if entry.streak > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12))
                                Text("\(entry.streak)")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(Color(hex: "FFB84D"))
                            Text("streak")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .padding(.bottom, 2)
            }
        .padding(14)
        .widgetURL(URL(string: "dailymemory://record?mode=voice"))
    }
}
