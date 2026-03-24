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
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.dailymemory.R

/**
 * Medium Widget (2x2)
 *
 * Shows:
 * - "DailyMemory" title
 * - Recent memory preview (if available)
 * - Voice and Text recording buttons
 */
class MediumWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        // In a real app, you would fetch recent memory data here
        val recentMemory = "No recent memories"

        provideContent {
            GlanceTheme {
                MediumWidgetContent(recentMemory = recentMemory)
            }
        }
    }

    @Composable
    private fun MediumWidgetContent(recentMemory: String) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(WidgetColors.Surface)
                .cornerRadius(24.dp)
                .padding(16.dp)
        ) {
            // Header
            Text(
                text = "DailyMemory",
                style = TextStyle(
                    color = ColorProvider(WidgetColors.Primary),
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold
                )
            )

            Spacer(modifier = GlanceModifier.height(8.dp))

            // Recent Memory Preview
            Box(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .defaultWeight()
                    .background(WidgetColors.Background)
                    .cornerRadius(12.dp)
                    .padding(12.dp),
                contentAlignment = Alignment.TopStart
            ) {
                Text(
                    text = recentMemory,
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.TextSecondary),
                        fontSize = 12.sp
                    ),
                    maxLines = 2
                )
            }

            Spacer(modifier = GlanceModifier.height(12.dp))

            // Action Buttons
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Voice Button
                Box(
                    modifier = GlanceModifier
                        .defaultWeight()
                        .height(44.dp)
                        .background(WidgetColors.Primary)
                        .cornerRadius(12.dp)
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
                    Row(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_mic),
                            contentDescription = "Voice",
                            modifier = GlanceModifier.size(18.dp)
                        )
                        Spacer(modifier = GlanceModifier.width(6.dp))
                        Text(
                            text = "Voice",
                            style = TextStyle(
                                color = ColorProvider(WidgetColors.OnPrimary),
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold
                            )
                        )
                    }
                }

                Spacer(modifier = GlanceModifier.width(8.dp))

                // Text Button
                Box(
                    modifier = GlanceModifier
                        .defaultWeight()
                        .height(44.dp)
                        .background(WidgetColors.Background)
                        .cornerRadius(12.dp)
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
                    Row(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_edit),
                            contentDescription = "Text",
                            modifier = GlanceModifier.size(18.dp)
                        )
                        Spacer(modifier = GlanceModifier.width(6.dp))
                        Text(
                            text = "Text",
                            style = TextStyle(
                                color = ColorProvider(WidgetColors.TextPrimary),
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold
                            )
                        )
                    }
                }
            }
        }
    }
}

class MediumWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = MediumWidget()
}
