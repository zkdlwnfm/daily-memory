package com.dailymemory.presentation.record

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.dailymemory.presentation.common.theme.Primary

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecordScreen(
    onNavigateBack: () -> Unit,
    onSaveComplete: () -> Unit,
    viewModel: RecordViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            RecordTopBar(
                state = uiState.recordState,
                onCancel = onNavigateBack,
                onSave = { viewModel.saveMemory(onSaveComplete) },
                onToggleMode = { viewModel.toggleMode() }
            )
        },
        containerColor = MaterialTheme.colorScheme.background
    ) { innerPadding ->
        AnimatedContent(
            targetState = uiState.recordState,
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            transitionSpec = {
                fadeIn(tween(300)) togetherWith fadeOut(tween(300))
            },
            label = "record_state"
        ) { state ->
            when (state) {
                RecordState.VOICE_IDLE -> VoiceIdleContent(
                    onStartRecording = { viewModel.startRecording() }
                )
                RecordState.VOICE_RECORDING -> VoiceRecordingContent(
                    elapsedTime = uiState.recordingTime,
                    transcription = uiState.transcription,
                    onStopRecording = { viewModel.stopRecording() }
                )
                RecordState.TEXT_MODE -> TextModeContent(
                    text = uiState.textContent,
                    onTextChange = { viewModel.updateText(it) },
                    onAnalyze = { viewModel.analyzeWithAI() },
                    onSaveWithoutAnalysis = { viewModel.saveWithoutAnalysis(onSaveComplete) }
                )
                RecordState.AI_PROCESSING -> AIProcessingContent()
                RecordState.AI_RESULT -> AIResultContent(
                    result = uiState.aiResult,
                    onEditContent = { viewModel.editContent(it) },
                    onPersonToggle = { viewModel.togglePerson(it) },
                    onAddPerson = { /* TODO */ },
                    onLocationChange = { /* TODO */ },
                    onEventChange = { /* TODO */ },
                    onAmountChange = { /* TODO */ },
                    onCategorySelect = { viewModel.selectCategory(it) },
                    onReminderSetup = { /* TODO */ }
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun RecordTopBar(
    state: RecordState,
    onCancel: () -> Unit,
    onSave: () -> Unit,
    onToggleMode: () -> Unit
) {
    CenterAlignedTopAppBar(
        title = { },
        navigationIcon = {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = onCancel) {
                    Icon(Icons.Default.Close, contentDescription = "Cancel")
                }
                if (state != RecordState.AI_RESULT) {
                    Text(
                        text = "Cancel",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        },
        actions = {
            when (state) {
                RecordState.VOICE_IDLE, RecordState.VOICE_RECORDING -> {
                    TextButton(onClick = onToggleMode) {
                        Text(
                            text = "Type instead",
                            color = Primary,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
                RecordState.TEXT_MODE -> {
                    TextButton(onClick = onToggleMode) {
                        Icon(
                            Icons.Default.Mic,
                            contentDescription = null,
                            tint = Primary,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = "Voice input",
                            color = Primary,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
                RecordState.AI_RESULT -> {
                    Button(
                        onClick = onSave,
                        colors = ButtonDefaults.buttonColors(containerColor = Primary),
                        shape = RoundedCornerShape(20.dp)
                    ) {
                        Text("Save", fontWeight = FontWeight.Bold)
                    }
                }
                else -> { }
            }
        },
        colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
            containerColor = Color.Transparent
        )
    )
}

@Composable
private fun VoiceIdleContent(
    onStartRecording: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Spacer(modifier = Modifier.weight(1f))

        // Mic Button
        Box(
            modifier = Modifier
                .size(120.dp)
                .clip(CircleShape)
                .background(Primary)
                .clickable(onClick = onStartRecording),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.Mic,
                contentDescription = "Start recording",
                tint = Color.White,
                modifier = Modifier.size(48.dp)
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            text = "Tap to record",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "Capture a moment from your day",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.weight(1f))

        // Tip Card
        TipCard(
            text = "Just speak naturally. AI will extract people, places, and events.",
            subtext = "Your recording is private and encrypted."
        )

        Spacer(modifier = Modifier.height(32.dp))
    }
}

@Composable
private fun VoiceRecordingContent(
    elapsedTime: String,
    transcription: String,
    onStopRecording: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(32.dp))

        // Timer Circle
        Box(
            modifier = Modifier
                .size(140.dp)
                .clip(CircleShape)
                .background(Color(0xFFDC2626)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = elapsedTime,
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Waveform placeholder
        WaveformAnimation()

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Recording...",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = Color(0xFFDC2626)
        )

        Text(
            text = "DailyMemory is listening",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Transcription Card
        if (transcription.isNotEmpty()) {
            TranscriptionCard(text = transcription)
        }

        Spacer(modifier = Modifier.weight(1f))

        // Stop Button
        Box(
            modifier = Modifier
                .size(72.dp)
                .clip(CircleShape)
                .background(Color(0xFFDC2626))
                .clickable(onClick = onStopRecording),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.Stop,
                contentDescription = "Stop recording",
                tint = Color.White,
                modifier = Modifier.size(32.dp)
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "TAP TO STOP",
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.Bold,
            letterSpacing = 2.sp
        )

        Spacer(modifier = Modifier.height(24.dp))

        TipCard(
            text = "Speak naturally. DailyMemory automatically organizes names, dates, and amounts mentioned.",
            prefix = "Tip:"
        )

        Spacer(modifier = Modifier.height(16.dp))
    }
}

@Composable
private fun WaveformAnimation() {
    Row(
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        repeat(7) { index ->
            val height = when (index) {
                0, 6 -> 16.dp
                1, 5 -> 24.dp
                2, 4 -> 32.dp
                else -> 40.dp
            }
            Box(
                modifier = Modifier
                    .width(6.dp)
                    .height(height)
                    .clip(RoundedCornerShape(3.dp))
                    .background(Color(0xFFDC2626).copy(alpha = 0.6f))
            )
        }
    }
}

@Composable
private fun TranscriptionCard(text: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        ),
        shape = RoundedCornerShape(16.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "❝",
                fontSize = 24.sp,
                color = Primary.copy(alpha = 0.5f)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(
                    text = text,
                    style = MaterialTheme.typography.bodyLarge
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .clip(CircleShape)
                            .background(Color(0xFF22C55E))
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "LIVE TRANSCRIPTION",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        letterSpacing = 1.sp
                    )
                }
            }
        }
    }
}

@Composable
private fun TipCard(
    text: String,
    subtext: String? = null,
    prefix: String? = null
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
        ),
        shape = RoundedCornerShape(16.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.Top
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFFEF3C7)),
                contentAlignment = Alignment.Center
            ) {
                Text("💡", fontSize = 18.sp)
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column {
                Text(
                    text = if (prefix != null) "$prefix $text" else text,
                    style = MaterialTheme.typography.bodyMedium
                )
                if (subtext != null) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = subtext,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
private fun TextModeContent(
    text: String,
    onTextChange: (String) -> Unit,
    onAnalyze: () -> Unit,
    onSaveWithoutAnalysis: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
    ) {
        Text(
            text = "TODAY'S ENTRY",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            letterSpacing = 1.sp
        )

        Spacer(modifier = Modifier.height(4.dp))

        Text(
            text = "New Memory",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Text Input
        androidx.compose.material3.OutlinedTextField(
            value = text,
            onValueChange = onTextChange,
            placeholder = {
                Text(
                    "What happened today?",
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                )
            },
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f),
            shape = RoundedCornerShape(16.dp)
        )

        Text(
            text = "${text.length}/500",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier
                .align(Alignment.End)
                .padding(top = 8.dp)
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Add Photos Section
        Text(
            text = "📷 ADD PHOTOS",
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.Bold,
            letterSpacing = 1.sp
        )

        Spacer(modifier = Modifier.height(12.dp))

        PhotoAddButton()

        Spacer(modifier = Modifier.height(24.dp))

        // Analyze Button
        Button(
            onClick = onAnalyze,
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Primary),
            shape = RoundedCornerShape(16.dp),
            enabled = text.isNotBlank()
        ) {
            Text(
                text = "✨ ✨ ANALYZE WITH AI",
                fontWeight = FontWeight.Bold
            )
        }

        Spacer(modifier = Modifier.height(12.dp))

        TextButton(
            onClick = onSaveWithoutAnalysis,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(
                text = "Save without analysis",
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun PhotoAddButton() {
    Box(
        modifier = Modifier
            .size(80.dp)
            .clip(RoundedCornerShape(12.dp))
            .border(
                width = 2.dp,
                color = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f),
                shape = RoundedCornerShape(12.dp)
            )
            .clickable { /* TODO */ },
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text("+", fontSize = 24.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(
                "UPLOAD",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun AIProcessingContent() {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("✨", fontSize = 48.sp)
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "AI is analyzing...",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Extracting people, places, and events",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun AIResultContent(
    result: AIAnalysisResult?,
    onEditContent: (String) -> Unit,
    onPersonToggle: (String) -> Unit,
    onAddPerson: () -> Unit,
    onLocationChange: () -> Unit,
    onEventChange: () -> Unit,
    onAmountChange: () -> Unit,
    onCategorySelect: (String) -> Unit,
    onReminderSetup: () -> Unit
) {
    if (result == null) return

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(24.dp)
    ) {
        // Content Section
        Text(
            text = "Your Memory",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(12.dp))

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)
            ),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = result.content,
                    style = MaterialTheme.typography.bodyLarge
                )
                TextButton(
                    onClick = { /* TODO: Enable editing */ },
                    modifier = Modifier.align(Alignment.End)
                ) {
                    Text("Edit ✏️", color = Primary)
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // AI Analysis Section
        Text(
            text = "✨ AI Analysis",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = Primary
        )

        Spacer(modifier = Modifier.height(16.dp))

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surface
            ),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                // People Section
                AIResultSection(
                    icon = "👤",
                    label = "PEOPLE",
                    content = {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            result.people.forEach { person ->
                                PersonChip(
                                    name = person,
                                    onRemove = { onPersonToggle(person) }
                                )
                            }
                            OutlinedButton(
                                onClick = onAddPerson,
                                shape = RoundedCornerShape(20.dp)
                            ) {
                                Text("+ Add person")
                            }
                        }
                        if (result.newPersonDetected) {
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "ℹ️ New person detected. Set relationship?",
                                style = MaterialTheme.typography.bodySmall,
                                color = Primary
                            )
                        }
                    }
                )

                SectionDivider()

                // Location Section
                AIResultSection(
                    icon = "📍",
                    label = "LOCATION",
                    content = {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = result.location ?: "Not detected",
                                style = MaterialTheme.typography.bodyLarge,
                                fontWeight = FontWeight.Medium
                            )
                            TextButton(onClick = onLocationChange) {
                                Text("Change >", color = Primary)
                            }
                        }
                    }
                )

                SectionDivider()

                // Event Section
                AIResultSection(
                    icon = "🎉",
                    label = "EVENT",
                    content = {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(
                                    text = result.event ?: "Not detected",
                                    style = MaterialTheme.typography.bodyLarge,
                                    fontWeight = FontWeight.Medium
                                )
                                result.eventDate?.let {
                                    Text(
                                        text = it,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                            TextButton(onClick = onEventChange) {
                                Text("Change >", color = Primary)
                            }
                        }
                    }
                )

                SectionDivider()

                // Amount Section
                AIResultSection(
                    icon = "💳",
                    label = "AMOUNT",
                    content = {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(
                                    text = result.amount ?: "Not detected",
                                    style = MaterialTheme.typography.bodyLarge,
                                    fontWeight = FontWeight.Medium
                                )
                                result.amountLabel?.let {
                                    Text(
                                        text = it,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                            TextButton(onClick = onAmountChange) {
                                Text("Change >", color = Primary)
                            }
                        }
                    }
                )

                SectionDivider()

                // Category Section
                AIResultSection(
                    icon = "🏷️",
                    label = "CATEGORY",
                    content = {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            listOf("General", "Meeting", "Event", "Financial").forEach { category ->
                                CategoryChip(
                                    label = category,
                                    isSelected = result.category == category,
                                    onClick = { onCategorySelect(category) }
                                )
                            }
                        }
                    }
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Add Photos Section
        Text(
            text = "Add Photos",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(12.dp))

        PhotoAddButton()

        Spacer(modifier = Modifier.height(24.dp))

        // Reminder Section
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = Primary.copy(alpha = 0.1f)
            ),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("🔔", fontSize = 20.sp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Set Reminder",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        TextButton(onClick = onReminderSetup) {
                            Text("Setup >", color = Primary)
                        }
                    }
                }

                if (result.suggestedReminder != null) {
                    Spacer(modifier = Modifier.height(12.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("💡", fontSize = 16.sp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = result.suggestedReminder,
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                    Spacer(modifier = Modifier.height(12.dp))
                    Button(
                        onClick = { /* TODO */ },
                        colors = ButtonDefaults.buttonColors(containerColor = Primary),
                        shape = RoundedCornerShape(20.dp)
                    ) {
                        Text("Yes, remind me 1 day before")
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(100.dp))
    }
}

@Composable
private fun AIResultSection(
    icon: String,
    label: String,
    content: @Composable () -> Unit
) {
    Column {
        Text(
            text = "$icon $label",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            letterSpacing = 1.sp
        )
        Spacer(modifier = Modifier.height(8.dp))
        content()
    }
}

@Composable
private fun SectionDivider() {
    Spacer(modifier = Modifier.height(16.dp))
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(1.dp)
            .background(MaterialTheme.colorScheme.outline.copy(alpha = 0.1f))
    )
    Spacer(modifier = Modifier.height(16.dp))
}

@Composable
private fun PersonChip(
    name: String,
    onRemove: () -> Unit
) {
    Surface(
        shape = RoundedCornerShape(20.dp),
        color = Primary.copy(alpha = 0.1f)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = name,
                style = MaterialTheme.typography.bodyMedium,
                color = Primary
            )
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = "×",
                style = MaterialTheme.typography.bodyMedium,
                color = Primary,
                modifier = Modifier.clickable(onClick = onRemove)
            )
        }
    }
}

@Composable
private fun CategoryChip(
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Surface(
        shape = RoundedCornerShape(20.dp),
        color = if (isSelected) Primary else Color.Transparent,
        modifier = Modifier
            .clip(RoundedCornerShape(20.dp))
            .clickable(onClick = onClick)
            .then(
                if (!isSelected) Modifier.border(
                    1.dp,
                    MaterialTheme.colorScheme.outline.copy(alpha = 0.3f),
                    RoundedCornerShape(20.dp)
                ) else Modifier
            )
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
        )
    }
}
