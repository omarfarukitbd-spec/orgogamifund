package com.helptrickbd.myapplicationsomithierp.presentation.screens.settings.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.core.datastore.AppThemeMode

@Composable
fun LanguageSelectionDialog(
    currentLanguage: String,
    onSelectLanguage: (String) -> Unit,
    onDismiss: () -> Unit
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = if (isBangla) "অ্যাপের ভাষা নির্বাচন করুন" else "Select App Language",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                LanguageOptionRow(
                    label = "বাংলা",
                    subtitle = "Bangla",
                    selected = currentLanguage == "bn",
                    onSelect = { onSelectLanguage("bn"); onDismiss() }
                )
                LanguageOptionRow(
                    label = "English",
                    subtitle = "ইংরেজি",
                    selected = currentLanguage == "en",
                    onSelect = { onSelectLanguage("en"); onDismiss() }
                )
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(if (isBangla) "বাতিল" else "Cancel")
            }
        }
    )
}

@Composable
private fun LanguageOptionRow(
    label: String,
    subtitle: String,
    selected: Boolean,
    onSelect: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onSelect() }
            .padding(vertical = 8.dp, horizontal = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            Text(
                text = label,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        RadioButton(
            selected = selected,
            onClick = onSelect
        )
    }
}

@Composable
fun ThemeSelectionDialog(
    currentThemeMode: AppThemeMode,
    onSelectTheme: (AppThemeMode) -> Unit,
    onDismiss: () -> Unit
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = if (isBangla) "থিম নির্বাচন করুন" else "Select Theme Mode",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                ThemeOptionRow(
                    label = if (isBangla) "সিস্টেম ডিফল্ট" else "System Default",
                    selected = currentThemeMode == AppThemeMode.SYSTEM,
                    onSelect = { onSelectTheme(AppThemeMode.SYSTEM); onDismiss() }
                )
                ThemeOptionRow(
                    label = if (isBangla) "লাইট মোড" else "Light Mode",
                    selected = currentThemeMode == AppThemeMode.LIGHT,
                    onSelect = { onSelectTheme(AppThemeMode.LIGHT); onDismiss() }
                )
                ThemeOptionRow(
                    label = if (isBangla) "ডার্ক মোড" else "Dark Mode",
                    selected = currentThemeMode == AppThemeMode.DARK,
                    onSelect = { onSelectTheme(AppThemeMode.DARK); onDismiss() }
                )
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(if (isBangla) "বাতিল" else "Cancel")
            }
        }
    )
}

@Composable
private fun ThemeOptionRow(
    label: String,
    selected: Boolean,
    onSelect: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onSelect() }
            .padding(vertical = 8.dp, horizontal = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
            color = MaterialTheme.colorScheme.onSurface
        )
        RadioButton(
            selected = selected,
            onClick = onSelect
        )
    }
}
