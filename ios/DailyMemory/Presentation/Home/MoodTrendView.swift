import SwiftUI

struct MoodTrendView: View {
    let moodData: [MoodDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mood Trend")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                if let latest = moodData.last {
                    Text(latest.emoji)
                        .font(.title2)
                }
            }

            if moodData.count >= 2 {
                // Chart
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height: CGFloat = 80
                    let maxScore = 10.0
                    let stepX = width / CGFloat(max(moodData.count - 1, 1))

                    ZStack(alignment: .bottomLeading) {
                        // Grid lines
                        ForEach([2.5, 5.0, 7.5], id: \.self) { level in
                            let y = height - (CGFloat(level) / CGFloat(maxScore)) * height
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: width, y: y))
                            }
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
                        }

                        // Line
                        Path { path in
                            for (index, point) in moodData.enumerated() {
                                let x = CGFloat(index) * stepX
                                let y = height - (CGFloat(point.score) / CGFloat(maxScore)) * height
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(
                            LinearGradient(colors: [.dmPrimary, .dmSecondary], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                        )

                        // Dots
                        ForEach(Array(moodData.enumerated()), id: \.element.id) { index, point in
                            let x = CGFloat(index) * stepX
                            let y = height - (CGFloat(point.score) / CGFloat(maxScore)) * height

                            Circle()
                                .fill(colorForScore(point.score))
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                        }
                    }
                    .frame(height: height)
                }
                .frame(height: 80)

                // Date labels
                HStack {
                    if let first = moodData.first {
                        Text(first.dateLabel)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if let last = moodData.last {
                        Text(last.dateLabel)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("Record more memories to see your mood trend")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 1...3: return .red
        case 4...5: return .orange
        case 6...7: return .dmSecondary
        case 8...10: return .dmSuccess
        default: return .secondary
        }
    }
}

struct MoodDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let score: Int
    let mood: String

    var emoji: String {
        switch mood {
        case "happy": return "😊"
        case "sad": return "😢"
        case "excited": return "🤩"
        case "anxious": return "😰"
        case "grateful": return "🙏"
        case "angry": return "😤"
        case "calm": return "😌"
        case "nostalgic": return "🥹"
        default: return "😐"
        }
    }

    var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

#Preview {
    MoodTrendView(moodData: [
        MoodDataPoint(date: Date().addingTimeInterval(-6*86400), score: 6, mood: "calm"),
        MoodDataPoint(date: Date().addingTimeInterval(-5*86400), score: 8, mood: "happy"),
        MoodDataPoint(date: Date().addingTimeInterval(-4*86400), score: 4, mood: "anxious"),
        MoodDataPoint(date: Date().addingTimeInterval(-3*86400), score: 7, mood: "grateful"),
        MoodDataPoint(date: Date().addingTimeInterval(-2*86400), score: 9, mood: "excited"),
        MoodDataPoint(date: Date().addingTimeInterval(-1*86400), score: 5, mood: "neutral"),
        MoodDataPoint(date: Date(), score: 8, mood: "happy"),
    ])
    .padding()
}
