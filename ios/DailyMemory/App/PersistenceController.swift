import CoreData
import WidgetKit

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    static let appGroupIdentifier = "group.com.effortmoney.dailymemory"

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// App Group 공유 컨테이너 URL
    static var sharedStoreURL: URL {
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )!
        return containerURL.appendingPathComponent("DailyMemory.sqlite")
    }

    /// 기존 로컬 저장소 URL (마이그레이션용)
    private static var defaultStoreURL: URL {
        NSPersistentContainer.defaultDirectoryURL()
            .appendingPathComponent("DailyMemory.sqlite")
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DailyMemory")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // 기존 store → App Group 경로로 마이그레이션
            PersistenceController.migrateStoreIfNeeded()

            // App Group 공유 경로 사용
            let description = NSPersistentStoreDescription(url: PersistenceController.sharedStoreURL)
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Store Migration

    /// 기존 로컬 저장소를 App Group 공유 경로로 이동
    private static func migrateStoreIfNeeded() {
        let fileManager = FileManager.default
        let oldStoreURL = defaultStoreURL
        let newStoreURL = sharedStoreURL

        // 이미 공유 경로에 store가 있으면 마이그레이션 불필요
        guard !fileManager.fileExists(atPath: newStoreURL.path) else { return }

        // 기존 store가 없으면 마이그레이션할 것도 없음
        guard fileManager.fileExists(atPath: oldStoreURL.path) else { return }

        // SQLite 관련 파일들 모두 이동 (-wal, -shm)
        let suffixes = ["", "-wal", "-shm"]
        for suffix in suffixes {
            let oldFile = URL(fileURLWithPath: oldStoreURL.path + suffix)
            let newFile = URL(fileURLWithPath: newStoreURL.path + suffix)
            if fileManager.fileExists(atPath: oldFile.path) {
                do {
                    try fileManager.copyItem(at: oldFile, to: newFile)
                } catch {
                    // 마이그레이션 실패 시 새로 시작
                    return
                }
            }
        }

        // 복사 성공 후 원본 삭제
        for suffix in suffixes {
            let oldFile = URL(fileURLWithPath: oldStoreURL.path + suffix)
            try? fileManager.removeItem(at: oldFile)
        }
    }

    // MARK: - Preview Helper
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        do {
            try viewContext.save()
        } catch {
            fatalError("Error creating preview: \(error)")
        }

        return controller
    }()

    // MARK: - Save Context
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
                // 위젯 타임라인 리로드
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
            }
        }
    }
}
