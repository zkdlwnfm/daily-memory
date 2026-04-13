import SwiftUI

// MARK: - Streak Ring View

struct StreakCard: View {
    let days: Int

    private var weekProgress: Double {
        min(Double(days % 7 == 0 && days > 0 ? 7 : days % 7), 7) / 7.0
    }

    private var milestoneIcon: String? {
        if days >= 365 { return "crown.fill" }
        if days >= 100 { return "star.fill" }
        if days >= 30 { return "medal.fill" }
        if days >= 7 { return "flame.fill" }
        return nil
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Ring
            ZStack {
                // Track
                Circle()
                    .stroke(Color.dmPrimary.opacity(0.1), lineWidth: 6)
                    .frame(width: 56, height: 56)

                // Progress
                Circle()
                    .trim(from: 0, to: weekProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.dmPrimary, Color.dmPrimaryLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                // Center
                VStack(spacing: 0) {
                    Text("\(days)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.dmPrimary)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Text("\(days)-day streak")
                        .font(.headline)
                        .fontWeight(.bold)

                    if let icon = milestoneIcon {
                        Image(systemName: icon)
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                }

                Text(encouragement)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Weekly dots
            HStack(spacing: 3) {
                ForEach(0..<7, id: \.self) { i in
                    let filled = i < (days >= 7 ? 7 : days % 7 + (days > 0 && days % 7 == 0 ? 0 : 0))
                    Circle()
                        .fill(i < min(days, 7) ? Color.dmPrimary : Color(.systemGray5))
                        .frame(width: 7, height: 7)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.dmPrimary.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.dmPrimary.opacity(0.12), lineWidth: 1)
        )
        .cornerRadius(Radius.md)
    }

    private var encouragement: String {
        switch days {
        case 1: return "Great start! Keep it going."
        case 2...3: return "Building a habit!"
        case 4...6: return "You're on a roll!"
        case 7...13: return "One week strong!"
        case 14...29: return "Incredible consistency!"
        case 30...99: return "A whole month! Amazing!"
        case 100...364: return "Triple digits!"
        default: return "You're unstoppable!"
        }
    }
}

// MARK: - Daily Prompt Card (with Quick Entry CTA)

struct DailyPromptCard: View {
    let onRecord: () -> Void
    let onQuickEntry: () -> Void

    private let moods = ["😊", "🙂", "😐", "😔", "😤"]

    private let prompts = [
        "What made you smile today?",
        "Who did you talk to today?",
        "What's one thing you learned today?",
        "How are you feeling right now?",
        "What are you grateful for today?",
        "What was the highlight of your day?",
        "Did anything surprise you today?",
        "What's one thing you want to remember?",
        "Who made your day better?",
        "What was the hardest part of today?",
        "What are you looking forward to tomorrow?",
        "Describe today in one sentence.",
        "What did you eat today?",
        "Where did you go today?",
    ]

    private var todayPrompt: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return prompts[dayOfYear % prompts.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Quick mood entry
            Button(action: onQuickEntry) {
                VStack(spacing: Spacing.sm) {
                    Text("How are you feeling?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    HStack(spacing: Spacing.md) {
                        ForEach(moods, id: \.self) { mood in
                            Text(mood)
                                .font(.system(size: 28))
                        }
                    }

                    Text("Tap to quick record")
                        .font(.caption)
                        .foregroundColor(.dmPrimary)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .padding(.horizontal, Spacing.md)
            }
            .buttonStyle(.plain)

            Divider().padding(.horizontal, Spacing.md)

            // Full record option
            Button(action: onRecord) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.dmPrimary)

                    Text(todayPrompt)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm + 2)
            }
            .buttonStyle(.plain)
        }
        .background(Color(.systemBackground))
        .cornerRadius(Radius.md)
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

// MARK: - Previews

#Preview("Streak") {
    VStack(spacing: 16) {
        StreakCard(days: 1)
        StreakCard(days: 5)
        StreakCard(days: 14)
        StreakCard(days: 100)
    }
    .padding()
}

#Preview("Daily Prompt") {
    DailyPromptCard(onRecord: {}, onQuickEntry: {})
        .padding()
}
