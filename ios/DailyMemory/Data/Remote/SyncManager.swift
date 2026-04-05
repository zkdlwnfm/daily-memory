import Foundation
import Combine
import Network

/// Sync status for UI
enum SyncState: Equatable {
    case idle
    case syncing(progress: Double)
    case synced
    case error(String)
    case offline

    static func == (lhs: SyncState, rhs: SyncState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.synced, .synced), (.offline, .offline): return true
        case (.syncing(let a), .syncing(let b)): return a == b
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

/// Tracks local changes that need to be synced
struct SyncChange: Codable, Identifiable {
    let id: String
    let entityType: EntityType
    let entityId: String
    let changeType: ChangeType
    let timestamp: Date

    enum EntityType: String, Codable {
        case memory, person, reminder
    }

    enum ChangeType: String, Codable {
        case create, update, delete
    }

    init(entityType: EntityType, entityId: String, changeType: ChangeType) {
        self.id = UUID().uuidString
        self.entityType = entityType
        self.entityId = entityId
        self.changeType = changeType
        self.timestamp = Date()
    }
}

/// Offline-first sync manager
@MainActor
final class SyncManager: ObservableObject {
    static let shared = SyncManager()

    @Published private(set) var syncState: SyncState = .idle
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var pendingChanges: Int = 0

    private let firestoreService = FirestoreService.shared
    private let cloudStorage = CloudStorageService.shared
    private let authService = AuthService.shared

    private let networkMonitor = NWPathMonitor()
    private var isNetworkAvailable = true
    private var pendingQueue: [SyncChange] = []
    private var isSyncing = false
    private var cancellables = Set<AnyCancellable>()

    private let queueFileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("sync_queue.json")
    }()

    private let lastSyncKey = "lastSyncDate"

    private init() {
        loadPendingQueue()
        loadLastSyncDate()
        startNetworkMonitoring()
        observeAuthState()
    }

    // MARK: - Network Monitoring

    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            let isAvailable = path.status == .satisfied
            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasOffline = !self.isNetworkAvailable
                self.isNetworkAvailable = isAvailable

                if isAvailable {
                    if wasOffline {
                        await self.syncAll()
                    }
                } else {
                    self.syncState = .offline
                }
            }
        }
        networkMonitor.start(queue: DispatchQueue.global(qos: .utility))
    }

    private func observeAuthState() {
        authService.$authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if case .signedIn = state {
                    Task { await self?.syncAll() }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Change Queue Management

    func enqueueChange(_ change: SyncChange) {
        // Deduplicate: if same entity has pending change, replace it
        pendingQueue.removeAll { $0.entityType == change.entityType && $0.entityId == change.entityId }
        pendingQueue.append(change)
        pendingChanges = pendingQueue.count
        savePendingQueue()

        // Auto-sync if online
        if isNetworkAvailable && authService.isSignedIn && !isSyncing {
            Task { await syncAll() }
        }
    }

    func enqueueMemoryChange(id: String, type: SyncChange.ChangeType) {
        enqueueChange(SyncChange(entityType: .memory, entityId: id, changeType: type))
    }

    func enqueuePersonChange(id: String, type: SyncChange.ChangeType) {
        enqueueChange(SyncChange(entityType: .person, entityId: id, changeType: type))
    }

    func enqueueReminderChange(id: String, type: SyncChange.ChangeType) {
        enqueueChange(SyncChange(entityType: .reminder, entityId: id, changeType: type))
    }

    // MARK: - Sync Operations

    func syncAll() async {
        guard !isSyncing else { return }
        guard authService.isSignedIn else { return }
        guard isNetworkAvailable else {
            syncState = .offline
            return
        }

        isSyncing = true
        syncState = .syncing(progress: 0)

        do {
            let totalChanges = max(pendingQueue.count, 1)

            // 1. Push local changes to cloud
            var processed = 0
            let changesToProcess = pendingQueue // Snapshot
            for change in changesToProcess {
                try await processChange(change)
                processed += 1
                syncState = .syncing(progress: Double(processed) / Double(totalChanges) * 0.5)

                // Remove from queue after successful sync
                pendingQueue.removeAll { $0.id == change.id }
            }

            syncState = .syncing(progress: 0.5)

            // 2. Pull cloud changes
            try await pullCloudChanges()

            syncState = .syncing(progress: 1.0)

            // Done
            lastSyncDate = Date()
            saveLastSyncDate()
            pendingChanges = pendingQueue.count
            savePendingQueue()
            syncState = .synced

            // Reset to idle after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if syncState == .synced {
                syncState = .idle
            }
        } catch {
            syncState = .error(error.localizedDescription)
            pendingChanges = pendingQueue.count
            savePendingQueue()
        }

        isSyncing = false
    }

    private func processChange(_ change: SyncChange) async throws {
        let container = DIContainer.shared

        switch change.entityType {
        case .memory:
            switch change.changeType {
            case .create, .update:
                if let memory = try await container.getMemoryUseCase.execute(id: change.entityId) {
                    // Upload photos first
                    let updatedPhotos = try await cloudStorage.syncPhotos(for: memory)
                    var syncedMemory = memory
                    syncedMemory.photos = updatedPhotos
                    syncedMemory.syncStatus = .synced

                    try await firestoreService.saveMemory(syncedMemory)

                    // Update local with synced status
                    _ = try await container.updateMemoryUseCase.execute(syncedMemory)
                }
            case .delete:
                try await firestoreService.deleteMemory(id: change.entityId)
                try await cloudStorage.deleteAllPhotos(memoryId: change.entityId)
            }

        case .person:
            switch change.changeType {
            case .create, .update:
                if let person = try await container.getPersonUseCase.execute(id: change.entityId) {
                    var syncedPerson = person
                    syncedPerson.syncStatus = .synced
                    try await firestoreService.savePerson(syncedPerson)
                    _ = try await container.updatePersonUseCase.execute(syncedPerson)
                }
            case .delete:
                try await firestoreService.deletePerson(id: change.entityId)
            }

        case .reminder:
            switch change.changeType {
            case .create, .update:
                if let reminder = try await container.reminderRepository.getById(change.entityId) {
                    var syncedReminder = reminder
                    syncedReminder.syncStatus = .synced
                    try await firestoreService.saveReminder(syncedReminder)
                    _ = try await container.updateReminderUseCase.execute(syncedReminder)
                }
            case .delete:
                try await firestoreService.deleteReminder(id: change.entityId)
            }
        }
    }

    private func pullCloudChanges() async throws {
        let container = DIContainer.shared

        // Fetch memories updated since last sync
        let cloudMemories = try await firestoreService.fetchMemories(since: lastSyncDate)
        for cloudMemory in cloudMemories {
            let localMemory = try await container.getMemoryUseCase.execute(id: cloudMemory.id)

            if let local = localMemory {
                // Conflict resolution: cloud wins if cloud is newer
                if cloudMemory.updatedAt > local.updatedAt {
                    _ = try await container.updateMemoryUseCase.execute(cloudMemory)
                }
            } else {
                // New from cloud - save locally
                _ = try await container.saveMemoryUseCase.execute(cloudMemory)
            }
        }

        // Fetch persons
        let cloudPersons = try await firestoreService.fetchPersons(since: lastSyncDate)
        for cloudPerson in cloudPersons {
            let localPerson = try await container.getPersonUseCase.execute(id: cloudPerson.id)

            if let local = localPerson {
                if cloudPerson.updatedAt > local.updatedAt {
                    _ = try await container.updatePersonUseCase.execute(cloudPerson)
                }
            } else {
                _ = try await container.savePersonUseCase.execute(cloudPerson)
            }
        }

        // Fetch reminders
        let cloudReminders = try await firestoreService.fetchReminders(since: lastSyncDate)
        for cloudReminder in cloudReminders {
            _ = try await container.saveReminderUseCase.execute(cloudReminder)
        }
    }

    // MARK: - Full Sync (initial)

    func performInitialSync() async {
        guard authService.isSignedIn else { return }

        syncState = .syncing(progress: 0)

        do {
            // Push all local data to cloud
            let container = DIContainer.shared

            // Get all local memories
            let memories = try await container.getRecentMemoriesUseCase.execute(limit: 10000)
            syncState = .syncing(progress: 0.1)

            for (index, memory) in memories.enumerated() {
                if memory.syncStatus != .synced && memory.syncStatus != .localOnly {
                    var syncedMemory = memory
                    let updatedPhotos = try await cloudStorage.syncPhotos(for: memory)
                    syncedMemory.photos = updatedPhotos
                    syncedMemory.syncStatus = .synced
                    try await firestoreService.saveMemory(syncedMemory)
                    _ = try await container.updateMemoryUseCase.execute(syncedMemory)
                }
                let progress = 0.1 + (Double(index) / Double(max(memories.count, 1))) * 0.4
                syncState = .syncing(progress: progress)
            }

            syncState = .syncing(progress: 0.5)

            // Get all local persons
            let persons = try await container.getAllPersonsUseCase.execute()
            for person in persons {
                if person.syncStatus != .synced {
                    var syncedPerson = person
                    syncedPerson.syncStatus = .synced
                    try await firestoreService.savePerson(syncedPerson)
                    _ = try await container.updatePersonUseCase.execute(syncedPerson)
                }
            }

            syncState = .syncing(progress: 0.7)

            // Pull cloud data
            try await pullCloudChanges()

            syncState = .syncing(progress: 1.0)

            lastSyncDate = Date()
            saveLastSyncDate()
            pendingQueue.removeAll()
            pendingChanges = 0
            savePendingQueue()

            syncState = .synced
        } catch {
            syncState = .error(error.localizedDescription)
        }
    }

    // MARK: - Persistence

    private func savePendingQueue() {
        do {
            let data = try JSONEncoder().encode(pendingQueue)
            try data.write(to: queueFileURL)
        } catch {
            print("Failed to save sync queue: \(error)")
        }
    }

    private func loadPendingQueue() {
        do {
            let data = try Data(contentsOf: queueFileURL)
            pendingQueue = try JSONDecoder().decode([SyncChange].self, from: data)
            pendingChanges = pendingQueue.count
        } catch {
            pendingQueue = []
            pendingChanges = 0
        }
    }

    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
    }

    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }
}
