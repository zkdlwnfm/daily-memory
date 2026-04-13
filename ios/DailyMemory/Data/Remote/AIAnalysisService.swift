import Foundation

/// AI Analysis Service for extracting entities from text
/// Supports both OpenAI and Claude APIs
actor AIAnalysisService {
    static let shared = AIAnalysisService()

    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Analysis

    /// Analyze text via backend API (falls back to simulation if offline)
    func analyzeText(_ text: String) async -> Result<AnalysisResult, Error> {
        // Try backend API first
        do {
            let response: AnalysisResponse = try await apiClient.post("ai/analyze", body: ["text": text])
            let personsWithRel = response.persons.map { PersonWithRelationship(from: $0) }
            let extractedTasks = (response.tasks ?? []).map { task in
                ExtractedTask(
                    title: task.title,
                    description: task.description,
                    dueDate: task.dueDate,
                    urgency: task.urgency,
                    importance: task.importance,
                    relatedPerson: task.relatedPerson
                )
            }
            let result = AnalysisResult(
                persons: response.persons.map { $0.name },
                location: response.location,
                date: response.date,
                amount: response.amount,
                tags: response.tags,
                category: response.category,
                mood: response.mood,
                moodScore: response.moodScore,
                summary: response.summary,
                personsWithRelationship: personsWithRel,
                extractedTasks: extractedTasks
            )
            return .success(result)
        } catch {
            print("[AIAnalysis] Backend API error: \(error)")
            // Fallback to simulation on error (offline, rate limited, etc.)
            return .success(simulateAnalysis(text))
        }
    }

    // MARK: - Legacy Response Parsing (kept for reference)

    private func parseAnalysisResponse(_ data: Data) throws -> AnalysisResult {
        // Parse the API response to extract the content
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIAnalysisError.invalidResponse
        }

        // Extract content from Claude or OpenAI response
        var content: String?

        // Claude format
        if let contentArray = json["content"] as? [[String: Any]],
           let firstContent = contentArray.first,
           let text = firstContent["text"] as? String {
            content = text
        }

        // OpenAI format
        if content == nil,
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let text = message["content"] as? String {
            content = text
        }

        guard let contentString = content else {
            throw AIAnalysisError.invalidResponse
        }

        // Extract JSON from content
        guard let jsonStart = contentString.firstIndex(of: "{"),
              let jsonEnd = contentString.lastIndex(of: "}") else {
            throw AIAnalysisError.invalidResponse
        }

        let jsonString = String(contentString[jsonStart...jsonEnd])
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIAnalysisError.invalidResponse
        }

        return try JSONDecoder().decode(AnalysisResult.self, from: jsonData)
    }

    // MARK: - Simulation

    /// Simulate AI analysis for testing/demo purposes
    private func simulateAnalysis(_ text: String) -> AnalysisResult {
        let lowerText = text.lowercased()

        // Extract names (simple heuristic: capitalized words)
        let namePattern = try? NSRegularExpression(pattern: "\\b([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)?)\\b")
        let range = NSRange(text.startIndex..., in: text)
        let matches = namePattern?.matches(in: text, range: range) ?? []

        let persons = matches.compactMap { match -> String? in
            guard let range = Range(match.range, in: text) else { return nil }
            let name = String(text[range])
            if name.count > 2 && !Self.commonWords.contains(name.lowercased()) {
                return name
            }
            return nil
        }
        .removingDuplicates()

        // Extract location
        var location: String?
        let locationKeywords = ["at ", "in ", "near ", "to "]
        for keyword in locationKeywords {
            if let range = lowerText.range(of: keyword) {
                let remaining = String(text[range.upperBound...])
                if let endIndex = remaining.firstIndex(where: { ".!?,\n".contains($0) }) {
                    location = String(remaining[..<endIndex]).trimmingCharacters(in: .whitespaces)
                } else {
                    location = remaining.split(separator: " ").prefix(3).joined(separator: " ")
                }
                if let loc = location, !loc.isEmpty { break }
            }
        }

        // Extract amount
        let amountPattern = try? NSRegularExpression(pattern: "\\$([\\d,]+(?:\\.\\d{2})?)")
        let amountMatch = amountPattern?.firstMatch(in: text, range: range)
        var amount: Double?
        if let match = amountMatch, let range = Range(match.range(at: 1), in: text) {
            let amountString = String(text[range]).replacingOccurrences(of: ",", with: "")
            amount = Double(amountString)
        }

        // Determine category
        let category: Category
        if lowerText.contains("wedding") || lowerText.contains("birthday") ||
           lowerText.contains("party") || lowerText.contains("anniversary") {
            category = .event
        } else if lowerText.contains("meeting") || lowerText.contains("lunch") ||
                  lowerText.contains("dinner") || lowerText.contains("met") {
            category = .meeting
        } else if lowerText.contains("pay") || lowerText.contains("owe") ||
                  lowerText.contains("money") || amount != nil {
            category = .financial
        } else if lowerText.contains("promise") || lowerText.contains("will") ||
                  lowerText.contains("remind") || lowerText.contains("todo") {
            category = .promise
        } else {
            category = .general
        }

        // Generate tags
        var tags: [String] = []
        if !persons.isEmpty { tags.append("people") }
        if location != nil { tags.append("location") }
        if amount != nil { tags.append("money") }
        if lowerText.contains("gift") { tags.append("gift") }
        if lowerText.contains("work") || lowerText.contains("office") { tags.append("work") }
        if lowerText.contains("family") { tags.append("family") }

        // Generate summary
        let summary = String(text.prefix(100)) + (text.count > 100 ? "..." : "")

        // Extract simulated tasks from promise-like content
        var simulatedTasks: [ExtractedTask] = []
        let promiseKeywords = ["need to", "have to", "should", "must", "will", "promise", "remind me", "don't forget"]
        for keyword in promiseKeywords {
            if lowerText.contains(keyword) {
                let taskTitle = String(text.prefix(60)).trimmingCharacters(in: .whitespaces)
                simulatedTasks.append(ExtractedTask(
                    title: taskTitle,
                    description: nil,
                    dueDate: nil,
                    urgency: 3,
                    importance: 3,
                    relatedPerson: persons.first
                ))
                break
            }
        }

        return AnalysisResult(
            persons: persons,
            location: location,
            date: nil,
            amount: amount,
            tags: tags,
            category: category.rawValue,
            summary: summary,
            extractedTasks: simulatedTasks
        )
    }

    // MARK: - Constants

    private static let commonWords: Set<String> = [
        "the", "and", "but", "for", "not", "you", "all", "can", "had", "her",
        "was", "one", "our", "out", "day", "get", "has", "him", "his", "how",
        "its", "may", "new", "now", "old", "see", "two", "way", "who", "boy",
        "did", "got", "let", "put", "say", "she", "too", "use", "monday",
        "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
        "january", "february", "march", "april", "june", "july", "august",
        "september", "october", "november", "december", "today", "yesterday"
    ]
}

// MARK: - Analysis Result

struct PersonWithRelationship {
    let name: String
    let relationship: Relationship

    init(name: String, relationship: Relationship = .other) {
        self.name = name
        self.relationship = relationship
    }

    init(from extracted: PersonExtracted) {
        self.name = extracted.name
        self.relationship = Relationship(rawValue: extracted.relationship) ?? .other
    }
}

struct AnalysisResult: Codable {
    let persons: [String]
    let location: String?
    let date: String?
    let amount: Double?
    let tags: [String]
    let category: String
    let mood: String?
    let moodScore: Int?
    let summary: String

    // Non-codable: relationship info from AI
    var personsWithRelationship: [PersonWithRelationship] = []
    // AI-extracted tasks/promises
    var extractedTasks: [ExtractedTask] = []

    enum CodingKeys: String, CodingKey {
        case persons, location, date, amount, tags, category, mood, moodScore, summary, extractedTasks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        persons = try container.decodeIfPresent([String].self, forKey: .persons) ?? []
        location = try container.decodeIfPresent(String.self, forKey: .location)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        amount = try container.decodeIfPresent(Double.self, forKey: .amount)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "GENERAL"
        mood = try container.decodeIfPresent(String.self, forKey: .mood)
        moodScore = try container.decodeIfPresent(Int.self, forKey: .moodScore)
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        extractedTasks = try container.decodeIfPresent([ExtractedTask].self, forKey: .extractedTasks) ?? []
        personsWithRelationship = []
    }

    init(
        persons: [String] = [],
        location: String? = nil,
        date: String? = nil,
        amount: Double? = nil,
        tags: [String] = [],
        category: String = "GENERAL",
        mood: String? = nil,
        moodScore: Int? = nil,
        summary: String = "",
        personsWithRelationship: [PersonWithRelationship] = [],
        extractedTasks: [ExtractedTask] = []
    ) {
        self.persons = persons
        self.location = location
        self.date = date
        self.amount = amount
        self.tags = tags
        self.category = category
        self.mood = mood
        self.moodScore = moodScore
        self.summary = summary
        self.personsWithRelationship = personsWithRelationship
        self.extractedTasks = extractedTasks
    }
}

// MARK: - Errors
enum AIAnalysisError: LocalizedError {
    case invalidResponse
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from AI service"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Array Extension
private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
