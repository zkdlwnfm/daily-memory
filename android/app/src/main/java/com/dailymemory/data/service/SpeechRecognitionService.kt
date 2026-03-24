package com.dailymemory.data.service

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.content.ContextCompat
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.callbackFlow
import java.util.Locale
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Speech Recognition Service using Android's built-in SpeechRecognizer
 */
@Singleton
class SpeechRecognitionService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private var speechRecognizer: SpeechRecognizer? = null

    private val _state = MutableStateFlow<SpeechRecognitionState>(SpeechRecognitionState.Idle)
    val state: StateFlow<SpeechRecognitionState> = _state.asStateFlow()

    private val _partialResult = MutableStateFlow("")
    val partialResult: StateFlow<String> = _partialResult.asStateFlow()

    /**
     * Check if speech recognition is available on the device
     */
    fun isAvailable(): Boolean {
        return SpeechRecognizer.isRecognitionAvailable(context)
    }

    /**
     * Check if audio recording permission is granted
     */
    fun hasPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Start listening for speech input
     * Returns a Flow that emits recognition results
     */
    fun startListening(
        language: String = Locale.getDefault().toLanguageTag()
    ): Flow<SpeechRecognitionResult> = callbackFlow {
        if (!isAvailable()) {
            trySend(SpeechRecognitionResult.Error("Speech recognition not available on this device"))
            close()
            return@callbackFlow
        }

        if (!hasPermission()) {
            trySend(SpeechRecognitionResult.Error("Audio recording permission not granted"))
            close()
            return@callbackFlow
        }

        _state.value = SpeechRecognitionState.Starting

        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context).apply {
            setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {
                    _state.value = SpeechRecognitionState.Listening
                    trySend(SpeechRecognitionResult.Ready)
                }

                override fun onBeginningOfSpeech() {
                    _state.value = SpeechRecognitionState.Recording
                }

                override fun onRmsChanged(rmsdB: Float) {
                    // Audio level changed - can be used for visualization
                    trySend(SpeechRecognitionResult.AudioLevel(rmsdB))
                }

                override fun onBufferReceived(buffer: ByteArray?) {
                    // Raw audio buffer received
                }

                override fun onEndOfSpeech() {
                    _state.value = SpeechRecognitionState.Processing
                }

                override fun onError(error: Int) {
                    val errorMessage = getErrorMessage(error)
                    _state.value = SpeechRecognitionState.Error(errorMessage)
                    trySend(SpeechRecognitionResult.Error(errorMessage))

                    // Auto-recover for certain errors
                    if (error == SpeechRecognizer.ERROR_NO_MATCH ||
                        error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT) {
                        _state.value = SpeechRecognitionState.Idle
                    }
                }

                override fun onResults(results: Bundle?) {
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    val confidences = results?.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)

                    if (!matches.isNullOrEmpty()) {
                        val finalText = matches[0]
                        val confidence = confidences?.getOrNull(0) ?: 0f

                        _state.value = SpeechRecognitionState.Idle
                        trySend(SpeechRecognitionResult.FinalResult(finalText, confidence))
                    } else {
                        _state.value = SpeechRecognitionState.Idle
                        trySend(SpeechRecognitionResult.Error("No speech detected"))
                    }
                }

                override fun onPartialResults(partialResults: Bundle?) {
                    val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    if (!matches.isNullOrEmpty()) {
                        val partialText = matches[0]
                        _partialResult.value = partialText
                        trySend(SpeechRecognitionResult.PartialResult(partialText))
                    }
                }

                override fun onEvent(eventType: Int, params: Bundle?) {
                    // Reserved for future events
                }
            })
        }

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
            // For continuous listening
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 5000L)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 2000L)
        }

        speechRecognizer?.startListening(intent)

        awaitClose {
            stopListening()
        }
    }

    /**
     * Stop listening and release resources
     */
    fun stopListening() {
        speechRecognizer?.apply {
            stopListening()
            cancel()
            destroy()
        }
        speechRecognizer = null
        _state.value = SpeechRecognitionState.Idle
        _partialResult.value = ""
    }

    /**
     * Cancel current recognition without processing
     */
    fun cancel() {
        speechRecognizer?.cancel()
        _state.value = SpeechRecognitionState.Idle
        _partialResult.value = ""
    }

    private fun getErrorMessage(errorCode: Int): String {
        return when (errorCode) {
            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
            SpeechRecognizer.ERROR_CLIENT -> "Client side error"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
            SpeechRecognizer.ERROR_NETWORK -> "Network error"
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
            SpeechRecognizer.ERROR_NO_MATCH -> "No speech detected"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognition service busy"
            SpeechRecognizer.ERROR_SERVER -> "Server error"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
            SpeechRecognizer.ERROR_TOO_MANY_REQUESTS -> "Too many requests"
            else -> "Unknown error"
        }
    }
}

/**
 * Speech recognition state
 */
sealed class SpeechRecognitionState {
    data object Idle : SpeechRecognitionState()
    data object Starting : SpeechRecognitionState()
    data object Listening : SpeechRecognitionState()
    data object Recording : SpeechRecognitionState()
    data object Processing : SpeechRecognitionState()
    data class Error(val message: String) : SpeechRecognitionState()
}

/**
 * Speech recognition result types
 */
sealed class SpeechRecognitionResult {
    data object Ready : SpeechRecognitionResult()
    data class AudioLevel(val level: Float) : SpeechRecognitionResult()
    data class PartialResult(val text: String) : SpeechRecognitionResult()
    data class FinalResult(val text: String, val confidence: Float) : SpeechRecognitionResult()
    data class Error(val message: String) : SpeechRecognitionResult()
}
