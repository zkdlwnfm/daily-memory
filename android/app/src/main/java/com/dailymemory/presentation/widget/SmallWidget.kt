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
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.dailymemory.R
import com.dailymemory.presentation.MainActivity

/**
 * Small Widget (1x1)
 *
 * Simple one-tap voice recording widget with:
 * - Primary color background (#6366F1)
 * - Microphone icon
 * - "Record" label
 * - One tap to open voice recording
 */
class SmallWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceTheme {
                SmallWidgetContent()
            }
        }
    }

    @Composable
    private fun SmallWidgetContent() {
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(WidgetColors.Primary)
                .cornerRadius(16.dp)
                .clickable(
                    actionStartActivity(
                        Intent("com.dailymemory.ACTION_VOICE_RECORD").apply {
                            setClassName("com.dailymemory", "com.dailymemory.presentation.MainActivity")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                            putExtra("START_VOICE_RECORD", true)
                        }
                    )
                ),
            contentAlignment = Alignment.Center
        ) {
            Column(
                modifier = GlanceModifier.padding(8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Image(
                    provider = ImageProvider(R.drawable.ic_mic),
                    contentDescription = "Record",
                    modifier = GlanceModifier.size(32.dp)
                )

                Spacer(modifier = GlanceModifier.height(4.dp))

                Text(
                    text = "Record",
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.OnPrimary),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
            }
        }
    }
}

class SmallWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = SmallWidget()
}
