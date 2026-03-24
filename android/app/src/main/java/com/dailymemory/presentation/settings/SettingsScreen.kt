package com.dailymemory.presentation.settings

import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Cloud
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.EditNote
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Policy
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material.icons.filled.Upload
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun SettingsScreen(
    onNavigateToAccount: () -> Unit = {},
    onNavigateToStorage: () -> Unit = {},
    onNavigateToExport: () -> Unit = {},
    onNavigateToImport: () -> Unit = {},
    onNavigateToQuietHours: () -> Unit = {},
    onNavigateToPrivacyPolicy: () -> Unit = {},
    onNavigateToTerms: () -> Unit = {},
    onNavigateToContact: () -> Unit = {},
    onNavigateToRate: () -> Unit = {},
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF9F9FF)),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 24.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        // Title
        item {
            Text(
                text = "Settings",
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.ExtraBold,
                modifier = Modifier.padding(horizontal = 8.dp)
            )
        }

        // Account Section
        item {
            SettingsSection(title = "Account") {
                AccountCard(
                    email = uiState.userEmail,
                    isPremium = uiState.isPremium,
                    onClick = onNavigateToAccount
                )
            }
        }

        // Data Section
        item {
            SettingsSection(title = "Data") {
                SettingsCard {
                    SettingsRowWithIcon(
                        icon = Icons.Default.Cloud,
                        iconBackgroundColor = Color(0xFF904900).copy(alpha = 0.1f),
                        iconTint = Color(0xFF904900),
                        title = "Storage & Cloud sync",
                        onClick = onNavigateToStorage
                    )

                    SettingsDivider()

                    SettingsRowWithSubtitle(
                        icon = Icons.Default.Sync,
                        iconBackgroundColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                        iconTint = MaterialTheme.colorScheme.primary,
                        title = "Sync status",
                        subtitle = "Last: ${uiState.lastSyncTime}",
                        trailing = {
                            Surface(
                                onClick = { viewModel.syncNow() },
                                color = Color(0xFFF1F3FF),
                                shape = RoundedCornerShape(20.dp)
                            ) {
                                Text(
                                    text = "Sync now",
                                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                                    color = MaterialTheme.colorScheme.primary,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 12.sp
                                )
                            }
                        }
                    )

                    SettingsDivider()

                    SettingsRowWithIcon(
                        icon = Icons.Default.Upload,
                        iconBackgroundColor = Color(0xFF141B2B).copy(alpha = 0.05f),
                        iconTint = Color(0xFF141B2B),
                        title = "Export data",
                        onClick = onNavigateToExport
                    )

                    SettingsDivider()

                    SettingsRowWithIcon(
                        icon = Icons.Default.Download,
                        iconBackgroundColor = Color(0xFF141B2B).copy(alpha = 0.05f),
                        iconTint = Color(0xFF141B2B),
                        title = "Import data",
                        onClick = onNavigateToImport
                    )
                }
            }
        }

        // Notifications Section
        item {
            SettingsSection(title = "Notifications") {
                SettingsCard {
                    SettingsToggleRow(
                        icon = Icons.Default.Notifications,
                        iconBackgroundColor = Color(0xFFFFF3E0),
                        iconTint = Color(0xFFE65100),
                        title = "Reminders",
                        isEnabled = uiState.remindersEnabled,
                        onToggle = viewModel::toggleReminders
                    )

                    SettingsDivider()

                    SettingsToggleRowWithSubtitle(
                        icon = Icons.Default.EditNote,
                        iconBackgroundColor = Color(0xFFE3F2FD),
                        iconTint = Color(0xFF1976D2),
                        title = "Daily prompt",
                        subtitle = "Every day at ${uiState.dailyPromptTime}",
                        isEnabled = uiState.dailyPromptEnabled,
                        onToggle = viewModel::toggleDailyPrompt
                    )

                    SettingsDivider()

                    SettingsRowWithSubtitle(
                        icon = Icons.Default.Bedtime,
                        iconBackgroundColor = Color(0xFFECEFF1),
                        iconTint = Color(0xFF546E7A),
                        title = "Quiet hours",
                        subtitle = "${uiState.quietHoursEnd} - ${uiState.quietHoursStart}",
                        trailing = {
                            Text(
                                text = "Set >",
                                color = MaterialTheme.colorScheme.primary,
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp
                            )
                        },
                        onClick = onNavigateToQuietHours
                    )

                    SettingsDivider()

                    SettingsToggleRow(
                        icon = Icons.Default.CalendarToday,
                        iconBackgroundColor = Color(0xFFFCE4EC),
                        iconTint = Color(0xFFC2185B),
                        title = "On this day",
                        isEnabled = uiState.onThisDayEnabled,
                        onToggle = viewModel::toggleOnThisDay
                    )
                }
            }
        }

        // Privacy & Security Section
        item {
            SettingsSection(title = "Privacy & Security") {
                SettingsCard {
                    SettingsToggleRow(
                        icon = Icons.Default.Lock,
                        iconBackgroundColor = Color(0xFFE8F5E9),
                        iconTint = Color(0xFF388E3C),
                        title = "App lock (Face ID)",
                        isEnabled = uiState.appLockEnabled,
                        onToggle = viewModel::toggleAppLock
                    )

                    SettingsDivider()

                    SettingsToggleRow(
                        icon = Icons.Default.VisibilityOff,
                        iconBackgroundColor = Color(0xFFFFF9C4),
                        iconTint = Color(0xFFFBC02D),
                        title = "Show locked memories",
                        isEnabled = uiState.showLockedMemories,
                        onToggle = viewModel::toggleShowLockedMemories
                    )
                }
            }
        }

        // AI Features Section
        item {
            SettingsSection(title = "AI Features") {
                Box(
                    modifier = Modifier
                        .background(
                            Color(0xFF8455EF).copy(alpha = 0.1f),
                            RoundedCornerShape(32.dp)
                        )
                        .padding(4.dp)
                ) {
                    SettingsCard {
                        SettingsToggleRow(
                            icon = Icons.Default.AutoAwesome,
                            iconBackgroundColor = Color(0xFF8455EF).copy(alpha = 0.2f),
                            iconTint = Color(0xFF6B38D4),
                            title = "Auto-analyze memories",
                            isEnabled = uiState.autoAnalyzeEnabled,
                            onToggle = viewModel::toggleAutoAnalyze
                        )

                        SettingsDivider()

                        SettingsToggleRow(
                            icon = Icons.Default.Lightbulb,
                            iconBackgroundColor = Color(0xFF8455EF).copy(alpha = 0.2f),
                            iconTint = Color(0xFF6B38D4),
                            title = "Smart reminder suggestions",
                            isEnabled = uiState.smartRemindersEnabled,
                            onToggle = viewModel::toggleSmartReminders
                        )
                    }
                }
            }
        }

        // About Section
        item {
            SettingsSection(title = "About") {
                SettingsCard {
                    SettingsRowWithValue(
                        icon = Icons.Default.Info,
                        iconBackgroundColor = Color(0xFFF1F3FF),
                        iconTint = MaterialTheme.colorScheme.onSurfaceVariant,
                        title = "Version",
                        value = uiState.appVersion
                    )

                    SettingsDivider()

                    SettingsRowWithIcon(
                        icon = Icons.Default.Description,
                        iconBackgroundColor = Color(0xFFF1F3FF),
                        iconTint = MaterialTheme.colorScheme.onSurfaceVariant,
                        title = "Privacy Policy",
                        onClick = onNavigateToPrivacyPolicy
                    )

                    SettingsDivider()

                    SettingsRowWithIcon(
                        icon = Icons.Default.Policy,
                        iconBackgroundColor = Color(0xFFF1F3FF),
                        iconTint = MaterialTheme.colorScheme.onSurfaceVariant,
                        title = "Terms of Service",
                        onClick = onNavigateToTerms
                    )

                    SettingsDivider()

                    SettingsRowWithIcon(
                        icon = Icons.AutoMirrored.Filled.Chat,
                        iconBackgroundColor = Color(0xFFF1F3FF),
                        iconTint = MaterialTheme.colorScheme.onSurfaceVariant,
                        title = "Contact Support",
                        onClick = onNavigateToContact
                    )

                    SettingsDivider()

                    SettingsRowWithIcon(
                        icon = Icons.Default.Star,
                        iconBackgroundColor = Color(0xFFF1F3FF),
                        iconTint = MaterialTheme.colorScheme.onSurfaceVariant,
                        title = "Rate the App",
                        onClick = onNavigateToRate
                    )
                }
            }
        }

        // Sign Out
        item {
            Box(
                modifier = Modifier.fillMaxWidth(),
                contentAlignment = Alignment.Center
            ) {
                TextButton(onClick = { viewModel.signOut() }) {
                    Text(
                        text = "Sign Out",
                        color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp
                    )
                }
            }
        }

        item { Spacer(modifier = Modifier.height(80.dp)) }
    }
}

@Composable
private fun SettingsSection(
    title: String,
    content: @Composable () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            text = title.uppercase(),
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.Bold,
            letterSpacing = 2.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
            modifier = Modifier.padding(horizontal = 8.dp)
        )
        content()
    }
}

@Composable
private fun SettingsCard(
    content: @Composable () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(28.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Column {
            content()
        }
    }
}

@Composable
private fun AccountCard(
    email: String,
    isPremium: Boolean,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(28.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Avatar
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(RoundedCornerShape(16.dp))
                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(28.dp)
                )
            }

            Spacer(modifier = Modifier.width(16.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = email,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    if (isPremium) {
                        Icon(
                            imageVector = Icons.Default.Star,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(14.dp)
                        )
                        Text(
                            text = "Premium Plan",
                            color = MaterialTheme.colorScheme.primary,
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp
                        )
                    }
                }
            }

            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.outline
            )
        }
    }
}

@Composable
private fun SettingsRowWithIcon(
    icon: ImageVector,
    iconBackgroundColor: Color,
    iconTint: Color,
    title: String,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        color = Color.Transparent
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconBox(icon = icon, backgroundColor = iconBackgroundColor, tint = iconTint)
            Spacer(modifier = Modifier.width(16.dp))
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.weight(1f)
            )
            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.outline
            )
        }
    }
}

@Composable
private fun SettingsRowWithSubtitle(
    icon: ImageVector,
    iconBackgroundColor: Color,
    iconTint: Color,
    title: String,
    subtitle: String,
    trailing: @Composable () -> Unit,
    onClick: () -> Unit = {}
) {
    Surface(
        onClick = onClick,
        color = Color.Transparent
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconBox(icon = icon, backgroundColor = iconBackgroundColor, tint = iconTint)
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            trailing()
        }
    }
}

@Composable
private fun SettingsRowWithValue(
    icon: ImageVector,
    iconBackgroundColor: Color,
    iconTint: Color,
    title: String,
    value: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(20.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconBox(icon = icon, backgroundColor = iconBackgroundColor, tint = iconTint)
        Spacer(modifier = Modifier.width(16.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.weight(1f)
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun SettingsToggleRow(
    icon: ImageVector,
    iconBackgroundColor: Color,
    iconTint: Color,
    title: String,
    isEnabled: Boolean,
    onToggle: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(20.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconBox(icon = icon, backgroundColor = iconBackgroundColor, tint = iconTint)
        Spacer(modifier = Modifier.width(16.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.weight(1f)
        )
        Switch(
            checked = isEnabled,
            onCheckedChange = onToggle,
            colors = SwitchDefaults.colors(
                checkedTrackColor = MaterialTheme.colorScheme.primary,
                uncheckedTrackColor = Color(0xFFDCE2F7)
            )
        )
    }
}

@Composable
private fun SettingsToggleRowWithSubtitle(
    icon: ImageVector,
    iconBackgroundColor: Color,
    iconTint: Color,
    title: String,
    subtitle: String,
    isEnabled: Boolean,
    onToggle: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(20.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconBox(icon = icon, backgroundColor = iconBackgroundColor, tint = iconTint)
        Spacer(modifier = Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Switch(
            checked = isEnabled,
            onCheckedChange = onToggle,
            colors = SwitchDefaults.colors(
                checkedTrackColor = MaterialTheme.colorScheme.primary,
                uncheckedTrackColor = Color(0xFFDCE2F7)
            )
        )
    }
}

@Composable
private fun IconBox(
    icon: ImageVector,
    backgroundColor: Color,
    tint: Color,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .size(40.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(backgroundColor),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = tint,
            modifier = Modifier.size(20.dp)
        )
    }
}

@Composable
private fun SettingsDivider() {
    HorizontalDivider(
        modifier = Modifier.padding(start = 76.dp),
        color = Color(0xFFF1F3FF)
    )
}
