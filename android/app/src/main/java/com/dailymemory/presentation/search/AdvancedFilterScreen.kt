package com.dailymemory.presentation.search

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.dailymemory.domain.model.Category
import com.dailymemory.domain.model.Person
import java.time.LocalDate
import java.time.format.DateTimeFormatter

data class AdvancedFilter(
    val startDate: LocalDate? = null,
    val endDate: LocalDate? = null,
    val categories: Set<Category> = emptySet(),
    val personIds: Set<String> = emptySet(),
    val minAmount: Double? = null,
    val maxAmount: Double? = null,
    val hasPhotos: Boolean? = null,
    val isLocked: Boolean? = null
) {
    fun isActive(): Boolean {
        return startDate != null || endDate != null ||
                categories.isNotEmpty() || personIds.isNotEmpty() ||
                minAmount != null || maxAmount != null ||
                hasPhotos != null || isLocked != null
    }

    fun activeCount(): Int {
        var count = 0
        if (startDate != null || endDate != null) count++
        if (categories.isNotEmpty()) count++
        if (personIds.isNotEmpty()) count++
        if (minAmount != null || maxAmount != null) count++
        if (hasPhotos != null) count++
        if (isLocked != null) count++
        return count
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdvancedFilterSheet(
    currentFilter: AdvancedFilter,
    availablePersons: List<Person>,
    onApplyFilter: (AdvancedFilter) -> Unit,
    onClearFilter: () -> Unit,
    onDismiss: () -> Unit
) {
    var filter by remember { mutableStateOf(currentFilter) }
    var showStartDatePicker by remember { mutableStateOf(false) }
    var showEndDatePicker by remember { mutableStateOf(false) }

    val dateFormatter = DateTimeFormatter.ofPattern("MMM d, yyyy")

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 32.dp)
                .verticalScroll(rememberScrollState())
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Advanced Filters",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                if (filter.isActive()) {
                    TextButton(onClick = {
                        filter = AdvancedFilter()
                        onClearFilter()
                    }) {
                        Text("Clear All")
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Date Range
            FilterSection(title = "Date Range") {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    DatePickerButton(
                        label = "From",
                        date = filter.startDate,
                        dateFormatter = dateFormatter,
                        onClick = { showStartDatePicker = true },
                        onClear = { filter = filter.copy(startDate = null) },
                        modifier = Modifier.weight(1f)
                    )
                    DatePickerButton(
                        label = "To",
                        date = filter.endDate,
                        dateFormatter = dateFormatter,
                        onClick = { showEndDatePicker = true },
                        onClear = { filter = filter.copy(endDate = null) },
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Categories
            FilterSection(title = "Categories") {
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Category.entries.forEach { category ->
                        val isSelected = filter.categories.contains(category)
                        FilterChip(
                            selected = isSelected,
                            onClick = {
                                filter = if (isSelected) {
                                    filter.copy(categories = filter.categories - category)
                                } else {
                                    filter.copy(categories = filter.categories + category)
                                }
                            },
                            label = { Text(getCategoryName(category)) },
                            leadingIcon = if (isSelected) {
                                { Icon(Icons.Default.Check, null, Modifier.size(18.dp)) }
                            } else null
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // People
            if (availablePersons.isNotEmpty()) {
                FilterSection(title = "People") {
                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        availablePersons.forEach { person ->
                            val isSelected = filter.personIds.contains(person.id)
                            FilterChip(
                                selected = isSelected,
                                onClick = {
                                    filter = if (isSelected) {
                                        filter.copy(personIds = filter.personIds - person.id)
                                    } else {
                                        filter.copy(personIds = filter.personIds + person.id)
                                    }
                                },
                                label = { Text(person.name) },
                                leadingIcon = if (isSelected) {
                                    { Icon(Icons.Default.Check, null, Modifier.size(18.dp)) }
                                } else {
                                    { Icon(Icons.Default.Person, null, Modifier.size(18.dp)) }
                                }
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))
            }

            // Amount Range
            FilterSection(title = "Amount Range") {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    OutlinedTextField(
                        value = filter.minAmount?.toString() ?: "",
                        onValueChange = { value ->
                            filter = filter.copy(minAmount = value.toDoubleOrNull())
                        },
                        label = { Text("Min $") },
                        modifier = Modifier.weight(1f),
                        singleLine = true
                    )
                    OutlinedTextField(
                        value = filter.maxAmount?.toString() ?: "",
                        onValueChange = { value ->
                            filter = filter.copy(maxAmount = value.toDoubleOrNull())
                        },
                        label = { Text("Max $") },
                        modifier = Modifier.weight(1f),
                        singleLine = true
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Additional Filters
            FilterSection(title = "Additional") {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Has Photos
                    FilterChip(
                        selected = filter.hasPhotos == true,
                        onClick = {
                            filter = filter.copy(
                                hasPhotos = if (filter.hasPhotos == true) null else true
                            )
                        },
                        label = { Text("Has Photos") },
                        leadingIcon = {
                            Icon(Icons.Default.Photo, null, Modifier.size(18.dp))
                        }
                    )

                    // Is Locked
                    FilterChip(
                        selected = filter.isLocked == true,
                        onClick = {
                            filter = filter.copy(
                                isLocked = if (filter.isLocked == true) null else true
                            )
                        },
                        label = { Text("Locked") },
                        leadingIcon = {
                            Icon(Icons.Default.Lock, null, Modifier.size(18.dp))
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(32.dp))

            // Apply Button
            Button(
                onClick = {
                    onApplyFilter(filter)
                    onDismiss()
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = RoundedCornerShape(16.dp)
            ) {
                Text(
                    text = if (filter.isActive()) {
                        "Apply ${filter.activeCount()} Filter${if (filter.activeCount() > 1) "s" else ""}"
                    } else {
                        "Show All Results"
                    },
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }

    // Date Pickers
    if (showStartDatePicker) {
        DatePickerDialog(
            initialDate = filter.startDate,
            onDateSelected = { date ->
                filter = filter.copy(startDate = date)
                showStartDatePicker = false
            },
            onDismiss = { showStartDatePicker = false }
        )
    }

    if (showEndDatePicker) {
        DatePickerDialog(
            initialDate = filter.endDate,
            onDateSelected = { date ->
                filter = filter.copy(endDate = date)
                showEndDatePicker = false
            },
            onDismiss = { showEndDatePicker = false }
        )
    }
}

@Composable
private fun FilterSection(
    title: String,
    content: @Composable () -> Unit
) {
    Column {
        Text(
            text = title,
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(12.dp))
        content()
    }
}

@Composable
private fun DatePickerButton(
    label: String,
    date: LocalDate?,
    dateFormatter: DateTimeFormatter,
    onClick: () -> Unit,
    onClear: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        onClick = onClick,
        modifier = modifier,
        shape = RoundedCornerShape(12.dp),
        color = if (date != null) {
            MaterialTheme.colorScheme.primaryContainer
        } else {
            MaterialTheme.colorScheme.surfaceVariant
        }
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = label,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = date?.format(dateFormatter) ?: "Select",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = if (date != null) FontWeight.Medium else FontWeight.Normal
                )
            }
            if (date != null) {
                IconButton(
                    onClick = onClear,
                    modifier = Modifier.size(24.dp)
                ) {
                    Icon(
                        Icons.Default.Close,
                        contentDescription = "Clear",
                        modifier = Modifier.size(16.dp)
                    )
                }
            } else {
                Icon(
                    Icons.Default.CalendarMonth,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DatePickerDialog(
    initialDate: LocalDate?,
    onDateSelected: (LocalDate) -> Unit,
    onDismiss: () -> Unit
) {
    val datePickerState = rememberDatePickerState(
        initialSelectedDateMillis = initialDate?.toEpochDay()?.times(86400000L)
    )

    DatePickerDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(
                onClick = {
                    datePickerState.selectedDateMillis?.let { millis ->
                        val date = LocalDate.ofEpochDay(millis / 86400000L)
                        onDateSelected(date)
                    }
                }
            ) {
                Text("OK")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    ) {
        DatePicker(state = datePickerState)
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun FlowRow(
    modifier: Modifier = Modifier,
    horizontalArrangement: Arrangement.Horizontal = Arrangement.Start,
    verticalArrangement: Arrangement.Vertical = Arrangement.Top,
    content: @Composable () -> Unit
) {
    androidx.compose.foundation.layout.FlowRow(
        modifier = modifier,
        horizontalArrangement = horizontalArrangement,
        verticalArrangement = verticalArrangement
    ) {
        content()
    }
}

private fun getCategoryName(category: Category): String {
    return when (category) {
        Category.EVENT -> "Event"
        Category.PROMISE -> "Promise"
        Category.MEETING -> "Meeting"
        Category.FINANCIAL -> "Financial"
        Category.GENERAL -> "General"
    }
}

@Composable
fun FilterBadge(
    filter: AdvancedFilter,
    onClick: () -> Unit
) {
    if (filter.isActive()) {
        Badge(
            containerColor = MaterialTheme.colorScheme.primary
        ) {
            Text(filter.activeCount().toString())
        }
    }
}
