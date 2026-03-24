package com.dailymemory.presentation.person

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Cake
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.EditNote
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.dailymemory.domain.model.Person
import com.dailymemory.domain.model.Relationship
import java.time.format.DateTimeFormatter

@Composable
fun PersonListScreen(
    onPersonClick: (String) -> Unit,
    onAddPersonClick: () -> Unit = {},
    viewModel: PeopleViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF9F9FF))
    ) {
        // Header
        PeopleHeader(
            onAddClick = onAddPersonClick
        )

        // Search Bar
        SearchBar(
            query = uiState.searchQuery,
            onQueryChange = viewModel::updateSearchQuery,
            modifier = Modifier.padding(horizontal = 24.dp)
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Sort Tabs
        SortTabs(
            selectedSort = uiState.sortOrder,
            onSortSelected = viewModel::updateSortOrder,
            modifier = Modifier.padding(horizontal = 24.dp)
        )

        Spacer(modifier = Modifier.height(16.dp))

        // People List
        if (uiState.filteredPeople.isEmpty() && !uiState.isLoading) {
            PeopleEmptyState(
                onAddClick = onAddPersonClick
            )
        } else {
            LazyColumn(
                contentPadding = PaddingValues(horizontal = 24.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(uiState.filteredPeople) { person ->
                    PersonCard(
                        person = person,
                        onClick = { onPersonClick(person.id) }
                    )
                }
                item { Spacer(modifier = Modifier.height(80.dp)) }
            }
        }
    }
}

@Composable
private fun PeopleHeader(
    onAddClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                imageVector = Icons.Default.Group,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(28.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Column {
                Text(
                    text = "People",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.ExtraBold
                )
                Text(
                    text = "Keep track of your meaningful connections",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        Surface(
            onClick = onAddClick,
            shape = RoundedCornerShape(12.dp),
            color = MaterialTheme.colorScheme.primary,
            shadowElevation = 4.dp
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = "Add",
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp
                )
            }
        }
    }
}

@Composable
private fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        placeholder = {
            Text(
                text = "Search people...",
                color = MaterialTheme.colorScheme.outline.copy(alpha = 0.6f)
            )
        },
        leadingIcon = {
            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.outline
            )
        },
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = OutlinedTextFieldDefaults.colors(
            unfocusedContainerColor = Color(0xFFF1F3FF),
            focusedContainerColor = Color.White,
            unfocusedBorderColor = Color.Transparent,
            focusedBorderColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
        ),
        singleLine = true
    )
}

@Composable
private fun SortTabs(
    selectedSort: SortOrder,
    onSortSelected: (SortOrder) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyRow(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(SortOrder.entries) { sortOrder ->
            val selected = sortOrder == selectedSort
            FilterChip(
                selected = selected,
                onClick = { onSortSelected(sortOrder) },
                label = {
                    Text(
                        text = when (sortOrder) {
                            SortOrder.RECENT -> "Recent"
                            SortOrder.ALPHABETICAL -> "A-Z"
                            SortOrder.FREQUENT -> "Frequent"
                        },
                        fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal
                    )
                },
                colors = FilterChipDefaults.filterChipColors(
                    selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                    selectedLabelColor = Color.White
                )
            )
        }
    }
}

@Composable
private fun PersonCard(
    person: Person,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val displayItem = person.toDisplayItem()

    Card(
        onClick = onClick,
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .then(
                    if (displayItem.hasNoContactWarning) {
                        Modifier.drawLeftBorder(Color(0xFFBA1A1A))
                    } else if (displayItem.hasUpcomingEvent) {
                        Modifier.drawLeftBorder(Color(0xFFB55D00))
                    } else {
                        Modifier
                    }
                )
                .padding(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Avatar
            PersonAvatar(
                name = person.name,
                imageUrl = person.profileImageUrl,
                relationship = person.relationship
            )

            Spacer(modifier = Modifier.width(16.dp))

            // Info
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = person.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Icon(
                        imageVector = Icons.Default.ChevronRight,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.outline.copy(alpha = 0.4f)
                    )
                }

                Text(
                    text = buildString {
                        append(person.relationship.getDisplayName())
                        person.lastMeetingDate?.let { date ->
                            append(" · Last seen ")
                            append(date.format(DateTimeFormatter.ofPattern("MMM d")))
                        }
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(8.dp))

                // Tags
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Memory count
                    TagChip(
                        icon = Icons.Default.EditNote,
                        text = "${person.meetingCount} memories",
                        color = MaterialTheme.colorScheme.primary
                    )

                    // Upcoming event badge
                    if (displayItem.hasUpcomingEvent) {
                        displayItem.upcomingEventLabel?.let { label ->
                            TagChip(
                                icon = Icons.Default.Cake,
                                text = label,
                                color = Color(0xFFB55D00),
                                backgroundColor = Color(0xFFFFDCC5).copy(alpha = 0.3f)
                            )
                        }
                    }

                    // No contact warning
                    if (displayItem.hasNoContactWarning) {
                        TagChip(
                            icon = Icons.Default.Warning,
                            text = "No contact for ${displayItem.noContactDays} days",
                            color = Color(0xFFBA1A1A),
                            backgroundColor = Color(0xFFFFDAD6).copy(alpha = 0.4f)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun PersonAvatar(
    name: String,
    imageUrl: String?,
    relationship: Relationship,
    modifier: Modifier = Modifier
) {
    val backgroundColor = when (relationship) {
        Relationship.FAMILY -> Color(0xFFE9DDFF)
        Relationship.FRIEND -> Color(0xFFE1E0FF)
        Relationship.COLLEAGUE -> Color(0xFFE1E8FD)
        else -> Color(0xFFDCE2F7)
    }

    Box(
        modifier = modifier
            .size(56.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(backgroundColor),
        contentAlignment = Alignment.Center
    ) {
        if (imageUrl != null) {
            // TODO: Load image with Coil
            Text(
                text = name.take(2).uppercase(),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        } else {
            Icon(
                imageVector = Icons.Default.Person,
                contentDescription = null,
                modifier = Modifier.size(28.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun TagChip(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    text: String,
    color: Color,
    backgroundColor: Color = color.copy(alpha = 0.05f),
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .background(backgroundColor, RoundedCornerShape(8.dp))
            .padding(horizontal = 8.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(12.dp),
            tint = color
        )
        Text(
            text = text,
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold,
            color = color
        )
    }
}

@Composable
private fun PeopleEmptyState(
    onAddClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "👥",
            fontSize = 64.sp
        )
        Spacer(modifier = Modifier.height(24.dp))
        Text(
            text = "No people yet",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Record memories and AI will automatically find people, or add them manually.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )
        Spacer(modifier = Modifier.height(24.dp))
        Surface(
            onClick = onAddClick,
            shape = RoundedCornerShape(16.dp),
            color = MaterialTheme.colorScheme.primary
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 24.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = null,
                    tint = Color.White
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Add Person",
                    color = Color.White,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

// Custom modifier for left border
private fun Modifier.drawLeftBorder(color: Color): Modifier = this.then(
    Modifier.clip(RoundedCornerShape(24.dp))
)
