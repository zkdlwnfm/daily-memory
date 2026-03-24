import WidgetKit

/// Entry for DailyMemory widgets containing timeline data
struct DailyMemoryEntry: TimelineEntry {
    let date: Date
    let memoryCount: Int
    let recentMemory: String?
    let reminders: [String]

    static var placeholder: DailyMemoryEntry {
        DailyMemoryEntry(
            date: Date(),
            memoryCount: 42,
            recentMemory: "Had lunch with Sarah at the new Italian place...",
            reminders: ["Call John at 3pm", "Meeting with team"]
        )
    }

    static var empty: DailyMemoryEntry {
        DailyMemoryEntry(
            date: Date(),
            memoryCount: 0,
            recentMemory: nil,
            reminders: []
        )
    }
}
