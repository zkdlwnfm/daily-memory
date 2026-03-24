package com.dailymemory.presentation.memory

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
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
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.LockOpen
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material.icons.filled.Tag
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import coil.request.ImageRequest
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import java.io.File
import com.dailymemory.domain.model.Category
import com.dailymemory.domain.model.Memory
import com.dailymemory.domain.model.Person
import com.dailymemory.domain.model.Photo
import com.dailymemory.presentation.photo.PhotoGalleryScreen
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MemoryDetailScreen(
    memoryId: String,
    onNavigateBack: () -> Unit,
    onEditClick: (String) -> Unit,
    onPersonClick: (String) -> Unit,
    viewModel: MemoryDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    var showMenu by remember { mutableStateOf(false) }
    var showPhotoGallery by remember { mutableStateOf(false) }
    var selectedPhotoIndex by remember { mutableIntStateOf(0) }

    LaunchedEffect(memoryId) {
        viewModel.loadMemory(memoryId)
    }

    LaunchedEffect(uiState.deleteSuccess) {
        if (uiState.deleteSuccess) {
            onNavigateBack()
        }
    }

    LaunchedEffect(uiState.error) {
        uiState.error?.let { error ->
            snackbarHostState.showSnackbar(error)
            viewModel.clearError()
        }
    }

    // Photo Gallery Full Screen
    if (showPhotoGallery && uiState.memory != null && uiState.memory!!.photos.isNotEmpty()) {
        PhotoGalleryScreen(
            photoIds = uiState.memory!!.photos.map { it.id },
            initialIndex = selectedPhotoIndex,
            onDismiss = { showPhotoGallery = false }
        )
    }

    // Delete Confirmation Dialog
    if (uiState.showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { viewModel.hideDeleteDialog() },
            title = { Text("Delete Memory") },
            text = { Text("Are you sure you want to delete this memory? This action cannot be undone.") },
            confirmButton = {
                TextButton(
                    onClick = { viewModel.deleteMemory() }
                ) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { viewModel.hideDeleteDialog() }) {
                    Text("Cancel")
                }
            }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                actions = {
                    if (uiState.memory != null) {
                        IconButton(onClick = { viewModel.toggleLock() }) {
                            Icon(
                                imageVector = if (uiState.memory!!.isLocked) Icons.Default.Lock else Icons.Default.LockOpen,
                                contentDescription = if (uiState.memory!!.isLocked) "Locked" else "Unlocked",
                                tint = if (uiState.memory!!.isLocked) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        IconButton(onClick = { onEditClick(memoryId) }) {
                            Icon(
                                imageVector = Icons.Default.Edit,
                                contentDescription = "Edit"
                            )
                        }
                        Box {
                            IconButton(onClick = { showMenu = true }) {
                                Icon(
                                    imageVector = Icons.Default.MoreVert,
                                    contentDescription = "More options"
                                )
                            }
                            DropdownMenu(
                                expanded = showMenu,
                                onDismissRequest = { showMenu = false }
                            ) {
                                DropdownMenuItem(
                                    text = { Text("Delete", color = MaterialTheme.colorScheme.error) },
                                    onClick = {
                                        showMenu = false
                                        viewModel.showDeleteDialog()
                                    },
                                    leadingIcon = {
                                        Icon(
                                            Icons.Default.Delete,
                                            contentDescription = null,
                                            tint = MaterialTheme.colorScheme.error
                                        )
                                    }
                                )
                            }
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .background(Color(0xFFF9F9FF))
        ) {
            when {
                uiState.isLoading || uiState.isDeleting -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
                uiState.memory == null -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "Memory not found",
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                else -> {
                    MemoryDetailContent(
                        memory = uiState.memory!!,
                        linkedPersons = uiState.linkedPersons,
                        onPersonClick = onPersonClick,
                        onCategoryChange = { viewModel.updateCategory(it) },
                        onImportanceChange = { viewModel.updateImportance(it) },
                        onPhotoClick = { index ->
                            selectedPhotoIndex = index
                            showPhotoGallery = true
                        }
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun MemoryDetailContent(
    memory: Memory,
    linkedPersons: List<Person>,
    onPersonClick: (String) -> Unit,
    onCategoryChange: (Category) -> Unit,
    onImportanceChange: (Int) -> Unit,
    onPhotoClick: (Int) -> Unit
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Date and Category Header
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.CalendarMonth,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = memory.recordedAt.format(
                            DateTimeFormatter.ofPattern("EEEE, MMMM d, yyyy")
                        ),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                }
                Text(
                    text = memory.recordedAt.format(
                        DateTimeFormatter.ofPattern("h:mm a")
                    ),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        // Main Content Card
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(
                    modifier = Modifier.padding(20.dp)
                ) {
                    Text(
                        text = memory.content,
                        style = MaterialTheme.typography.bodyLarge,
                        lineHeight = MaterialTheme.typography.bodyLarge.lineHeight * 1.4
                    )
                }
            }
        }

        // Photos Section
        if (memory.photos.isNotEmpty()) {
            item {
                PhotosSection(
                    photos = memory.photos,
                    onPhotoClick = onPhotoClick
                )
            }
        }

        // Extracted Information Section
        item {
            ExtractedInfoSection(memory = memory)
        }

        // Linked People
        if (linkedPersons.isNotEmpty()) {
            item {
                LinkedPeopleSection(
                    persons = linkedPersons,
                    onPersonClick = onPersonClick
                )
            }
        }

        // Tags
        if (memory.extractedTags.isNotEmpty()) {
            item {
                TagsSection(tags = memory.extractedTags)
            }
        }

        // Category & Importance
        item {
            CategoryAndImportanceSection(
                category = memory.category,
                importance = memory.importance,
                onCategoryChange = onCategoryChange,
                onImportanceChange = onImportanceChange
            )
        }

        // Metadata
        item {
            MetadataSection(memory = memory)
        }
    }
}

@Composable
private fun PhotosSection(
    photos: List<Photo>,
    onPhotoClick: (Int) -> Unit
) {
    val context = LocalContext.current

    Column {
        SectionHeader(title = "Photos (${photos.size})", icon = null)
        Spacer(modifier = Modifier.height(12.dp))
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            itemsIndexed(photos) { index, photo ->
                val thumbnailFile = remember(photo.id) {
                    File(context.filesDir, "thumbnails/${photo.id}_thumb.jpg")
                }

                Box(
                    modifier = Modifier
                        .size(120.dp)
                        .clip(RoundedCornerShape(16.dp))
                        .clickable { onPhotoClick(index) }
                ) {
                    AsyncImage(
                        model = ImageRequest.Builder(context)
                            .data(if (thumbnailFile.exists()) thumbnailFile else photo.thumbnailUrl ?: photo.url)
                            .crossfade(true)
                            .build(),
                        contentDescription = "Photo ${index + 1}",
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ExtractedInfoSection(memory: Memory) {
    val hasExtractedInfo = memory.extractedLocation != null ||
            memory.extractedAmount != null ||
            memory.extractedPersons.isNotEmpty()

    if (!hasExtractedInfo) return

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFFF1F3FF))
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "AI Extracted",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )

            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Location
                memory.extractedLocation?.let { location ->
                    InfoChip(
                        icon = Icons.Default.LocationOn,
                        text = location,
                        containerColor = Color(0xFFE8F5E9),
                        contentColor = Color(0xFF2E7D32)
                    )
                }

                // Amount
                memory.extractedAmount?.let { amount ->
                    InfoChip(
                        icon = Icons.Default.AttachMoney,
                        text = String.format("$%.2f", amount),
                        containerColor = Color(0xFFFFF8E1),
                        contentColor = Color(0xFFF57C00)
                    )
                }

                // Extracted Persons
                memory.extractedPersons.forEach { person ->
                    InfoChip(
                        icon = Icons.Default.Person,
                        text = person,
                        containerColor = Color(0xFFE3F2FD),
                        contentColor = Color(0xFF1976D2)
                    )
                }
            }
        }
    }
}

@Composable
private fun InfoChip(
    icon: ImageVector,
    text: String,
    containerColor: Color,
    contentColor: Color
) {
    Surface(
        shape = RoundedCornerShape(12.dp),
        color = containerColor
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(16.dp),
                tint = contentColor
            )
            Text(
                text = text,
                style = MaterialTheme.typography.bodySmall,
                fontWeight = FontWeight.Medium,
                color = contentColor
            )
        }
    }
}

@Composable
private fun LinkedPeopleSection(
    persons: List<Person>,
    onPersonClick: (String) -> Unit
) {
    Column {
        SectionHeader(title = "Linked People", icon = Icons.Default.Person)
        Spacer(modifier = Modifier.height(12.dp))
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(persons) { person ->
                PersonChip(
                    person = person,
                    onClick = { onPersonClick(person.id) }
                )
            }
        }
    }
}

@Composable
private fun PersonChip(
    person: Person,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(16.dp),
        color = Color.White,
        shadowElevation = 2.dp
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFDCE2F7)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Column {
                Text(
                    text = person.name,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = person.relationship.getDisplayName(),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun TagsSection(tags: List<String>) {
    Column {
        SectionHeader(title = "Tags", icon = Icons.Default.Tag)
        Spacer(modifier = Modifier.height(12.dp))
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            tags.forEach { tag ->
                AssistChip(
                    onClick = { },
                    label = { Text(tag) },
                    colors = AssistChipDefaults.assistChipColors(
                        containerColor = Color(0xFFEDE7F6),
                        labelColor = Color(0xFF5E35B1)
                    ),
                    border = null
                )
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun CategoryAndImportanceSection(
    category: Category,
    importance: Int,
    onCategoryChange: (Category) -> Unit,
    onImportanceChange: (Int) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Category
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = "Category",
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Category.entries.forEach { cat ->
                        val isSelected = cat == category
                        Surface(
                            onClick = { onCategoryChange(cat) },
                            shape = RoundedCornerShape(12.dp),
                            color = if (isSelected) MaterialTheme.colorScheme.primary else Color(0xFFF5F5F5)
                        ) {
                            Text(
                                text = getCategoryDisplayName(cat),
                                modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                                style = MaterialTheme.typography.bodySmall,
                                fontWeight = FontWeight.Medium,
                                color = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }

            // Importance
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = "Importance",
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    (1..5).forEach { star ->
                        Icon(
                            imageVector = if (star <= importance) Icons.Default.Star else Icons.Default.StarBorder,
                            contentDescription = "Star $star",
                            modifier = Modifier
                                .size(32.dp)
                                .clickable { onImportanceChange(star) },
                            tint = if (star <= importance) Color(0xFFFFB300) else Color(0xFFE0E0E0)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MetadataSection(memory: Memory) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFFFAFAFA))
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "Details",
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            MetadataRow("Created", memory.createdAt.format(DateTimeFormatter.ofPattern("MMM d, yyyy h:mm a")))
            MetadataRow("Updated", memory.updatedAt.format(DateTimeFormatter.ofPattern("MMM d, yyyy h:mm a")))

            memory.recordedLatitude?.let { lat ->
                memory.recordedLongitude?.let { lng ->
                    MetadataRow("Location", String.format("%.4f, %.4f", lat, lng))
                }
            }

            MetadataRow("Sync Status", memory.syncStatus.name.lowercase().replaceFirstChar { it.uppercase() })
        }
    }
}

@Composable
private fun MetadataRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodySmall,
            fontWeight = FontWeight.Medium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}

@Composable
private fun SectionHeader(
    title: String,
    icon: ImageVector?
) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        if (icon != null) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(18.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.width(8.dp))
        }
        Text(
            text = title,
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.Bold
        )
    }
}

private fun getCategoryDisplayName(category: Category): String {
    return when (category) {
        Category.EVENT -> "Event"
        Category.PROMISE -> "Promise"
        Category.MEETING -> "Meeting"
        Category.FINANCIAL -> "Financial"
        Category.GENERAL -> "General"
    }
}
