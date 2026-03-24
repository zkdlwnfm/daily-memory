package com.dailymemory.presentation.home

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
import androidx.compose.material.icons.filled.Cake
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Payments
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.dailymemory.presentation.common.theme.Accent
import com.dailymemory.presentation.common.theme.Primary
import java.time.LocalTime
import java.util.Locale
import androidx.compose.ui.unit.sp

@Composable
fun HomeScreen(
    onMemoryClick: (String) -> Unit,
    onReminderClick: (String) -> Unit
) {
    val greeting = remember { getGreeting() }
    val userName = "Alex" // TODO: Get from user preferences

    // Sample data - TODO: Replace with ViewModel data
    val todayMemoryCount = 2
    val reminderCount = 1
    val hasReminder = true
    val hasFlashback = true

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background),
        contentPadding = PaddingValues(bottom = 100.dp)
    ) {
        // Greeting Section
        item {
            GreetingSection(
                greeting = greeting,
                userName = userName,
                memoryCount = todayMemoryCount,
                reminderCount = reminderCount
            )
        }

        // Reminder Card
        if (hasReminder) {
            item {
                ReminderCard(
                    title = "Mom's birthday tomorrow",
                    description = "Last year you gave her a massage chair.",
                    icon = Icons.Default.Cake,
                    onDone = { /* TODO */ },
                    onSnooze = { /* TODO */ }
                )
            }
        }

        // Recent Memories Section
        item {
            SectionHeader(
                title = "Recent Memories",
                emoji = "\uD83D\uDCDD",
                onSeeAllClick = { /* TODO */ }
            )
        }

        // Memory Cards
        items(getSampleMemories()) { memory ->
            MemoryCard(
                memory = memory,
                onClick = { onMemoryClick(memory.id) }
            )
        }

        // On This Day Section
        if (hasFlashback) {
            item {
                Spacer(modifier = Modifier.height(24.dp))
                OnThisDaySection(
                    title = "Family trip - Beach vacation",
                    date = "October 14, 2023",
                    imageUrl = "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
                    onClick = { /* TODO */ }
                )
            }
        }
    }
}

@Composable
private fun GreetingSection(
    greeting: String,
    userName: String,
    memoryCount: Int,
    reminderCount: Int
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 16.dp)
    ) {
        Text(
            text = "$greeting, $userName \uD83D\uDC4B",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onBackground
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = "$memoryCount memories today · $reminderCount reminder",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun ReminderCard(
    title: String,
    description: String,
    icon: ImageVector,
    onDone: () -> Unit,
    onSnooze: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 8.dp),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFFFFF7ED) // Orange light background
        )
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = Color(0xFFEA580C),
                    modifier = Modifier.size(24.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF431407)
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = description,
                style = MaterialTheme.typography.bodyMedium,
                color = Color(0xFF78350F)
            )

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedButton(
                    onClick = onDone,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = Color(0xFF431407)
                    )
                ) {
                    Text("DONE", fontWeight = FontWeight.Bold)
                }

                Button(
                    onClick = onSnooze,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Primary
                    )
                ) {
                    Text("SNOOZE", fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
private fun SectionHeader(
    title: String,
    emoji: String,
    onSeeAllClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "$emoji $title",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onBackground
        )
        TextButton(onClick = onSeeAllClick) {
            Text(
                text = "See all ›",
                color = Primary,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

@Composable
private fun MemoryCard(
    memory: MemoryUiModel,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 6.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = memory.formattedDate.uppercase(Locale.getDefault()),
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                color = Primary.copy(alpha = 0.7f),
                letterSpacing = 1.sp
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = memory.content,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            if (memory.tags.isNotEmpty()) {
                Spacer(modifier = Modifier.height(12.dp))

                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(memory.tags) { tag ->
                        TagChip(tag = tag)
                    }
                }
            }
        }
    }
}

@Composable
private fun TagChip(tag: TagUiModel) {
    Surface(
        shape = RoundedCornerShape(20.dp),
        color = MaterialTheme.colorScheme.surfaceVariant
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = tag.icon,
                contentDescription = null,
                modifier = Modifier.size(14.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = tag.label,
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun OnThisDaySection(
    title: String,
    date: String,
    imageUrl: String,
    onClick: () -> Unit
) {
    Column(
        modifier = Modifier.padding(horizontal = 24.dp)
    ) {
        Text(
            text = "\uD83D\uDCF8 On this day, 1 year ago",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onBackground
        )

        Spacer(modifier = Modifier.height(16.dp))

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .height(180.dp)
                .clickable(onClick = onClick),
            shape = RoundedCornerShape(24.dp)
        ) {
            Box {
                AsyncImage(
                    model = imageUrl,
                    contentDescription = title,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )

                // Gradient overlay
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(
                                    Color.Transparent,
                                    Color.Black.copy(alpha = 0.7f)
                                ),
                                startY = 100f
                            )
                        )
                )

                // Text overlay
                Column(
                    modifier = Modifier
                        .align(Alignment.BottomStart)
                        .padding(20.dp)
                ) {
                    Text(
                        text = title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                    Text(
                        text = date,
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.White.copy(alpha = 0.7f)
                    )
                }
            }
        }
    }
}

// Helper functions and models
private fun getGreeting(): String {
    return when (LocalTime.now().hour) {
        in 5..11 -> "Good morning"
        in 12..17 -> "Good afternoon"
        in 18..21 -> "Good evening"
        else -> "Good night"
    }
}

data class MemoryUiModel(
    val id: String,
    val content: String,
    val formattedDate: String,
    val tags: List<TagUiModel>
)

data class TagUiModel(
    val icon: ImageVector,
    val label: String
)

private fun getSampleMemories(): List<MemoryUiModel> {
    return listOf(
        MemoryUiModel(
            id = "1",
            content = "Had lunch with Mike in downtown. He's getting married next month.",
            formattedDate = "Today, 2:30 PM",
            tags = listOf(
                TagUiModel(Icons.Default.Person, "Mike"),
                TagUiModel(Icons.Default.LocationOn, "Downtown"),
                TagUiModel(Icons.Default.Payments, "Gift")
            )
        ),
        MemoryUiModel(
            id = "2",
            content = "Meeting with Acme Corp - project proposal went well",
            formattedDate = "Yesterday, 6:00 PM",
            tags = emptyList()
        )
    )
}
