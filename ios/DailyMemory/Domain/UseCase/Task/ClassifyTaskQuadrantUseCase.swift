import Foundation

/// Use case for classifying a task into an Eisenhower Matrix quadrant
/// based on urgency and importance scores (1-5 each).
final class ClassifyTaskQuadrantUseCase {
    private let threshold: Int

    init(threshold: Int = 3) {
        self.threshold = threshold
    }

    func execute(urgency: Int, importance: Int) -> EisenhowerQuadrant {
        let isUrgent = urgency >= threshold
        let isImportant = importance >= threshold

        switch (isUrgent, isImportant) {
        case (true, true):   return .q1_urgentImportant
        case (false, true):  return .q2_importantNotUrgent
        case (true, false):  return .q3_urgentNotImportant
        case (false, false): return .q4_neither
        }
    }
}
