import Foundation

/// AI Analysis Service for extracting entities from text
/// Supports both OpenAI and Claude APIs
actor AIAnalysisService {
    static let shared = AIAnalysisService()

    // MARK: - Configuration
    enum AIProvider {
        case openAI
        case claude
    }

    private var apiKey: String = ""
    private var apiProvider: AIProvider = .claude

    private let session: URLSession

    // MARK: - Initialization
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Configuration

    /// Configure the AI service with API credentials
    func configure(apiKey: String, provider: AIProvider = .claude) {
        self.apiKey = apiKey
        self.apiProvider = provider
    }

    // MARK: - Analysis

    /// Analyze text and extract entities
    func analyzeText(_ text: String) async -> Result<AnalysisResult, Error> {
        if apiKey.isEmpty {
            // Return simulated result when no API key is configured
            return .success(simulateAnalysis(text))
        }

        do {
            let result: AnalysisResult
            switch apiProvider {
            case .openAI:
                result = try await analyzeWithOpenAI(text)
            case .claude:
                result = try await analyzeWithClaude(text)
            }
            return .success(result)
        } catch {
            // Fallback to simulation on error
            return .success(simulateAnalysis(text))
        }
    }

    // MARK: - Claude API

    private func analyzeWithClaude(_ text: String) async throws -> AnalysisResult {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let prompt = buildAnalysisPrompt(text)
        let body: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        return try parseAnalysisResponse(data)
    }

    // MARK: - OpenAI API

    private func analyzeWithOpenAI(_ text: String) async throws -> AnalysisResult {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let prompt = buildAnalysisPrompt(text)
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that extracts structured information from text."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        return try parseAnalysisResponse(data)
    }

    // MARK: - Prompt Building

    private func buildAnalysisPrompt(_ text: String) -> String {
        """
        Analyze the following text and extract structured information.
        Return a JSON object with these fields:
        - persons: array of person names mentioned
        - location: the main location mentioned (or null)
        - date: any specific date mentioned in ISO format (or null)
        - amount: any monetary amount mentioned as a number (or null)
        - tags: array of relevant keywords/topics
        - category: one of EVENT, PROMISE, MEETING, FINANCIAL, GENERAL
        - summary: a brief one-sentence summary

        Text: "\(text)"

        Respond ONLY with valid JSON, no additional text.
        """
    }

    // MARK: - Response Parsing

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

        return AnalysisResult(
            persons: persons,
            location: location,
            date: nil,
            amount: amount,
            tags: tags,
            category: category.rawValue,
            summary: summary
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
struct AnalysisResult: Codable {
    let persons: [String]
    let location: String?
    let date: String?
    let amount: Double?
    let tags: [String]
    let category: String
    let summary: String

    init(
        persons: [String] = [],
        location: String? = nil,
        date: String? = nil,
        amount: Double? = nil,
        tags: [String] = [],
        category: String = "GENERAL",
        summary: String = ""
    ) {
        self.persons = persons
        self.location = location
        self.date = date
        self.amount = amount
        self.tags = tags
        self.category = category
        self.summary = summary
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
