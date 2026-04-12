import WidgetKit
import SwiftUI

/// Medium Widget — 홈화면 메인 위젯
struct DailyMemoryWidget: Widget {
    let kind: String = "DailyMemoryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyMemoryProvider()) { entry in
            MediumWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "1E293B"), location: 0),
                            .init(color: Color(hex: "0F172A"), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .configurationDisplayName("Engram")
        .description("Record memories and view reminders")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: DailyMemoryEntry

    var body: some View {
        HStack(spacing: 12) {
                // MARK: Left — 정보 영역
                VStack(alignment: .leading, spacing: 0) {
                    // 브랜드 + 날짜
                    HStack(alignment: .center, spacing: 6) {
                        // 브랜드 아이콘
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(hex: "3D5A50"))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            )

                        Text("Engram")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        // Streak
                        if entry.streak > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 9))
                                Text("\(entry.streak)d")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(Color(hex: "FFB84D"))
                        }
                    }
                    .padding(.bottom, 8)

                    // 컨텐츠 카드
                    if !entry.reminders.isEmpty {
                        MediumReminderCard(reminders: entry.reminders)
                    } else if let memory = entry.recentMemories.first {
                        MediumMemoryCard(memory: memory)
                    } else {
                        MediumEmptyCard()
                    }

                    Spacer(minLength: 2)

                    // 하단 날짜 + 카운트
                    HStack(spacing: 0) {
                        Text(formattedDate)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.35))

                        Spacer()

                        Text("\(entry.todayMemoryCount) memories today")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(hex: "6B8F7E"))
                    }
                }
                .frame(maxWidth: .infinity)

                // MARK: Right — 액션 버튼
                VStack(spacing: 8) {
                    Link(destination: URL(string: "dailymemory://record?mode=voice")!) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: "3D5A50"))

                            VStack(spacing: 6) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)

                                Text("Voice")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }

                    Link(destination: URL(string: "dailymemory://record?mode=text")!) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.08))

                            VStack(spacing: 6) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))

                                Text("Text")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white.opacity(0.45))
                            }
                        }
                    }
                }
                .frame(width: 70)
            }
        .padding(14)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: entry.date)
    }
}

// MARK: - Reminder Card

struct MediumReminderCard: View {
    let reminders: [WidgetReminder]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(hex: "F59E0B"))
                    .frame(width: 6, height: 6)
                Text("REMINDERS")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(Color(hex: "F59E0B"))
            }

            ForEach(Array(reminders.prefix(2).enumerated()), id: \.offset) { _, reminder in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color(hex: "F59E0B").opacity(0.6))
                        .frame(width: 2, height: 16)

                    Text(reminder.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)

                    Spacer()

                    Text(formatTime(reminder.scheduledAt))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Memory Card

struct MediumMemoryCard: View {
    let memory: WidgetMemory

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(hex: "6B8F7E"))
                    .frame(width: 6, height: 6)
                Text("LATEST")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(Color(hex: "6B8F7E"))
            }

            Text(memory.content)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if let location = memory.location {
                HStack(spacing: 3) {
                    Image(systemName: "mappin")
                        .font(.system(size: 8))
                    Text(location)
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
    }
}

// MARK: - Empty Card

struct MediumEmptyCard: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "3D5A50"))

            VStack(alignment: .leading, spacing: 2) {
                Text("No memories yet")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                Text("Tap to record your first memory")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
    }
}
