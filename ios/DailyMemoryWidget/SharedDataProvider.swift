import CoreData
import Foundation

/// 위젯 전용 CoreData 읽기 접근
/// App Group 공유 컨테이너를 통해 앱의 데이터를 읽는다.
enum SharedDataProvider {

    private static let appGroupIdentifier = "group.com.effortmoney.dailymemory"

    private static var sharedStoreURL: URL {
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )!
        return containerURL.appendingPathComponent("DailyMemory.sqlite")
    }

    private static var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DailyMemory")
        let description = NSPersistentStoreDescription(url: sharedStoreURL)
        description.isReadOnly = true
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                print("[Widget] Failed to load store: \(error)")
            }
        }
        return container
    }()

    private static var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: - Queries

    /// 최근 기억 N개
    static func fetchRecentMemories(limit: Int = 3) -> [WidgetMemory] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "MemoryMO")
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]
        request.fetchLimit = limit

        guard let results = try? context.fetch(request) else { return [] }

        return results.compactMap { mo in
            guard let content = mo.value(forKey: "content") as? String,
                  let recordedAt = mo.value(forKey: "recordedAt") as? Date,
                  let categoryRaw = mo.value(forKey: "categoryRaw") as? String
            else { return nil }

            let mood = mo.value(forKey: "mood") as? String
            let extractedLocation = mo.value(forKey: "extractedLocation") as? String

            return WidgetMemory(
                content: content,
                recordedAt: recordedAt,
                category: categoryRaw,
                mood: mood,
                location: extractedLocation
            )
        }
    }

    /// 오늘 기록한 기억 수
    static func fetchTodayMemoryCount() -> Int {
        let request = NSFetchRequest<NSManagedObject>(entityName: "MemoryMO")
        let startOfDay = Calendar.current.startOfDay(for: Date())
        request.predicate = NSPredicate(format: "recordedAt >= %@", startOfDay as NSDate)

        return (try? context.count(for: request)) ?? 0
    }

    /// 전체 기억 수
    static func fetchTotalMemoryCount() -> Int {
        let request = NSFetchRequest<NSManagedObject>(entityName: "MemoryMO")
        return (try? context.count(for: request)) ?? 0
    }

    /// 오늘의 리마인더
    static func fetchTodayReminders() -> [WidgetReminder] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "ReminderMO")
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        request.predicate = NSPredicate(
            format: "isActive == YES AND scheduledAt >= %@ AND scheduledAt < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "scheduledAt", ascending: true)]
        request.fetchLimit = 3

        guard let results = try? context.fetch(request) else { return [] }

        return results.compactMap { mo in
            guard let title = mo.value(forKey: "title") as? String,
                  let scheduledAt = mo.value(forKey: "scheduledAt") as? Date
            else { return nil }

            return WidgetReminder(title: title, scheduledAt: scheduledAt)
        }
    }

    /// 연속 기록 일수 (streak)
    static func fetchStreak() -> Int {
        let request = NSFetchRequest<NSDictionary>(entityName: "MemoryMO")
        request.resultType = .dictionaryResultType

        let dateExpression = NSExpression(forKeyPath: "recordedAt")
        let description = NSExpressionDescription()
        description.name = "recordedDate"
        description.expression = dateExpression
        description.expressionResultType = .dateAttributeType
        request.propertiesToFetch = [description]
        request.propertiesToGroupBy = [description]
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]

        // 간단한 방식: 최근 기억들의 날짜를 가져와서 연속일 계산
        let memoryRequest = NSFetchRequest<NSManagedObject>(entityName: "MemoryMO")
        memoryRequest.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]
        memoryRequest.fetchLimit = 365

        guard let results = try? context.fetch(memoryRequest) else { return 0 }

        let calendar = Calendar.current
        var dates = Set<DateComponents>()
        for mo in results {
            if let date = mo.value(forKey: "recordedAt") as? Date {
                let components = calendar.dateComponents([.year, .month, .day], from: date)
                dates.insert(components)
            }
        }

        // 오늘부터 거꾸로 연속일 계산
        var streak = 0
        var checkDate = Date()

        // 오늘 기록이 없으면 어제부터 체크
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: checkDate)
        if !dates.contains(todayComponents) {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        while true {
            let components = calendar.dateComponents([.year, .month, .day], from: checkDate)
            if dates.contains(components) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        return streak
    }
}

// MARK: - Widget Data Models

struct WidgetMemory {
    let content: String
    let recordedAt: Date
    let category: String
    let mood: String?
    let location: String?
}

struct WidgetReminder {
    let title: String
    let scheduledAt: Date
}
