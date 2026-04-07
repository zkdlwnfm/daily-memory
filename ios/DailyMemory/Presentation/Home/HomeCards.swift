import SwiftUI

// MARK: - Streak Card

struct StreakCard: View {
    let days: Int

    private var flameCount: Int {
        min(days, 7)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(days >= 7 ? "🔥" : "✨")
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(days)-day streak!")
                    .font(.headline)
                    .fontWeight(.bold)

                Text(encouragement)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Mini flame indicators
            HStack(spacing: 2) {
                ForEach(0..<7, id: \.self) { i in
                    Circle()
                        .fill(i < flameCount ? Color.orange : Color(.systemGray5))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.08), Color.yellow.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(16)
    }

    private var encouragement: String {
        switch days {
        case 1: return "Great start! Keep it going."
        case 2...3: return "Building a habit. Nice!"
        case 4...6: return "You're on a roll!"
        case 7...13: return "One week strong!"
        case 14...29: return "Incredible consistency!"
        default: return "You're unstoppable!"
        }
    }
}

// MARK: - Daily Prompt Card

struct DailyPromptCard: View {
    let onRecord: () -> Void

    private let prompts = [
        "What made you smile today?",
        "Who did you talk to today?",
        "What's one thing you learned today?",
        "How are you feeling right now?",
        "What are you grateful for today?",
        "What was the highlight of your day?",
        "Did anything surprise you today?",
    ]

    private var todayPrompt: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return prompts[dayOfYear % prompts.count]
    }

    var body: some View {
        Button(action: onRecord) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: "pencil.line")
                        .font(.system(size: 18))
                        .foregroundColor(.accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(todayPrompt)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("Tap to record your thought")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Streak") {
    VStack(spacing: 16) {
        StreakCard(days: 1)
        StreakCard(days: 5)
        StreakCard(days: 14)
    }
    .padding()
}

#Preview("Daily Prompt") {
    DailyPromptCard(onRecord: {})
        .padding()
}
