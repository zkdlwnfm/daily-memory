package com.dailymemory.presentation.common.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BrokenImage
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil.compose.SubcomposeAsyncImage
import coil.request.ImageRequest

/**
 * Async image with loading and error states
 * Uses Coil for image loading
 */
@Composable
fun AsyncImage(
    url: String?,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop,
    shape: Shape = RoundedCornerShape(8.dp),
    placeholderIcon: ImageVector = Icons.Default.Image,
    errorIcon: ImageVector = Icons.Default.BrokenImage,
    placeholderColor: Color = Color(0xFFE8E8E8)
) {
    if (url.isNullOrBlank()) {
        // No URL - show placeholder
        PlaceholderBox(
            icon = placeholderIcon,
            color = placeholderColor,
            shape = shape,
            modifier = modifier
        )
    } else {
        SubcomposeAsyncImage(
            model = ImageRequest.Builder(LocalContext.current)
                .data(url)
                .crossfade(true)
                .build(),
            contentDescription = contentDescription,
            modifier = modifier.clip(shape),
            contentScale = contentScale,
            loading = {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(placeholderColor),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            },
            error = {
                PlaceholderBox(
                    icon = errorIcon,
                    color = placeholderColor,
                    shape = shape,
                    modifier = Modifier.fillMaxSize()
                )
            }
        )
    }
}

/**
 * Avatar image with fallback to initials or icon
 */
@Composable
fun AvatarImage(
    imageUrl: String?,
    name: String?,
    modifier: Modifier = Modifier,
    size: Dp = 48.dp,
    backgroundColor: Color = Color(0xFFDCE2F7)
) {
    if (!imageUrl.isNullOrBlank()) {
        AsyncImage(
            url = imageUrl,
            contentDescription = "Profile picture of $name",
            shape = CircleShape,
            placeholderIcon = Icons.Default.Person,
            modifier = modifier.size(size)
        )
    } else {
        // Fallback to icon
        Box(
            modifier = modifier
                .size(size)
                .clip(CircleShape)
                .background(backgroundColor),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.Person,
                contentDescription = null,
                modifier = Modifier.size(size * 0.5f),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

/**
 * Photo thumbnail with rounded corners
 */
@Composable
fun PhotoThumbnail(
    url: String?,
    modifier: Modifier = Modifier,
    cornerRadius: Dp = 12.dp
) {
    AsyncImage(
        url = url,
        contentDescription = "Photo",
        shape = RoundedCornerShape(cornerRadius),
        modifier = modifier
    )
}

@Composable
private fun PlaceholderBox(
    icon: ImageVector,
    color: Color,
    shape: Shape,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .clip(shape)
            .background(color),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = Color.Gray.copy(alpha = 0.5f),
            modifier = Modifier.size(32.dp)
        )
    }
}
