import UIKit
import Photos

/// Service for managing photo storage and operations
final class PhotoService {
    static let shared = PhotoService()

    private let fileManager = FileManager.default
    private let photosDirectory: URL
    private let thumbnailsDirectory: URL

    private let thumbnailSize: CGFloat = 300
    private let photoQuality: CGFloat = 0.85
    private let thumbnailQuality: CGFloat = 0.70
    private let maxPhotoSize: CGFloat = 2048

    private init() {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        photosDirectory = documentsDirectory.appendingPathComponent("photos", isDirectory: true)
        thumbnailsDirectory = documentsDirectory.appendingPathComponent("thumbnails", isDirectory: true)

        // Create directories if needed
        try? fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Save Photo

    /// Save photo from UIImage and generate thumbnail
    func savePhoto(image: UIImage) async -> Result<SavedPhoto, Error> {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    let photoId = UUID().uuidString
                    let photoURL = photosDirectory.appendingPathComponent("\(photoId).jpg")
                    let thumbnailURL = thumbnailsDirectory.appendingPathComponent("\(photoId)_thumb.jpg")

                    // Resize if needed and save photo
                    let resizedImage = resizeImageIfNeeded(image, maxSize: maxPhotoSize)
                    guard let photoData = resizedImage.jpegData(compressionQuality: photoQuality) else {
                        continuation.resume(returning: .failure(PhotoServiceError.cannotEncodeImage))
                        return
                    }
                    try photoData.write(to: photoURL)

                    // Generate and save thumbnail
                    let thumbnail = createThumbnail(from: image)
                    guard let thumbnailData = thumbnail.jpegData(compressionQuality: thumbnailQuality) else {
                        continuation.resume(returning: .failure(PhotoServiceError.cannotEncodeThumbnail))
                        return
                    }
                    try thumbnailData.write(to: thumbnailURL)

                    let savedPhoto = SavedPhoto(
                        id: photoId,
                        url: photoURL,
                        thumbnailUrl: thumbnailURL
                    )

                    continuation.resume(returning: .success(savedPhoto))
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }

    /// Save photo from Data
    func savePhoto(data: Data) async -> Result<SavedPhoto, Error> {
        guard let image = UIImage(data: data) else {
            return .failure(PhotoServiceError.cannotDecodeImage)
        }
        return await savePhoto(image: image)
    }

    /// Save photo from URL (for picking from library)
    func savePhoto(from url: URL) async -> Result<SavedPhoto, Error> {
        do {
            let data = try Data(contentsOf: url)
            return await savePhoto(data: data)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Retrieve Photos

    /// Get photo file URL by ID
    func getPhotoURL(photoId: String) -> URL? {
        let url = photosDirectory.appendingPathComponent("\(photoId).jpg")
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    /// Get thumbnail file URL by ID
    func getThumbnailURL(photoId: String) -> URL? {
        let url = thumbnailsDirectory.appendingPathComponent("\(photoId)_thumb.jpg")
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    /// Load photo image by ID
    func loadPhoto(photoId: String) -> UIImage? {
        guard let url = getPhotoURL(photoId: photoId) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    /// Load thumbnail image by ID
    func loadThumbnail(photoId: String) -> UIImage? {
        guard let url = getThumbnailURL(photoId: photoId) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    // MARK: - Delete Photo

    /// Delete photo and its thumbnail
    func deletePhoto(photoId: String) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    let photoURL = photosDirectory.appendingPathComponent("\(photoId).jpg")
                    let thumbnailURL = thumbnailsDirectory.appendingPathComponent("\(photoId)_thumb.jpg")

                    if fileManager.fileExists(atPath: photoURL.path) {
                        try fileManager.removeItem(at: photoURL)
                    }

                    if fileManager.fileExists(atPath: thumbnailURL.path) {
                        try fileManager.removeItem(at: thumbnailURL)
                    }

                    continuation.resume(returning: .success(()))
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }

    /// Delete multiple photos
    func deletePhotos(photoIds: [String]) async -> Result<Void, Error> {
        for photoId in photoIds {
            let result = await deletePhoto(photoId: photoId)
            if case .failure(let error) = result {
                return .failure(error)
            }
        }
        return .success(())
    }

    // MARK: - Management

    /// Get all photo IDs
    func getAllPhotoIds() -> [String] {
        guard let contents = try? fileManager.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: nil) else {
            return []
        }

        return contents
            .filter { $0.pathExtension == "jpg" }
            .map { $0.deletingPathExtension().lastPathComponent }
    }

    /// Get total storage used by photos in bytes
    func getStorageUsed() -> Int64 {
        var totalSize: Int64 = 0

        // Photos directory
        if let contents = try? fileManager.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for url in contents {
                if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(size)
                }
            }
        }

        // Thumbnails directory
        if let contents = try? fileManager.contentsOfDirectory(at: thumbnailsDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for url in contents {
                if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(size)
                }
            }
        }

        return totalSize
    }

    /// Format storage size for display
    func formatStorageSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Private Helpers

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

    private func createThumbnail(from image: UIImage) -> UIImage {
        let width = image.size.width
        let height = image.size.height

        let ratio = min(thumbnailSize / width, thumbnailSize / height)
        let newSize = CGSize(width: width * ratio, height: height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Models

/// Saved photo information
struct SavedPhoto: Identifiable, Equatable {
    let id: String
    let url: URL
    let thumbnailUrl: URL
}

/// Photo service errors
enum PhotoServiceError: LocalizedError {
    case cannotDecodeImage
    case cannotEncodeImage
    case cannotEncodeThumbnail
    case photoNotFound

    var errorDescription: String? {
        switch self {
        case .cannotDecodeImage:
            return "Cannot decode image"
        case .cannotEncodeImage:
            return "Cannot encode image"
        case .cannotEncodeThumbnail:
            return "Cannot encode thumbnail"
        case .photoNotFound:
            return "Photo not found"
        }
    }
}
