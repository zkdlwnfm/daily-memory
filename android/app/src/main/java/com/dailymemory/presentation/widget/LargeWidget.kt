package com.dailymemory.presentation.widget

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.dailymemory.R
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Large Widget (4x2)
 *
 * Full featured widget showing:
 * - Current date with memory count
 * - Today's reminders (or "No reminders today")
 * - Voice and Text recording buttons
 */
class LargeWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        // In a real app, fetch this data from repository
        val memoryCount = 0
        val todayReminders = listOf<String>()

        provideContent {
            GlanceTheme {
                LargeWidgetContent(
                    memoryCount = memoryCount,
                    reminders = todayReminders
                )
            }
        }
    }

    @Composable
    private fun LargeWidgetContent(
        memoryCount: Int,
        reminders: List<String>
    ) {
        val today = LocalDate.now()
        val dateFormatter = DateTimeFormatter.ofPattern("EEEE, MMM d", Locale.getDefault())

        Row(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(WidgetColors.Surface)
                .cornerRadius(24.dp)
                .padding(16.dp)
        ) {
            // Left Section - Date & Reminders
            Column(
                modifier = GlanceModifier
                    .defaultWeight()
                    .fillMaxHeight()
            ) {
                // Date Header
                Column {
                    Text(
                        text = today.format(dateFormatter),
                        style = TextStyle(
                            color = ColorProvider(WidgetColors.TextPrimary),
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold
                        )
                    )

                    Text(
                        text = "$memoryCount memories",
                        style = TextStyle(
                            color = ColorProvider(WidgetColors.TextSecondary),
                            fontSize = 12.sp
                        )
                    )
                }

                Spacer(modifier = GlanceModifier.height(12.dp))

                // Reminders Card
                Box(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .defaultWeight()
                        .background(WidgetColors.Warning.copy(alpha = 0.15f))
                        .cornerRadius(16.dp)
                        .padding(12.dp)
                        .clickable(
                            actionStartActivity(
                                Intent().apply {
                                    setClassName("com.dailymemory", "com.dailymemory.presentation.MainActivity")
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                                }
                            )
                        ),
                    contentAlignment = Alignment.TopStart
                ) {
                    Column {
                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Image(
                                provider = ImageProvider(R.drawable.ic_bell),
                                contentDescription = null,
                                modifier = GlanceModifier.size(14.dp)
                            )
                            Spacer(modifier = GlanceModifier.width(6.dp))
                            Text(
                                text = "Reminders",
                                style = TextStyle(
                                    color = ColorProvider(WidgetColors.Warning),
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold
                                )
                            )
                        }

                        Spacer(modifier = GlanceModifier.height(6.dp))

                        if (reminders.isEmpty()) {
                            Text(
                                text = "No reminders today",
                                style = TextStyle(
                                    color = ColorProvider(WidgetColors.TextSecondary),
                                    fontSize = 11.sp
                                )
                            )
                        } else {
                            reminders.take(2).forEach { reminder ->
                                Text(
                                    text = "• $reminder",
                                    style = TextStyle(
                                        color = ColorProvider(WidgetColors.TextPrimary),
                                        fontSize = 11.sp
                                    ),
                                    maxLines = 1
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = GlanceModifier.width(12.dp))

            // Right Section - Action Buttons
            Column(
                modifier = GlanceModifier
                    .width(100.dp)
                    .fillMaxHeight(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Voice Button
                Box(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .defaultWeight()
                        .background(WidgetColors.Primary)
                        .cornerRadius(16.dp)
                        .clickable(
                            actionStartActivity(
                                Intent().apply {
                                    setClassName("com.dailymemory", "com.dailymemory.presentation.MainActivity")
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                                    putExtra("START_VOICE_RECORD", true)
                                }
                            )
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_mic),
                            contentDescription = "Voice",
                            modifier = GlanceModifier.size(24.dp)
                        )
                        Spacer(modifier = GlanceModifier.height(4.dp))
                        Text(
                            text = "Voice",
                            style = TextStyle(
                                color = ColorProvider(WidgetColors.OnPrimary),
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                textAlign = TextAlign.Center
                            )
                        )
                    }
                }

                Spacer(modifier = GlanceModifier.height(8.dp))

                // Text Button
                Box(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .defaultWeight()
                        .background(WidgetColors.Background)
                        .cornerRadius(16.dp)
                        .clickable(
                            actionStartActivity(
                                Intent().apply {
                                    setClassName("com.dailymemory", "com.dailymemory.presentation.MainActivity")
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                                    putExtra("START_TEXT_RECORD", true)
                                }
                            )
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_edit),
                            contentDescription = "Text",
                            modifier = GlanceModifier.size(24.dp)
                        )
                        Spacer(modifier = GlanceModifier.height(4.dp))
                        Text(
                            text = "Text",
                            style = TextStyle(
                                color = ColorProvider(WidgetColors.TextPrimary),
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                textAlign = TextAlign.Center
                            )
                        )
                    }
                }
            }
        }
    }
}

class LargeWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = LargeWidget()
}
