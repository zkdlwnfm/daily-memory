package com.dailymemory.presentation.common.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CloudOff
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Inbox
import androidx.compose.material.icons.filled.SearchOff
import androidx.compose.material.icons.filled.WifiOff
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

/**
 * Loading state with optional message
 */
@Composable
fun LoadingState(
    modifier: Modifier = Modifier,
    message: String? = null
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            CircularProgressIndicator(
                modifier = Modifier.size(48.dp),
                color = MaterialTheme.colorScheme.primary
            )
            if (message != null) {
                Text(
                    text = message,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

/**
 * Error state with retry button
 */
@Composable
fun ErrorState(
    message: String,
    modifier: Modifier = Modifier,
    title: String = "Something went wrong",
    icon: ImageVector = Icons.Default.Error,
    onRetry: (() -> Unit)? = null
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier.padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.error.copy(alpha = 0.7f)
            )

            Text(
                text = title,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )

            Text(
                text = message,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )

            if (onRetry != null) {
                Spacer(modifier = Modifier.height(8.dp))
                Button(
                    onClick = onRetry,
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text(
                        text = "Try Again",
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }
    }
}

/**
 * Network error state
 */
@Composable
fun NetworkErrorState(
    modifier: Modifier = Modifier,
    onRetry: (() -> Unit)? = null
) {
    ErrorState(
        title = "No Internet Connection",
        message = "Please check your connection and try again.",
        icon = Icons.Default.WifiOff,
        onRetry = onRetry,
        modifier = modifier
    )
}

/**
 * Empty state with customizable content
 */
@Composable
fun EmptyState(
    title: String,
    message: String,
    modifier: Modifier = Modifier,
    emoji: String? = null,
    icon: ImageVector? = Icons.Default.Inbox,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier.padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            if (emoji != null) {
                Text(
                    text = emoji,
                    style = MaterialTheme.typography.displayLarge
                )
            } else if (icon != null) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    modifier = Modifier.size(64.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                )
            }

            Text(
                text = title,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )

            Text(
                text = message,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )

            if (actionLabel != null && onAction != null) {
                Spacer(modifier = Modifier.height(8.dp))
                Button(
                    onClick = onAction,
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.primary
                    )
                ) {
                    Text(
                        text = actionLabel,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }
    }
}

/**
 * Search empty state
 */
@Composable
fun SearchEmptyState(
    query: String,
    modifier: Modifier = Modifier,
    onClearSearch: (() -> Unit)? = null
) {
    EmptyState(
        title = "No results found",
        message = "No matches for \"$query\". Try a different search term.",
        icon = Icons.Default.SearchOff,
        actionLabel = if (onClearSearch != null) "Clear Search" else null,
        onAction = onClearSearch,
        modifier = modifier
    )
}

// Predefined empty states for common scenarios
object EmptyStates {
    @Composable
    fun Memories(
        modifier: Modifier = Modifier,
        onAddMemory: (() -> Unit)? = null
    ) {
        EmptyState(
            emoji = "\uD83D\uDCDD",
            title = "No memories yet",
            message = "Start recording your thoughts and moments. They'll appear here.",
            actionLabel = if (onAddMemory != null) "Record Memory" else null,
            onAction = onAddMemory,
            modifier = modifier
        )
    }

    @Composable
    fun People(
        modifier: Modifier = Modifier,
        onAddPerson: (() -> Unit)? = null
    ) {
        EmptyState(
            emoji = "\uD83D\uDC65",
            title = "No people yet",
            message = "Record memories and AI will automatically find people, or add them manually.",
            actionLabel = if (onAddPerson != null) "Add Person" else null,
            onAction = onAddPerson,
            modifier = modifier
        )
    }

    @Composable
    fun Reminders(
        modifier: Modifier = Modifier,
        onAddReminder: (() -> Unit)? = null
    ) {
        EmptyState(
            emoji = "\uD83D\uDD14",
            title = "No reminders",
            message = "You're all caught up! Add reminders to stay on top of important things.",
            actionLabel = if (onAddReminder != null) "Add Reminder" else null,
            onAction = onAddReminder,
            modifier = modifier
        )
    }

    @Composable
    fun Timeline(
        modifier: Modifier = Modifier
    ) {
        EmptyState(
            emoji = "\uD83D\uDCC5",
            title = "No timeline events",
            message = "Memories with this person will appear here.",
            modifier = modifier
        )
    }
}
