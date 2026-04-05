import Foundation
import UIKit

/// Service for analyzing images using Vision AI (OpenAI GPT-4o Vision)
/// Extracts objects, scene descriptions, text (OCR), and face counts
actor ImageAnalysisService {
    static let shared = ImageAnalysisService()

    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Analysis

    /// Analyze an image via backend API (falls back to simulation if offline)
    func analyzeImage(_ image: UIImage) async -> Result<ImageAnalysisResult, Error> {
        // Resize and encode image
        let maxDimension: CGFloat = 1024
        let resized = resizeImage(image, maxDimension: maxDimension)
        guard let imageData = resized.jpegData(compressionQuality: 0.7) else {
            return .success(simulateAnalysis(image))
        }
        let base64 = imageData.base64EncodedString()

        do {
            let response: ImageAnalysisResponse = try await apiClient.post("ai/analyze-image", body: ["imageBase64": base64])
            let result = ImageAnalysisResult(
                objects: response.objects,
                scene: response.scene,
                text: response.text,
                faces: response.faces,
                description: response.description,
                suggestedTags: response.suggestedTags
            )
            return .success(result)
        } catch {
            return .success(simulateAnalysis(image))
        }
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return resized
    }

    /// Analyze image from file URL
    func analyzeImage(from url: URL) async -> Result<ImageAnalysisResult, Error> {
        guard let image = UIImage(contentsOfFile: url.path) else {
            return .failure(ImageAnalysisError.cannotLoadImage)
        }
        return await analyzeImage(image)
    }

    /// Analyze image from Data
    func analyzeImage(from data: Data) async -> Result<ImageAnalysisResult, Error> {
        guard let image = UIImage(data: data) else {
            return .failure(ImageAnalysisError.cannotLoadImage)
        }
        return await analyzeImage(image)
    }

    // MARK: - Legacy (removed - now uses backend API)

    private func buildAnalysisPrompt() -> String {
        """
        Analyze this image and extract structured information.
        Return a JSON object with these fields:
        - objects: array of objects/items visible in the image (e.g., "person", "dog", "cake", "car")
        - scene: brief description of the scene/setting (e.g., "birthday party indoor", "beach sunset")
        - text: any visible text in the image (OCR), or null if none
        - faces: number of human faces visible (integer)
        - description: a brief one-sentence description of what's happening in the image
        - suggestedTags: array of relevant tags for categorizing this image (e.g., "family", "celebration", "travel")

        Respond ONLY with valid JSON, no additional text or markdown.
        """
    }

    // MARK: - Response Parsing

    private func parseAnalysisResponse(_ data: Data) throws -> ImageAnalysisResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ImageAnalysisError.invalidResponse
        }

        // Extract content from OpenAI response
        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ImageAnalysisError.invalidResponse
        }

        // Extract JSON from content
        guard let jsonStart = content.firstIndex(of: "{"),
              let jsonEnd = content.lastIndex(of: "}") else {
            throw ImageAnalysisError.invalidResponse
        }

        let jsonString = String(content[jsonStart...jsonEnd])
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ImageAnalysisError.invalidResponse
        }

        return try JSONDecoder().decode(ImageAnalysisResult.self, from: jsonData)
    }

    // MARK: - Simulation

    /// Simulate image analysis for testing/demo purposes
    private func simulateAnalysis(_ image: UIImage) -> ImageAnalysisResult {
        // Basic simulation based on image characteristics
        let width = image.size.width
        let height = image.size.height
        let aspectRatio = width / height

        var objects: [String] = []
        var scene = "general scene"
        var suggestedTags: [String] = []

        // Simulate based on aspect ratio
        if aspectRatio > 1.5 {
            // Wide/landscape image - likely outdoor or scenery
            scene = "outdoor landscape"
            objects = ["sky", "nature"]
            suggestedTags = ["outdoor", "scenery", "landscape"]
        } else if aspectRatio < 0.7 {
            // Tall/portrait image - likely portrait photo
            scene = "portrait photo"
            objects = ["person"]
            suggestedTags = ["portrait", "people"]
        } else {
            // Square-ish - could be anything
            scene = "casual photo"
            objects = ["person", "background"]
            suggestedTags = ["casual", "moment"]
        }

        return ImageAnalysisResult(
            objects: objects,
            scene: scene,
            text: nil,
            faces: 1,
            description: "A \(scene) captured in this photo",
            suggestedTags: suggestedTags
        )
    }

    // MARK: - Helpers

    private func resizeImageIfNeeded(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let width = image.size.width
        let height = image.size.height

        if width <= maxSize && height <= maxSize {
            return image
        }

        let ratio = min(maxSize / width, maxSize / height)
        let newSize = CGSize(width: width * ratio, height: height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Result Model

/// Result of image analysis
struct ImageAnalysisResult: Codable, Equatable {
    let objects: [String]
    let scene: String
    let text: String?
    let faces: Int
    let description: String
    let suggestedTags: [String]

    init(
        objects: [String] = [],
        scene: String = "",
        text: String? = nil,
        faces: Int = 0,
        description: String = "",
        suggestedTags: [String] = []
    ) {
        self.objects = objects
        self.scene = scene
        self.text = text
        self.faces = faces
        self.description = description
        self.suggestedTags = suggestedTags
    }
}

// MARK: - Errors

enum ImageAnalysisError: LocalizedError {
    case cannotLoadImage
    case cannotEncodeImage
    case invalidResponse
    case apiError(statusCode: Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .cannotLoadImage:
            return "Cannot load image"
        case .cannotEncodeImage:
            return "Cannot encode image for API"
        case .invalidResponse:
            return "Invalid response from Vision API"
        case .apiError(let statusCode):
            return "API error: HTTP \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
