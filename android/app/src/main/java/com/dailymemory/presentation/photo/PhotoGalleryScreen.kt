package com.dailymemory.presentation.photo

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.dailymemory.data.service.PhotoService
import java.io.File

@OptIn(ExperimentalMaterial3Api::class, androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
fun PhotoGalleryScreen(
    photoIds: List<String>,
    initialIndex: Int = 0,
    onDelete: ((String) -> Unit)? = null,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    var currentIndex by remember { mutableIntStateOf(initialIndex) }
    var showControls by remember { mutableStateOf(true) }
    var showDeleteDialog by remember { mutableStateOf(false) }

    val pagerState = rememberPagerState(
        initialPage = initialIndex,
        pageCount = { photoIds.size }
    )

    LaunchedEffect(pagerState.currentPage) {
        currentIndex = pagerState.currentPage
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        // Photo pager
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.fillMaxSize()
        ) { page ->
            ZoomablePhoto(
                photoId = photoIds[page],
                onClick = { showControls = !showControls }
            )
        }

        // Top bar with controls
        AnimatedVisibility(
            visible = showControls,
            enter = fadeIn(),
            exit = fadeOut(),
            modifier = Modifier.align(Alignment.TopCenter)
        ) {
            TopAppBar(
                title = {
                    Text(
                        "${currentIndex + 1} / ${photoIds.size}",
                        color = Color.White
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(
                            Icons.Default.Close,
                            contentDescription = "Close",
                            tint = Color.White
                        )
                    }
                },
                actions = {
                    if (onDelete != null) {
                        IconButton(onClick = { showDeleteDialog = true }) {
                            Icon(
                                Icons.Default.Delete,
                                contentDescription = "Delete",
                                tint = Color.White
                            )
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Black.copy(alpha = 0.5f)
                )
            )
        }

        // Page indicator
        if (photoIds.size > 1) {
            AnimatedVisibility(
                visible = showControls,
                enter = fadeIn(),
                exit = fadeOut(),
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 32.dp)
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    photoIds.forEachIndexed { index, _ ->
                        Box(
                            modifier = Modifier
                                .size(if (index == currentIndex) 8.dp else 6.dp)
                                .clip(CircleShape)
                                .background(
                                    if (index == currentIndex) Color.White
                                    else Color.White.copy(alpha = 0.5f)
                                )
                        )
                    }
                }
            }
        }
    }

    // Delete confirmation dialog
    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete Photo") },
            text = { Text("Are you sure you want to delete this photo?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        onDelete?.invoke(photoIds[currentIndex])
                        showDeleteDialog = false
                        if (photoIds.size == 1) {
                            onDismiss()
                        }
                    }
                ) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun ZoomablePhoto(
    photoId: String,
    onClick: () -> Unit
) {
    val context = LocalContext.current
    var scale by remember { mutableFloatStateOf(1f) }
    var offsetX by remember { mutableFloatStateOf(0f) }
    var offsetY by remember { mutableFloatStateOf(0f) }

    // Get photo file
    val photoFile = remember(photoId) {
        File(context.filesDir, "photos/$photoId.jpg")
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .pointerInput(Unit) {
                detectTapGestures(
                    onTap = { onClick() },
                    onDoubleTap = {
                        if (scale > 1f) {
                            scale = 1f
                            offsetX = 0f
                            offsetY = 0f
                        } else {
                            scale = 2.5f
                        }
                    }
                )
            }
            .pointerInput(Unit) {
                detectTransformGestures { _, pan, zoom, _ ->
                    scale = (scale * zoom).coerceIn(1f, 5f)
                    if (scale > 1f) {
                        offsetX += pan.x
                        offsetY += pan.y
                    } else {
                        offsetX = 0f
                        offsetY = 0f
                    }
                }
            },
        contentAlignment = Alignment.Center
    ) {
        AsyncImage(
            model = ImageRequest.Builder(context)
                .data(photoFile)
                .crossfade(true)
                .build(),
            contentDescription = "Photo",
            contentScale = ContentScale.Fit,
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer(
                    scaleX = scale,
                    scaleY = scale,
                    translationX = offsetX,
                    translationY = offsetY
                )
        )
    }
}

@Composable
fun PhotoThumbnailGrid(
    photoIds: List<String>,
    onPhotoClick: (Int) -> Unit,
    onAddClick: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current

    LazyVerticalGrid(
        columns = GridCells.Fixed(3),
        contentPadding = PaddingValues(4.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
        modifier = modifier
    ) {
        // Add photo button
        if (onAddClick != null) {
            item {
                Box(
                    modifier = Modifier
                        .aspectRatio(1f)
                        .clip(RoundedCornerShape(8.dp))
                        .background(MaterialTheme.colorScheme.surfaceVariant)
                        .clickable(onClick = onAddClick),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Default.Add,
                        contentDescription = "Add photo",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(32.dp)
                    )
                }
            }
        }

        // Photo thumbnails
        itemsIndexed(photoIds) { index, photoId ->
            val thumbnailFile = remember(photoId) {
                File(context.filesDir, "thumbnails/${photoId}_thumb.jpg")
            }

            AsyncImage(
                model = ImageRequest.Builder(context)
                    .data(thumbnailFile)
                    .crossfade(true)
                    .build(),
                contentDescription = "Photo thumbnail",
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .aspectRatio(1f)
                    .clip(RoundedCornerShape(8.dp))
                    .clickable { onPhotoClick(index) }
            )
        }
    }
}

@Composable
fun PhotoPreviewRow(
    photoIds: List<String>,
    maxDisplay: Int = 4,
    onPhotoClick: (Int) -> Unit,
    onViewAllClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val displayPhotos = photoIds.take(maxDisplay)
    val remainingCount = photoIds.size - maxDisplay

    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        displayPhotos.forEachIndexed { index, photoId ->
            val thumbnailFile = remember(photoId) {
                File(context.filesDir, "thumbnails/${photoId}_thumb.jpg")
            }

            Box(
                modifier = Modifier
                    .size(64.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .clickable { onPhotoClick(index) }
            ) {
                AsyncImage(
                    model = ImageRequest.Builder(context)
                        .data(thumbnailFile)
                        .crossfade(true)
                        .build(),
                    contentDescription = "Photo thumbnail",
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )

                // Show remaining count on last item
                if (index == maxDisplay - 1 && remainingCount > 0) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(Color.Black.copy(alpha = 0.6f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            "+$remainingCount",
                            color = Color.White,
                            style = MaterialTheme.typography.titleMedium
                        )
                    }
                }
            }
        }

        // View all button if there are more photos
        if (photoIds.size > maxDisplay) {
            TextButton(
                onClick = onViewAllClick,
                modifier = Modifier.align(Alignment.CenterVertically)
            ) {
                Text("View all")
            }
        }
    }
}
