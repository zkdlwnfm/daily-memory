package com.dailymemory.presentation.photo

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.dailymemory.data.service.PhotoService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class PhotoPickerViewModel @Inject constructor(
    private val photoService: PhotoService
) : ViewModel() {

    private val _uiState = MutableStateFlow(PhotoPickerUiState())
    val uiState: StateFlow<PhotoPickerUiState> = _uiState.asStateFlow()

    private var pendingCameraUri: Uri? = null

    /**
     * Create a URI for camera capture
     */
    fun createCameraPhotoUri(): Uri {
        val uri = photoService.createCameraPhotoUri()
        pendingCameraUri = uri
        return uri
    }

    /**
     * Process the camera-captured photo
     */
    fun processCameraPhoto() {
        val uri = pendingCameraUri ?: return
        pendingCameraUri = null

        _uiState.update { state ->
            state.copy(selectedPhotos = state.selectedPhotos + uri)
        }
    }

    /**
     * Add photos from URIs (from photo picker or gallery)
     */
    fun addPhotosFromUris(uris: List<Uri>) {
        if (uris.isEmpty()) return

        _uiState.update { state ->
            val newPhotos = uris.filter { uri ->
                !state.selectedPhotos.contains(uri)
            }
            state.copy(selectedPhotos = state.selectedPhotos + newPhotos)
        }
    }

    /**
     * Remove a photo from selection
     */
    fun removePhoto(uri: Uri) {
        _uiState.update { state ->
            state.copy(selectedPhotos = state.selectedPhotos - uri)
        }
    }

    /**
     * Clear all selected photos
     */
    fun clearSelection() {
        _uiState.update { it.copy(selectedPhotos = emptyList()) }
    }

    /**
     * Save all selected photos and return their IDs
     */
    fun saveSelectedPhotos(onComplete: (List<String>) -> Unit) {
        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true, error = null) }

            val photoIds = mutableListOf<String>()
            var hasError = false

            for (uri in _uiState.value.selectedPhotos) {
                // Check if this is a camera photo (already in our photos directory)
                val path = uri.path
                if (path != null && path.contains("photos") && path.endsWith("_camera.jpg")) {
                    // Process camera photo
                    photoService.processCameraPhoto(uri)
                        .onSuccess { savedPhoto ->
                            photoIds.add(savedPhoto.id)
                        }
                        .onFailure { e ->
                            hasError = true
                            _uiState.update { it.copy(error = e.message) }
                        }
                } else {
                    // Save from external URI
                    photoService.savePhoto(uri)
                        .onSuccess { savedPhoto ->
                            photoIds.add(savedPhoto.id)
                        }
                        .onFailure { e ->
                            hasError = true
                            _uiState.update { it.copy(error = e.message) }
                        }
                }
            }

            _uiState.update { it.copy(isSaving = false) }

            if (photoIds.isNotEmpty()) {
                onComplete(photoIds)
            }
        }
    }

    /**
     * Clear error message
     */
    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}

data class PhotoPickerUiState(
    val selectedPhotos: List<Uri> = emptyList(),
    val isSaving: Boolean = false,
    val error: String? = null
)
