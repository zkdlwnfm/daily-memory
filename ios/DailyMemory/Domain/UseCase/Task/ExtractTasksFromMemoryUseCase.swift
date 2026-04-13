import Foundation

/// Use case for converting AI-extracted tasks into domain Task objects.
/// Matches related persons and assigns quadrant classification.
final class ExtractTasksFromMemoryUseCase {
    private let classifyQuadrant: ClassifyTaskQuadrantUseCase
    private let personRepository: PersonRepository

    init(
        classifyQuadrant: ClassifyTaskQuadrantUseCase = ClassifyTaskQuadrantUseCase(),
        personRepository: PersonRepository = PersonRepositoryImpl()
    ) {
        self.classifyQuadrant = classifyQuadrant
        self.personRepository = personRepository
    }

    func execute(memoryId: String, extractedTasks: [ExtractedTask]) async throws -> [MemoryTask] {
        let allPersons = try await personRepository.getAll(sortedBy: .alphabetical)

        return extractedTasks.map { extracted in
            let quadrant = classifyQuadrant.execute(
                urgency: extracted.urgency,
                importance: extracted.importance
            )

            // Match relatedPerson name to existing Person entity
            let matchedPersonId: String? = extracted.relatedPerson.flatMap { (name: String) -> String? in
                allPersons.first(where: { person in
                    person.name.localizedCaseInsensitiveContains(name) ||
                    name.localizedCaseInsensitiveContains(person.name)
                })?.id
            }

            // Parse due date from ISO 8601 string
            let dueDate = extracted.dueDate.flatMap { dateString in
                ISO8601DateFormatter().date(from: dateString)
                    ?? DateFormatter.yearMonthDay.date(from: dateString)
            }

            let confidence = Float(extracted.urgency + extracted.importance) / 10.0

            return MemoryTask(
                memoryId: memoryId,
                personId: matchedPersonId,
                title: extracted.title,
                description: extracted.description,
                dueDate: dueDate,
                quadrant: quadrant,
                status: .open,
                isAISuggested: true,
                aiConfidence: confidence
            )
        }
    }
}

private extension DateFormatter {
    static let yearMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
