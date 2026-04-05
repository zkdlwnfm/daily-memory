import Foundation

/// Dependency Injection Container
/// Provides singleton instances of repositories and use cases
final class DIContainer {
    static let shared = DIContainer()

    private init() {}

    // MARK: - Repositories

    private lazy var _memoryRepository: MemoryRepository = MemoryRepositoryImpl()
    private lazy var _personRepository: PersonRepository = PersonRepositoryImpl()
    private lazy var _reminderRepository: ReminderRepository = ReminderRepositoryImpl()

    var memoryRepository: MemoryRepository { _memoryRepository }
    var personRepository: PersonRepository { _personRepository }
    var reminderRepository: ReminderRepository { _reminderRepository }

    // MARK: - Memory Use Cases

    lazy var saveMemoryUseCase: SaveMemoryUseCase = {
        SaveMemoryUseCase(
            memoryRepository: memoryRepository,
            personRepository: personRepository
        )
    }()

    lazy var updateMemoryUseCase: UpdateMemoryUseCase = {
        UpdateMemoryUseCase(memoryRepository: memoryRepository)
    }()

    lazy var deleteMemoryUseCase: DeleteMemoryUseCase = {
        DeleteMemoryUseCase(
            memoryRepository: memoryRepository,
            reminderRepository: reminderRepository
        )
    }()

    lazy var getMemoryUseCase: GetMemoryUseCase = {
        GetMemoryUseCase(memoryRepository: memoryRepository)
    }()

    lazy var getRecentMemoriesUseCase: GetRecentMemoriesUseCase = {
        GetRecentMemoriesUseCase(memoryRepository: memoryRepository)
    }()

    lazy var searchMemoriesUseCase: SearchMemoriesUseCase = {
        SearchMemoriesUseCase(memoryRepository: memoryRepository)
    }()

    // MARK: - Person Use Cases

    lazy var savePersonUseCase: SavePersonUseCase = {
        SavePersonUseCase(personRepository: personRepository)
    }()

    lazy var updatePersonUseCase: UpdatePersonUseCase = {
        UpdatePersonUseCase(personRepository: personRepository)
    }()

    lazy var deletePersonUseCase: DeletePersonUseCase = {
        DeletePersonUseCase(
            personRepository: personRepository,
            reminderRepository: reminderRepository
        )
    }()

    lazy var getPersonUseCase: GetPersonUseCase = {
        GetPersonUseCase(personRepository: personRepository)
    }()

    lazy var getAllPersonsUseCase: GetAllPersonsUseCase = {
        GetAllPersonsUseCase(personRepository: personRepository)
    }()

    // MARK: - Reminder Use Cases

    lazy var saveReminderUseCase: SaveReminderUseCase = {
        SaveReminderUseCase(reminderRepository: reminderRepository)
    }()

    lazy var updateReminderUseCase: UpdateReminderUseCase = {
        UpdateReminderUseCase(reminderRepository: reminderRepository)
    }()

    lazy var deleteReminderUseCase: DeleteReminderUseCase = {
        DeleteReminderUseCase(reminderRepository: reminderRepository)
    }()

    lazy var getTodayRemindersUseCase: GetTodayRemindersUseCase = {
        GetTodayRemindersUseCase(reminderRepository: reminderRepository)
    }()

    lazy var getUpcomingRemindersUseCase: GetUpcomingRemindersUseCase = {
        GetUpcomingRemindersUseCase(reminderRepository: reminderRepository)
    }()

    lazy var completeReminderUseCase: CompleteReminderUseCase = {
        CompleteReminderUseCase(reminderRepository: reminderRepository)
    }()

    lazy var snoozeReminderUseCase: SnoozeReminderUseCase = {
        SnoozeReminderUseCase(reminderRepository: reminderRepository)
    }()

    // MARK: - AI Use Cases

    lazy var analyzeMemoryUseCase: AnalyzeMemoryUseCase = {
        AnalyzeMemoryUseCase()
    }()

    lazy var analyzeImageUseCase: AnalyzeImageUseCase = {
        AnalyzeImageUseCase()
    }()

    lazy var semanticSearchUseCase: SemanticSearchUseCase = {
        SemanticSearchUseCase()
    }()

    // MARK: - Cloud Services

    var authService: AuthService { AuthService.shared }
    var firestoreService: FirestoreService { FirestoreService.shared }
    var cloudStorageService: CloudStorageService { CloudStorageService.shared }
    var syncManager: SyncManager { SyncManager.shared }
}
