import WidgetKit
import SwiftUI

/// Timeline provider for DailyMemory widgets
struct DailyMemoryProvider: TimelineProvider {
    typealias Entry = DailyMemoryEntry

    func placeholder(in context: Context) -> DailyMemoryEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyMemoryEntry) -> Void) {
        // Return placeholder for preview
        if context.isPreview {
            completion(.placeholder)
            return
        }

        // In real implementation, fetch data from shared container
        let entry = fetchCurrentEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyMemoryEntry>) -> Void) {
        let currentDate = Date()
        let entry = fetchCurrentEntry()

        // Update every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    // MARK: - Private

    private func fetchCurrentEntry() -> DailyMemoryEntry {
        // In a real implementation, this would fetch data from:
        // 1. Shared UserDefaults (App Group)
        // 2. Core Data with shared container
        // 3. Or other shared storage

        // For now, return sample data
        return DailyMemoryEntry(
            date: Date(),
            memoryCount: 0,
            recentMemory: nil,
            reminders: []
        )
    }
}

/// Simple provider for Quick Record widget (no dynamic data needed)
struct QuickRecordProvider: TimelineProvider {
    typealias Entry = SimpleEntry

    struct SimpleEntry: TimelineEntry {
        let date: Date
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        // Static widget, update once a day
        let entry = SimpleEntry(date: Date())
        let nextUpdate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
