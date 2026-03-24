import Foundation

/// Service for exporting memories to various formats
final class ExportService {
    static let shared = ExportService()

    private let fileManager = FileManager.default
    private let exportDirectory: URL

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()

    private init() {
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        exportDirectory = cacheDir.appendingPathComponent("exports", isDirectory: true)
        try? fileManager.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
    }

    // MARK: - JSON Export

    /// Export memories to JSON format
    func exportToJson(memories: [Memory], persons: [Person] = []) async -> Result<ExportResult, Error> {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    let timestamp = displayDateFormatter.string(from: Date())
                    let fileName = "dailymemory_export_\(timestamp).json"
                    let fileURL = exportDirectory.appendingPathComponent(fileName)

                    let exportData: [String: Any] = [
                        "exportDate": dateFormatter.string(from: Date()),
                        "version": "1.0",
                        "memoriesCount": memories.count,
                        "personsCount": persons.count,
                        "memories": memories.map { memoryToDict($0) },
                        "persons": persons.map { personToDict($0) }
                    ]

                    let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
                    try jsonData.write(to: fileURL)

                    let result = ExportResult(
                        url: fileURL,
                        fileName: fileName,
                        mimeType: "application/json",
                        itemCount: memories.count
                    )

                    continuation.resume(returning: .success(result))
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }

    // MARK: - CSV Export

    /// Export memories to CSV format
    func exportToCsv(memories: [Memory]) async -> Result<ExportResult, Error> {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    let timestamp = displayDateFormatter.string(from: Date())
                    let fileName = "dailymemory_export_\(timestamp).csv"
                    let fileURL = exportDirectory.appendingPathComponent(fileName)

                    var csvContent = "ID,Date,Time,Content,Category,Importance,Location,Amount,Persons,Tags,IsLocked\n"

                    let csvDateFormatter = DateFormatter()
                    csvDateFormatter.dateFormat = "yyyy-MM-dd"

                    let csvTimeFormatter = DateFormatter()
                    csvTimeFormatter.dateFormat = "HH:mm:ss"

                    for memory in memories {
                        let row = [
                            escapeCsv(memory.id),
                            csvDateFormatter.string(from: memory.recordedAt),
                            csvTimeFormatter.string(from: memory.recordedAt),
                            escapeCsv(memory.content),
                            memory.category.rawValue,
                            String(memory.importance),
                            escapeCsv(memory.extractedLocation ?? ""),
                            memory.extractedAmount.map { String($0) } ?? "",
                            escapeCsv(memory.extractedPersons.joined(separator: "; ")),
                            escapeCsv(memory.extractedTags.joined(separator: "; ")),
                            String(memory.isLocked)
                        ].joined(separator: ",")

                        csvContent += row + "\n"
                    }

                    try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)

                    let result = ExportResult(
                        url: fileURL,
                        fileName: fileName,
                        mimeType: "text/csv",
                        itemCount: memories.count
                    )

                    continuation.resume(returning: .success(result))
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }

    // MARK: - Date Range Export

    /// Export memories for a specific date range
    func exportDateRange(
        memories: [Memory],
        startDate: Date,
        endDate: Date,
        format: ExportFormat
    ) async -> Result<ExportResult, Error> {
        let filteredMemories = memories.filter { memory in
            memory.recordedAt >= startDate && memory.recordedAt <= endDate
        }

        switch format {
        case .json:
            return await exportToJson(memories: filteredMemories)
        case .csv:
            return await exportToCsv(memories: filteredMemories)
        }
    }

    // MARK: - Cleanup

    /// Clean up old export files
    func cleanupExports() {
        guard let contents = try? fileManager.contentsOfDirectory(at: exportDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return
        }

        let oneDayAgo = Date().addingTimeInterval(-24 * 60 * 60)

        for url in contents {
            if let modificationDate = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
               modificationDate < oneDayAgo {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    // MARK: - Private Helpers

    private func memoryToDict(_ memory: Memory) -> [String: Any] {
        var dict: [String: Any] = [
            "id": memory.id,
            "content": memory.content,
            "category": memory.category.rawValue,
            "importance": memory.importance,
            "isLocked": memory.isLocked,
            "recordedAt": dateFormatter.string(from: memory.recordedAt),
            "createdAt": dateFormatter.string(from: memory.createdAt),
            "updatedAt": dateFormatter.string(from: memory.updatedAt)
        ]

        if let location = memory.extractedLocation {
            dict["extractedLocation"] = location
        }
        if let amount = memory.extractedAmount {
            dict["extractedAmount"] = amount
        }
        if let lat = memory.recordedLatitude {
            dict["latitude"] = lat
        }
        if let lng = memory.recordedLongitude {
            dict["longitude"] = lng
        }
        if !memory.extractedPersons.isEmpty {
            dict["extractedPersons"] = memory.extractedPersons
        }
        if !memory.extractedTags.isEmpty {
            dict["extractedTags"] = memory.extractedTags
        }
        if !memory.personIds.isEmpty {
            dict["personIds"] = memory.personIds
        }
        if !memory.photos.isEmpty {
            dict["photos"] = memory.photos.map { photo in
                var photoDict: [String: Any] = [
                    "id": photo.id,
                    "url": photo.url
                ]
                if let thumbnailUrl = photo.thumbnailUrl {
                    photoDict["thumbnailUrl"] = thumbnailUrl
                }
                if let aiAnalysis = photo.aiAnalysis {
                    photoDict["aiAnalysis"] = aiAnalysis
                }
                return photoDict
            }
        }

        return dict
    }

    private func personToDict(_ person: Person) -> [String: Any] {
        var dict: [String: Any] = [
            "id": person.id,
            "name": person.name,
            "relationship": person.relationship.rawValue
        ]

        if let nickname = person.nickname {
            dict["nickname"] = nickname
        }
        if let phone = person.phone {
            dict["phone"] = phone
        }
        if let email = person.email {
            dict["email"] = email
        }
        if let memo = person.memo {
            dict["memo"] = memo
        }
        if let profileImageUrl = person.profileImageUrl {
            dict["profileImageUrl"] = profileImageUrl
        }

        return dict
    }

    private func escapeCsv(_ value: String) -> String {
        let needsQuotes = value.contains(",") || value.contains("\"") || value.contains("\n")
        if needsQuotes {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

// MARK: - Models

struct ExportResult {
    let url: URL
    let fileName: String
    let mimeType: String
    let itemCount: Int
}

enum ExportFormat {
    case json
    case csv
}
