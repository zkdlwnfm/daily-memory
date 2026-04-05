package com.dailymemory.presentation.reminder

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import com.dailymemory.domain.model.LocationTriggerType
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.dailymemory.domain.model.Person
import com.dailymemory.domain.model.RepeatType
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReminderEditScreen(
    reminderId: String? = null,
    memoryId: String? = null,
    personId: String? = null,
    onNavigateBack: () -> Unit,
    onNavigateToLocationPicker: (SelectedLocation?) -> Unit,
    viewModel: ReminderEditViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

    var showDatePicker by remember { mutableStateOf(false) }
    var showTimePicker by remember { mutableStateOf(false) }
    var showRepeatPicker by remember { mutableStateOf(false) }
    var showPersonPicker by remember { mutableStateOf(false) }

    LaunchedEffect(reminderId, memoryId, personId) {
        viewModel.initialize(reminderId, memoryId, personId)
    }

    LaunchedEffect(uiState.saveSuccess) {
        if (uiState.saveSuccess) {
            onNavigateBack()
        }
    }

    LaunchedEffect(uiState.error) {
        uiState.error?.let { error ->
            snackbarHostState.showSnackbar(error)
            viewModel.clearError()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(if (reminderId != null) "Edit Reminder" else "New Reminder")
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back")
                    }
                },
                actions = {
                    TextButton(
                        onClick = { viewModel.save() },
                        enabled = uiState.isValid && !uiState.isSaving
                    ) {
                        if (uiState.isSaving) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text("Save")
                        }
                    }
                }
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Title
            OutlinedTextField(
                value = uiState.title,
                onValueChange = { viewModel.updateTitle(it) },
                label = { Text("Title") },
                placeholder = { Text("What should I remind you about?") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                leadingIcon = {
                    Icon(Icons.Default.NotificationsActive, null)
                }
            )

            // Body/Description
            OutlinedTextField(
                value = uiState.body,
                onValueChange = { viewModel.updateBody(it) },
                label = { Text("Description (optional)") },
                placeholder = { Text("Add more details...") },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp),
                maxLines = 5
            )

            HorizontalDivider()

            // Date & Time Section
            Text(
                text = "Schedule",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.primary
            )

            // Date Picker
            SettingRow(
                icon = Icons.Default.CalendarMonth,
                title = "Date",
                value = uiState.date.format(DateTimeFormatter.ofPattern("EEEE, MMM d, yyyy")),
                onClick = { showDatePicker = true }
            )

            // Time Picker
            SettingRow(
                icon = Icons.Default.Schedule,
                title = "Time",
                value = uiState.time.format(DateTimeFormatter.ofPattern("h:mm a")),
                onClick = { showTimePicker = true }
            )

            // Repeat
            SettingRow(
                icon = Icons.Default.Repeat,
                title = "Repeat",
                value = uiState.repeatType.getDisplayName(),
                onClick = { showRepeatPicker = true }
            )

            HorizontalDivider()

            // Location Section
            Text(
                text = "Location",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.primary
            )

            // Location-based toggle
            Surface(
                onClick = { viewModel.updateIsLocationBased(!uiState.isLocationBased) },
                shape = RoundedCornerShape(12.dp),
                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.LocationOn,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(16.dp))
                    Text(
                        text = "Location-based reminder",
                        modifier = Modifier.weight(1f),
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Switch(
                        checked = uiState.isLocationBased,
                        onCheckedChange = { viewModel.updateIsLocationBased(it) }
                    )
                }
            }

            // Location picker (shown when location-based is enabled)
            if (uiState.isLocationBased) {
                Surface(
                    onClick = { onNavigateToLocationPicker(uiState.selectedLocation) },
                    shape = RoundedCornerShape(12.dp),
                    color = if (uiState.selectedLocation != null)
                        MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                    else
                        MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = if (uiState.selectedLocation != null)
                                Icons.Default.CheckCircle
                            else
                                Icons.Default.AddLocation,
                            contentDescription = null,
                            tint = if (uiState.selectedLocation != null)
                                MaterialTheme.colorScheme.primary
                            else
                                MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.width(16.dp))
                        if (uiState.selectedLocation != null) {
                            val location = uiState.selectedLocation!!
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = location.name,
                                    style = MaterialTheme.typography.bodyLarge,
                                    fontWeight = FontWeight.Medium
                                )
                                location.address?.let {
                                    Text(
                                        text = it,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    val triggerIcon = when (location.triggerType) {
                                        LocationTriggerType.ENTER -> Icons.Default.ArrowDownward
                                        LocationTriggerType.EXIT -> Icons.Default.ArrowUpward
                                        LocationTriggerType.BOTH -> Icons.Default.SwapVert
                                    }
                                    Icon(
                                        triggerIcon,
                                        contentDescription = null,
                                        modifier = Modifier.size(14.dp),
                                        tint = MaterialTheme.colorScheme.primary
                                    )
                                    Text(
                                        text = "${location.triggerType.getDisplayName()} within ${location.radius.toInt()}m",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                }
                            }
                        } else {
                            Text(
                                text = "Select location",
                                modifier = Modifier.weight(1f),
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        Icon(
                            Icons.Default.ChevronRight,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            HorizontalDivider()

            // Link Section
            Text(
                text = "Link To",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.primary
            )

            // Person Link
            SettingRow(
                icon = Icons.Default.Person,
                title = "Person",
                value = uiState.linkedPerson?.name ?: "None",
                onClick = { showPersonPicker = true }
            )

            // Memory Link (if provided)
            if (uiState.linkedMemoryPreview != null) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.Description,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                "Linked Memory",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                uiState.linkedMemoryPreview!!,
                                style = MaterialTheme.typography.bodyMedium,
                                maxLines = 2
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(32.dp))

            // Quick Time Buttons
            Text(
                text = "Quick Set",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.primary
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                QuickTimeChip(
                    label = "In 1 hour",
                    onClick = { viewModel.setQuickTime(1) },
                    modifier = Modifier.weight(1f)
                )
                QuickTimeChip(
                    label = "Tomorrow",
                    onClick = { viewModel.setTomorrow() },
                    modifier = Modifier.weight(1f)
                )
                QuickTimeChip(
                    label = "Next week",
                    onClick = { viewModel.setNextWeek() },
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }

    // Date Picker Dialog
    if (showDatePicker) {
        val datePickerState = rememberDatePickerState(
            initialSelectedDateMillis = uiState.date.toEpochDay() * 86400000L
        )

        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(onClick = {
                    datePickerState.selectedDateMillis?.let { millis ->
                        viewModel.updateDate(LocalDate.ofEpochDay(millis / 86400000L))
                    }
                    showDatePicker = false
                }) {
                    Text("OK")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDatePicker = false }) {
                    Text("Cancel")
                }
            }
        ) {
            DatePicker(state = datePickerState)
        }
    }

    // Time Picker Dialog
    if (showTimePicker) {
        val timePickerState = rememberTimePickerState(
            initialHour = uiState.time.hour,
            initialMinute = uiState.time.minute
        )

        AlertDialog(
            onDismissRequest = { showTimePicker = false },
            title = { Text("Select Time") },
            text = {
                TimePicker(state = timePickerState)
            },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.updateTime(LocalTime.of(timePickerState.hour, timePickerState.minute))
                    showTimePicker = false
                }) {
                    Text("OK")
                }
            },
            dismissButton = {
                TextButton(onClick = { showTimePicker = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Repeat Picker Dialog
    if (showRepeatPicker) {
        AlertDialog(
            onDismissRequest = { showRepeatPicker = false },
            title = { Text("Repeat") },
            text = {
                Column {
                    RepeatType.entries.forEach { repeatType ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    viewModel.updateRepeatType(repeatType)
                                    showRepeatPicker = false
                                }
                                .padding(vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = uiState.repeatType == repeatType,
                                onClick = {
                                    viewModel.updateRepeatType(repeatType)
                                    showRepeatPicker = false
                                }
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(repeatType.getDisplayName())
                        }
                    }
                }
            },
            confirmButton = {}
        )
    }

    // Person Picker Dialog
    if (showPersonPicker) {
        PersonPickerDialog(
            persons = uiState.availablePersons,
            selectedPerson = uiState.linkedPerson,
            onSelect = { person ->
                viewModel.updateLinkedPerson(person)
                showPersonPicker = false
            },
            onDismiss = { showPersonPicker = false }
        )
    }
}

@Composable
private fun SettingRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    value: String,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = value,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Medium
                )
            }
            Icon(
                Icons.Default.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun QuickTimeChip(
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        onClick = onClick,
        modifier = modifier,
        shape = RoundedCornerShape(8.dp),
        color = MaterialTheme.colorScheme.secondaryContainer
    ) {
        Text(
            text = label,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 10.dp),
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSecondaryContainer
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PersonPickerDialog(
    persons: List<Person>,
    selectedPerson: Person?,
    onSelect: (Person?) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Select Person") },
        text = {
            Column {
                // None option
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onSelect(null) }
                        .padding(vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(
                        selected = selectedPerson == null,
                        onClick = { onSelect(null) }
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("None")
                }

                HorizontalDivider()

                // Person options
                persons.forEach { person ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onSelect(person) }
                            .padding(vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = selectedPerson?.id == person.id,
                            onClick = { onSelect(person) }
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Column {
                            Text(person.name)
                            Text(
                                person.relationship.getDisplayName(),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                if (persons.isEmpty()) {
                    Text(
                        "No people added yet",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(vertical = 16.dp)
                    )
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
