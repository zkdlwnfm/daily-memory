import Foundation
import FirebaseStorage
import FirebaseAuth
import UIKit

/// Firebase Storage service for uploading/downloading photos and files
final class CloudStorageService {
    static let shared = CloudStorageService()

    private let storage = Storage.storage()
    private let authService = AuthService.shared

    var userId: String? {
        Auth.auth().currentUser?.uid
    }

    private init() {}

    // MARK: - Photo Upload

    /// Upload a photo and return its cloud URL
    func uploadPhoto(memoryId: String, photoId: String, imageData: Data) async throws -> String {
        guard let uid = userId else {
            throw CloudStorageError.notAuthenticated
        }

        let path = "users/\(uid)/memories/\(memoryId)/photos/\(photoId).jpg"
        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await ref.downloadURL()
        return downloadURL.absoluteString
    }

    /// Upload a thumbnail
    func uploadThumbnail(memoryId: String, photoId: String, imageData: Data) async throws -> String {
        guard let uid = userId else {
            throw CloudStorageError.notAuthenticated
        }

        let path = "users/\(uid)/memories/\(memoryId)/thumbnails/\(photoId).jpg"
        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await ref.downloadURL()
        return downloadURL.absoluteString
    }

    /// Upload a photo from local file URL
    func uploadPhotoFromFile(memoryId: String, photoId: String, fileURL: URL) async throws -> String {
        guard let imageData = try? Data(contentsOf: fileURL) else {
            throw CloudStorageError.fileNotFound
        }
        return try await uploadPhoto(memoryId: memoryId, photoId: photoId, imageData: imageData)
    }

    // MARK: - Photo Download

    /// Download photo data by cloud URL
    func downloadPhoto(url: String) async throws -> Data {
        let ref = storage.reference(forURL: url)
        let maxSize: Int64 = 10 * 1024 * 1024 // 10MB
        return try await ref.data(maxSize: maxSize)
    }

    /// Download and save photo to local file
    func downloadPhotoToFile(url: String, localPath: URL) async throws {
        let data = try await downloadPhoto(url: url)
        try data.write(to: localPath)
    }

    // MARK: - Photo Delete

    /// Delete a photo from cloud storage
    func deletePhoto(memoryId: String, photoId: String) async throws {
        guard let uid = userId else {
            throw CloudStorageError.notAuthenticated
        }

        let photoPath = "users/\(uid)/memories/\(memoryId)/photos/\(photoId).jpg"
        let thumbnailPath = "users/\(uid)/memories/\(memoryId)/thumbnails/\(photoId).jpg"

        // Delete both photo and thumbnail
        do {
            try await storage.reference().child(photoPath).delete()
        } catch {
            // Photo might not exist, continue
        }

        do {
            try await storage.reference().child(thumbnailPath).delete()
        } catch {
            // Thumbnail might not exist, continue
        }
    }

    /// Delete all photos for a memory
    func deleteAllPhotos(memoryId: String) async throws {
        guard let uid = userId else {
            throw CloudStorageError.notAuthenticated
        }

        let photosRef = storage.reference().child("users/\(uid)/memories/\(memoryId)/photos")
        let thumbnailsRef = storage.reference().child("users/\(uid)/memories/\(memoryId)/thumbnails")

        // List and delete all photos
        do {
            let photoList = try await photosRef.listAll()
            for item in photoList.items {
                try await item.delete()
            }
        } catch {
            // Folder might not exist
        }

        do {
            let thumbList = try await thumbnailsRef.listAll()
            for item in thumbList.items {
                try await item.delete()
            }
        } catch {
            // Folder might not exist
        }
    }

    // MARK: - Profile Photo

    func uploadProfilePhoto(imageData: Data) async throws -> String {
        guard let uid = userId else {
            throw CloudStorageError.notAuthenticated
        }

        let path = "users/\(uid)/profile/avatar.jpg"
        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await ref.downloadURL()
        return downloadURL.absoluteString
    }

    // MARK: - Sync Helpers

    /// Upload all local photos for a memory to cloud
    func syncPhotos(for memory: Memory) async throws -> [Photo] {
        var updatedPhotos: [Photo] = []

        for photo in memory.photos {
            var updatedPhoto = photo

            // Check if URL is local (not already a cloud URL)
            if !photo.url.hasPrefix("https://") && !photo.url.hasPrefix("gs://") {
                let localURL = URL(fileURLWithPath: photo.url)
                if let data = try? Data(contentsOf: localURL) {
                    let cloudURL = try await uploadPhoto(
                        memoryId: memory.id,
                        photoId: photo.id,
                        imageData: data
                    )
                    updatedPhoto.url = cloudURL
                }
            }

            // Upload thumbnail if local
            if let thumbnailUrl = photo.thumbnailUrl,
               !thumbnailUrl.hasPrefix("https://") && !thumbnailUrl.hasPrefix("gs://") {
                let localURL = URL(fileURLWithPath: thumbnailUrl)
                if let data = try? Data(contentsOf: localURL) {
                    let cloudURL = try await uploadThumbnail(
                        memoryId: memory.id,
                        photoId: photo.id,
                        imageData: data
                    )
                    updatedPhoto.thumbnailUrl = cloudURL
                }
            }

            updatedPhotos.append(updatedPhoto)
        }

        return updatedPhotos
    }

    // MARK: - Storage Usage

    func getStorageUsage() async throws -> Int64 {
        guard let uid = userId else {
            throw CloudStorageError.notAuthenticated
        }

        let ref = storage.reference().child("users/\(uid)")
        let list = try await ref.listAll()

        var totalSize: Int64 = 0
        for item in list.items {
            let metadata = try await item.getMetadata()
            totalSize += metadata.size
        }

        return totalSize
    }
}

// MARK: - Errors

enum CloudStorageError: LocalizedError {
    case notAuthenticated
    case fileNotFound
    case uploadFailed(String)
    case downloadFailed(String)
    case sizeLimitExceeded

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not authenticated. Please sign in first."
        case .fileNotFound: return "File not found at the specified path."
        case .uploadFailed(let msg): return "Upload failed: \(msg)"
        case .downloadFailed(let msg): return "Download failed: \(msg)"
        case .sizeLimitExceeded: return "File exceeds the maximum size limit."
        }
    }
}
