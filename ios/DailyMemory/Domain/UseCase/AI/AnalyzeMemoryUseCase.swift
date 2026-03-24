import Foundation

/// Use case for analyzing memory text with AI
/// Extracts entities like people, locations, dates, and amounts
final class AnalyzeMemoryUseCase {
    private let aiAnalysisService: AIAnalysisService

    init(aiAnalysisService: AIAnalysisService = .shared) {
        self.aiAnalysisService = aiAnalysisService
    }

    /// Analyze text and return extracted entities
    func execute(text: String) async -> Result<MemoryAnalysis, Error> {
        let result = await aiAnalysisService.analyzeText(text)

        switch result {
        case .success(let analysisResult):
            return .success(analysisResult.toMemoryAnalysis())
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Analyze and create a Memory object with extracted data
    func analyzeAndCreateMemory(
        content: String,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) async -> Result<Memory, Error> {
        let result = await aiAnalysisService.analyzeText(content)

        switch result {
        case .success(let analysisResult):
            let analysis = analysisResult.toMemoryAnalysis()

            let memory = Memory(
                content: content,
                extractedPersons: analysis.persons,
                extractedLocation: analysis.location,
                extractedDate: analysis.date,
                extractedAmount: analysis.amount,
                extractedTags: analysis.tags,
                category: analysis.category,
                recordedAt: Date(),
                recordedLatitude: latitude,
                recordedLongitude: longitude
            )

            return .success(memory)

        case .failure(let error):
            return .failure(error)
        }
    }
}

/// Data class for memory analysis results
struct MemoryAnalysis {
    let persons: [String]
    let location: String?
    let date: Date?
    let amount: Double?
    let tags: [String]
    let category: Category
    let summary: String
}

/// Extension to convert API result to domain model
extension AnalysisResult {
    func toMemoryAnalysis() -> MemoryAnalysis {
        // Parse date if present
        var parsedDate: Date?
        if let dateString = date {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            parsedDate = formatter.date(from: dateString)

            // Try without fractional seconds
            if parsedDate == nil {
                formatter.formatOptions = [.withInternetDateTime]
                parsedDate = formatter.date(from: dateString)
            }

            // Try date only
            if parsedDate == nil {
                formatter.formatOptions = [.withFullDate]
                parsedDate = formatter.date(from: dateString)
            }
        }

        // Parse category
        let parsedCategory = Category(rawValue: category.uppercased()) ?? .general

        return MemoryAnalysis(
            persons: persons,
            location: location,
            date: parsedDate,
            amount: amount,
            tags: tags,
            category: parsedCategory,
            summary: summary
        )
    }
}
