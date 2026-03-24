package com.dailymemory.presentation

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.dailymemory.presentation.common.theme.DailyMemoryTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    companion object {
        const val EXTRA_START_VOICE_RECORD = "START_VOICE_RECORD"
        const val EXTRA_START_TEXT_RECORD = "START_TEXT_RECORD"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Check if launched from widget
        val startVoiceRecord = intent.getBooleanExtra(EXTRA_START_VOICE_RECORD, false)
        val startTextRecord = intent.getBooleanExtra(EXTRA_START_TEXT_RECORD, false)

        setContent {
            DailyMemoryTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    DailyMemoryApp(
                        startWithVoiceRecord = startVoiceRecord,
                        startWithTextRecord = startTextRecord
                    )
                }
            }
        }
    }
}
