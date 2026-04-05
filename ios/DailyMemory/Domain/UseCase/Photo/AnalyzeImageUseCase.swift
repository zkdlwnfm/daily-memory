import Foundation
import UIKit

/// Use case for analyzing images with AI
/// Extracts objects, scenes, text, and generates tags
final class AnalyzeImageUseCase {
    private let imageAnalysisService: ImageAnalysisService

    init(imageAnalysisService: ImageAnalysisService = .shared) {
        self.imageAnalysisService = imageAnalysisService
    }

    /// Analyze a single image and return results
    func execute(image: UIImage) async -> Result<PhotoAnalysis, Error> {
        let result = await imageAnalysisService.analyzeImage(image)

        switch result {
        case .success(let analysisResult):
            return .success(analysisResult.toPhotoAnalysis())
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Analyze image from file URL
    func execute(imageURL: URL) async -> Result<PhotoAnalysis, Error> {
        let result = await imageAnalysisService.analyzeImage(from: imageURL)

        switch result {
        case .success(let analysisResult):
            return .success(analysisResult.toPhotoAnalysis())
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Analyze multiple images and combine results
    func execute(images: [UIImage]) async -> Result<[PhotoAnalysis], Error> {
        var results: [PhotoAnalysis] = []

        for image in images {
            let result = await imageAnalysisService.analyzeImage(image)
            switch result {
            case .success(let analysisResult):
                results.append(analysisResult.toPhotoAnalysis())
            case .failure(let error):
                return .failure(error)
            }
        }

        return .success(results)
    }

    /// Analyze images and merge into combined analysis
    func executeAndMerge(images: [UIImage]) async -> Result<CombinedPhotoAnalysis, Error> {
        let results = await execute(images: images)

        switch results {
        case .success(let analyses):
            return .success(CombinedPhotoAnalysis.merge(analyses))
        case .failure(let error):
            return .failure(error)
        }
    }
}

// MARK: - Photo Analysis Model

/// Analysis result for a single photo
struct PhotoAnalysis: Equatable {
    let objects: [String]
    let scene: String
    let ocrText: String?
    let faceCount: Int
    let description: String
    let suggestedTags: [String]

    /// Check if people were detected
    var hasPeople: Bool {
        faceCount > 0 || objects.contains { $0.lowercased().contains("person") }
    }

    /// Check if text was detected
    var hasText: Bool {
        ocrText != nil && !ocrText!.isEmpty
    }
}

/// Combined analysis from multiple photos
struct CombinedPhotoAnalysis: Equatable {
    let allObjects: [String]
    let scenes: [String]
    let allOcrText: [String]
    let totalFaces: Int
    let descriptions: [String]
    let mergedTags: [String]

    /// Merge multiple photo analyses into one
    static func merge(_ analyses: [PhotoAnalysis]) -> CombinedPhotoAnalysis {
        var allObjects: Set<String> = []
        var scenes: [String] = []
        var allOcrText: [String] = []
        var totalFaces = 0
        var descriptions: [String] = []
        var allTags: Set<String> = []

        for analysis in analyses {
            allObjects.formUnion(analysis.objects)
            scenes.append(analysis.scene)
            if let text = analysis.ocrText, !text.isEmpty {
                allOcrText.append(text)
            }
            totalFaces += analysis.faceCount
            descriptions.append(analysis.description)
            allTags.formUnion(analysis.suggestedTags)
        }

        return CombinedPhotoAnalysis(
            allObjects: Array(allObjects).sorted(),
            scenes: scenes,
            allOcrText: allOcrText,
            totalFaces: totalFaces,
            descriptions: descriptions,
            mergedTags: Array(allTags).sorted()
        )
    }
}

// MARK: - Extension

extension ImageAnalysisResult {
    func toPhotoAnalysis() -> PhotoAnalysis {
        PhotoAnalysis(
            objects: objects,
            scene: scene,
            ocrText: text,
            faceCount: faces,
            description: description,
            suggestedTags: suggestedTags
        )
    }
}
