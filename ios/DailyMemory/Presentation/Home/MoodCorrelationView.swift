import SwiftUI

/// Daylio 스타일 무드-활동 상관관계 차트
struct MoodCorrelationView: View {
    let memories: [MoodActivityData]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Text("Mood Insights")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(.dmPrimary)
            }

            if correlations.isEmpty {
                Text("Record more memories with activities to see insights")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.md)
            } else {
                // Top correlations
                ForEach(correlations.prefix(4)) { item in
                    HStack(spacing: Spacing.sm) {
                        // Activity label
                        Text(item.activity)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 80, alignment: .leading)
                            .lineLimit(1)

                        // Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray6))
                                    .frame(height: 20)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(barColor(score: item.averageScore))
                                    .frame(width: max(geo.size.width * item.normalizedScore, 20), height: 20)
                            }
                        }
                        .frame(height: 20)

                        // Score
                        Text(String(format: "%.1f", item.averageScore))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(barColor(score: item.averageScore))
                            .frame(width: 30)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(Radius.md)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private var correlations: [MoodCorrelation] {
        var activityScores: [String: [Int]] = [:]

        for data in memories {
            for activity in data.activities {
                activityScores[activity, default: []].append(data.moodScore)
            }
        }

        let maxScore = 10.0
        return activityScores
            .filter { $0.value.count >= 2 }
            .map { activity, scores in
                let avg = Double(scores.reduce(0, +)) / Double(scores.count)
                return MoodCorrelation(
                    activity: activity,
                    averageScore: avg,
                    count: scores.count,
                    normalizedScore: avg / maxScore
                )
            }
            .sorted { $0.averageScore > $1.averageScore }
    }

    private func barColor(score: Double) -> Color {
        switch score {
        case 8...10: return Color(hex: "22C55E")
        case 6..<8: return Color(hex: "6B8F7E")
        case 4..<6: return Color(hex: "F59E0B")
        default: return Color(hex: "EF4444")
        }
    }
}

struct MoodActivityData {
    let moodScore: Int
    let activities: [String]
}

struct MoodCorrelation: Identifiable {
    let id = UUID()
    let activity: String
    let averageScore: Double
    let count: Int
    let normalizedScore: Double
}
