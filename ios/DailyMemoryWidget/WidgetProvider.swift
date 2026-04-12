import WidgetKit
import SwiftUI

/// 메인 위젯용 타임라인 프로바이더
/// SharedDataProvider를 통해 실제 CoreData 데이터를 읽는다.
struct DailyMemoryProvider: TimelineProvider {
    typealias Entry = DailyMemoryEntry

    func placeholder(in context: Context) -> DailyMemoryEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyMemoryEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        completion(fetchCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyMemoryEntry>) -> Void) {
        let entry = fetchCurrentEntry()

        // 30분마다 업데이트
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchCurrentEntry() -> DailyMemoryEntry {
        DailyMemoryEntry(
            date: Date(),
            totalMemoryCount: SharedDataProvider.fetchTotalMemoryCount(),
            todayMemoryCount: SharedDataProvider.fetchTodayMemoryCount(),
            streak: SharedDataProvider.fetchStreak(),
            recentMemories: SharedDataProvider.fetchRecentMemories(limit: 3),
            reminders: SharedDataProvider.fetchTodayReminders()
        )
    }
}

/// Quick Record / Lock Screen 용 프로바이더
/// 동적 데이터 포함 (오늘 기록 수, streak)
struct QuickRecordProvider: TimelineProvider {
    typealias Entry = DailyMemoryEntry

    func placeholder(in context: Context) -> DailyMemoryEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyMemoryEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        completion(fetchCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyMemoryEntry>) -> Void) {
        let entry = fetchCurrentEntry()

        // 1시간마다 업데이트
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchCurrentEntry() -> DailyMemoryEntry {
        DailyMemoryEntry(
            date: Date(),
            totalMemoryCount: SharedDataProvider.fetchTotalMemoryCount(),
            todayMemoryCount: SharedDataProvider.fetchTodayMemoryCount(),
            streak: SharedDataProvider.fetchStreak(),
            recentMemories: SharedDataProvider.fetchRecentMemories(limit: 1),
            reminders: SharedDataProvider.fetchTodayReminders()
        )
    }
}
