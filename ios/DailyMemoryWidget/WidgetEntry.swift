import WidgetKit

/// 위젯 타임라인 엔트리
struct DailyMemoryEntry: TimelineEntry {
    let date: Date
    let totalMemoryCount: Int
    let todayMemoryCount: Int
    let streak: Int
    let recentMemories: [WidgetMemory]
    let reminders: [WidgetReminder]

    /// 가장 최근 기억 내용 (프리뷰용)
    var recentMemoryPreview: String? {
        recentMemories.first?.content
    }

    static var placeholder: DailyMemoryEntry {
        DailyMemoryEntry(
            date: Date(),
            totalMemoryCount: 42,
            todayMemoryCount: 3,
            streak: 7,
            recentMemories: [
                WidgetMemory(
                    content: "Had lunch with Sarah at the new Italian place downtown...",
                    recordedAt: Date(),
                    category: "EVENT",
                    mood: "happy",
                    location: "Gangnam"
                )
            ],
            reminders: [
                WidgetReminder(title: "Call John at 3pm", scheduledAt: Date()),
                WidgetReminder(title: "Team meeting", scheduledAt: Date())
            ]
        )
    }

    static var empty: DailyMemoryEntry {
        DailyMemoryEntry(
            date: Date(),
            totalMemoryCount: 0,
            todayMemoryCount: 0,
            streak: 0,
            recentMemories: [],
            reminders: []
        )
    }
}
