package com.dailymemory.data.service

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.core.content.FileProvider
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Service for managing photo storage and operations
 */
@Singleton
class PhotoService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val photosDir: File
        get() = File(context.filesDir, "photos").apply { mkdirs() }

    private val thumbnailsDir: File
        get() = File(context.filesDir, "thumbnails").apply { mkdirs() }

    companion object {
        private const val THUMBNAIL_SIZE = 300
        private const val PHOTO_QUALITY = 85
        private const val THUMBNAIL_QUALITY = 70
    }

    /**
     * Save photo from URI and generate thumbnail
     * Returns the photo ID that can be used to retrieve it later
     */
    suspend fun savePhoto(uri: Uri): Result<SavedPhoto> = withContext(Dispatchers.IO) {
        try {
            val photoId = UUID.randomUUID().toString()
            val photoFile = File(photosDir, "$photoId.jpg")
            val thumbnailFile = File(thumbnailsDir, "${photoId}_thumb.jpg")

            // Read and decode the image
            val inputStream = context.contentResolver.openInputStream(uri)
                ?: return@withContext Result.failure(Exception("Cannot open image"))

            val originalBitmap = BitmapFactory.decodeStream(inputStream)
            inputStream.close()

            if (originalBitmap == null) {
                return@withContext Result.failure(Exception("Cannot decode image"))
            }

            // Save the photo (optionally resize if too large)
            val resizedBitmap = resizeBitmapIfNeeded(originalBitmap, 2048)
            FileOutputStream(photoFile).use { out ->
                resizedBitmap.compress(Bitmap.CompressFormat.JPEG, PHOTO_QUALITY, out)
            }

            // Generate and save thumbnail
            val thumbnail = createThumbnail(originalBitmap)
            FileOutputStream(thumbnailFile).use { out ->
                thumbnail.compress(Bitmap.CompressFormat.JPEG, THUMBNAIL_QUALITY, out)
            }

            // Clean up
            if (resizedBitmap != originalBitmap) {
                resizedBitmap.recycle()
            }
            originalBitmap.recycle()
            thumbnail.recycle()

            Result.success(
                SavedPhoto(
                    id = photoId,
                    url = photoFile.absolutePath,
                    thumbnailUrl = thumbnailFile.absolutePath
                )
            )
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Create a temporary file for camera capture
     * Returns the URI that can be passed to camera intent
     */
    fun createCameraPhotoUri(): Uri {
        val photoId = UUID.randomUUID().toString()
        val photoFile = File(photosDir, "${photoId}_camera.jpg")
        return FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            photoFile
        )
    }

    /**
     * Process a camera-captured photo (generate thumbnail)
     */
    suspend fun processCameraPhoto(uri: Uri): Result<SavedPhoto> = withContext(Dispatchers.IO) {
        try {
            val photoId = UUID.randomUUID().toString()
            val thumbnailFile = File(thumbnailsDir, "${photoId}_thumb.jpg")

            // Get the file path from URI
            val photoPath = uri.path ?: return@withContext Result.failure(Exception("Invalid URI"))
            val photoFile = File(photoPath)

            if (!photoFile.exists()) {
                return@withContext Result.failure(Exception("Photo file not found"))
            }

            // Decode and create thumbnail
            val bitmap = BitmapFactory.decodeFile(photoFile.absolutePath)
                ?: return@withContext Result.failure(Exception("Cannot decode image"))

            val thumbnail = createThumbnail(bitmap)
            FileOutputStream(thumbnailFile).use { out ->
                thumbnail.compress(Bitmap.CompressFormat.JPEG, THUMBNAIL_QUALITY, out)
            }

            bitmap.recycle()
            thumbnail.recycle()

            // Rename photo file to use the new ID
            val newPhotoFile = File(photosDir, "$photoId.jpg")
            photoFile.renameTo(newPhotoFile)

            Result.success(
                SavedPhoto(
                    id = photoId,
                    url = newPhotoFile.absolutePath,
                    thumbnailUrl = thumbnailFile.absolutePath
                )
            )
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Get photo file by ID
     */
    fun getPhotoFile(photoId: String): File? {
        val file = File(photosDir, "$photoId.jpg")
        return if (file.exists()) file else null
    }

    /**
     * Get thumbnail file by ID
     */
    fun getThumbnailFile(photoId: String): File? {
        val file = File(thumbnailsDir, "${photoId}_thumb.jpg")
        return if (file.exists()) file else null
    }

    /**
     * Get photo URI for sharing/display
     */
    fun getPhotoUri(photoId: String): Uri? {
        val file = getPhotoFile(photoId) ?: return null
        return FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            file
        )
    }

    /**
     * Delete photo and its thumbnail
     */
    suspend fun deletePhoto(photoId: String): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            val photoFile = File(photosDir, "$photoId.jpg")
            val thumbnailFile = File(thumbnailsDir, "${photoId}_thumb.jpg")

            photoFile.delete()
            thumbnailFile.delete()

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Get all photos for a specific directory (for cleanup/management)
     */
    fun getAllPhotoIds(): List<String> {
        return photosDir.listFiles()
            ?.filter { it.extension == "jpg" }
            ?.map { it.nameWithoutExtension }
            ?: emptyList()
    }

    /**
     * Get total storage used by photos in bytes
     */
    fun getStorageUsed(): Long {
        val photosSize = photosDir.listFiles()?.sumOf { it.length() } ?: 0L
        val thumbnailsSize = thumbnailsDir.listFiles()?.sumOf { it.length() } ?: 0L
        return photosSize + thumbnailsSize
    }

    private fun resizeBitmapIfNeeded(bitmap: Bitmap, maxSize: Int): Bitmap {
        val width = bitmap.width
        val height = bitmap.height

        if (width <= maxSize && height <= maxSize) {
            return bitmap
        }

        val ratio = minOf(maxSize.toFloat() / width, maxSize.toFloat() / height)
        val newWidth = (width * ratio).toInt()
        val newHeight = (height * ratio).toInt()

        return Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
    }

    private fun createThumbnail(bitmap: Bitmap): Bitmap {
        val width = bitmap.width
        val height = bitmap.height

        val ratio = minOf(THUMBNAIL_SIZE.toFloat() / width, THUMBNAIL_SIZE.toFloat() / height)
        val newWidth = (width * ratio).toInt()
        val newHeight = (height * ratio).toInt()

        return Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
    }
}

/**
 * Data class for saved photo information
 */
data class SavedPhoto(
    val id: String,
    val url: String,
    val thumbnailUrl: String
)
