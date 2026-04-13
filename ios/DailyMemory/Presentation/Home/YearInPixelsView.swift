import SwiftUI

/// Daylio 스타일 Year in Pixels — 365일을 색상 그리드로 시각화
struct YearInPixelsView: View {
    let pixelData: [Date: PixelDay]
    let year: Int

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Year in Pixels")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("\(recordedDays)/\(daysElapsed) days recorded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Completion percentage
                Text("\(completionPercent)%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.dmPrimary)
            }

            // Mini month grid (compact view)
            HStack(alignment: .top, spacing: 3) {
                ForEach(0..<12, id: \.self) { month in
                    miniMonthColumn(month: month + 1)
                }
            }

            // Legend
            HStack(spacing: Spacing.md) {
                legendItem(color: Color(.systemGray5), label: "No record")
                legendItem(color: .dmPrimary.opacity(0.25), label: "Recorded")
                legendItem(color: .dmPrimary.opacity(0.5), label: "2+")
                legendItem(color: .dmPrimary, label: "3+")
            }
            .font(.system(size: 9))
        }
        .padding(Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(Radius.md)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Mini Month Column

    private func miniMonthColumn(month: Int) -> some View {
        VStack(spacing: 2) {
            Text(monthLabel(month))
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.secondary)

            let days = daysInMonth(month: month, year: year)
            ForEach(days, id: \.self) { date in
                let pixel = pixelData[calendar.startOfDay(for: date)]
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(pixelColor(for: pixel))
                    .frame(height: 6)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func pixelColor(for pixel: PixelDay?) -> Color {
        guard let pixel else { return Color(.systemGray5) }

        if let mood = pixel.mood {
            return moodColor(mood)
        }

        switch pixel.count {
        case 1: return .dmPrimary.opacity(0.25)
        case 2: return .dmPrimary.opacity(0.5)
        default: return .dmPrimary
        }
    }

    private func moodColor(_ mood: String) -> Color {
        switch mood {
        case "happy", "excited", "grateful": return Color(hex: "22C55E")
        case "calm": return Color(hex: "6B8F7E")
        case "neutral": return Color(hex: "94A3B8")
        case "sad", "nostalgic": return Color(hex: "3B82F6")
        case "anxious", "angry": return Color(hex: "EF4444")
        default: return .dmPrimary.opacity(0.3)
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
        }
    }

    private func monthLabel(_ month: Int) -> String {
        let formatter = DateFormatter()
        return String(formatter.shortMonthSymbols[month - 1].prefix(1))
    }

    private func daysInMonth(month: Int, year: Int) -> [Date] {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }

        let today = Date()
        return range.compactMap { day -> Date? in
            components.day = day
            guard let date = calendar.date(from: components) else { return nil }
            return date <= today ? date : nil
        }
    }

    private var recordedDays: Int {
        pixelData.count
    }

    private var daysElapsed: Int {
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let today = min(Date(), calendar.date(from: DateComponents(year: year, month: 12, day: 31))!)
        return (calendar.dateComponents([.day], from: startOfYear, to: today).day ?? 0) + 1
    }

    private var completionPercent: Int {
        guard daysElapsed > 0 else { return 0 }
        return Int(Double(recordedDays) / Double(daysElapsed) * 100)
    }
}

/// 하루의 픽셀 데이터
struct PixelDay {
    let count: Int
    let mood: String?
}
