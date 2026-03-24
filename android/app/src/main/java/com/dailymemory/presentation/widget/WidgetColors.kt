package com.dailymemory.presentation.widget

import androidx.compose.ui.graphics.Color

/**
 * Color constants for widgets
 *
 * Note: Glance widgets have limited color support compared to regular Compose.
 * These colors are used across all widget variants for consistency.
 */
object WidgetColors {
    // Primary Brand Color
    val Primary = Color(0xFF6366F1)
    val PrimaryDark = Color(0xFF4F46E5)
    val OnPrimary = Color(0xFFFFFFFF)

    // Surface Colors
    val Surface = Color(0xFFFFFFFF)
    val Background = Color(0xFFF1F5F9)

    // Text Colors
    val TextPrimary = Color(0xFF1E293B)
    val TextSecondary = Color(0xFF64748B)

    // Status Colors
    val Warning = Color(0xFFF59E0B)
    val Success = Color(0xFF22C55E)
}
