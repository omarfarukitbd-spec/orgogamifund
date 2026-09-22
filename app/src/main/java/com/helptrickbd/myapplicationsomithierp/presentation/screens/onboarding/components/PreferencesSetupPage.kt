package com.helptrickbd.myapplicationsomithierp.presentation.screens.onboarding.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BrightnessMedium
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.PhoneAndroid
import androidx.compose.material.icons.filled.Translate
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.helptrickbd.myapplicationsomithierp.R
import com.helptrickbd.myapplicationsomithierp.core.datastore.AppThemeMode

@Composable
fun PreferencesSetupPage(
    currentLanguage: String,
    currentThemeMode: AppThemeMode,
    onLanguageSelect: (String) -> Unit,
    onThemeModeSelect: (AppThemeMode) -> Unit,
    modifier: Modifier = Modifier
) {
    val isBangla = currentLanguage == "bn"

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Hero Concentric Circular Icon
        Box(
            modifier = Modifier
                .size(92.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.primaryContainer),
            contentAlignment = Alignment.Center
        ) {
            Box(
                modifier = Modifier
                    .size(64.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Filled.Palette,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onPrimary,
                    modifier = Modifier.size(34.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // Headline
        Text(
            text = if (isBangla) "ভাষা ও থিম নির্বাচন" else "Language & Theme Setup",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onBackground,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(6.dp))

        Text(
            text = if (isBangla) {
                "অ্যাপ ব্যবহারের সুবিধার্থে আপনার পছন্দ নির্বাচন করুন"
            } else {
                "Customize your preferred language and display theme"
            },
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 8.dp)
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Section 1: Language
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 8.dp, start = 2.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.Translate,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(18.dp)
            )
            Text(
                text = if (isBangla) "অ্যাপের ভাষা (Language):" else "App Language:",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onBackground
            )
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            ModernSelectionCard(
                title = "বাংলা",
                subtitle = if (isBangla) "ডিফল্ট" else "Default",
                icon = null,
                isSelected = currentLanguage == "bn",
                modifier = Modifier.weight(1f),
                onClick = { onLanguageSelect("bn") }
            )
            ModernSelectionCard(
                title = "English",
                subtitle = if (isBangla) "আন্তর্জাতিক" else "International",
                icon = null,
                isSelected = currentLanguage == "en",
                modifier = Modifier.weight(1f),
                onClick = { onLanguageSelect("en") }
            )
        }

        Spacer(modifier = Modifier.height(20.dp))

        // Section 2: Theme
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 8.dp, start = 2.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.BrightnessMedium,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(18.dp)
            )
            Text(
                text = if (isBangla) "ডিসপ্লে থিম (Theme):" else "Display Theme:",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onBackground
            )
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            ModernSelectionCard(
                title = if (isBangla) "সিস্টেম" else "System",
                subtitle = if (isBangla) "ডিফল্ট" else "Default",
                icon = Icons.Filled.PhoneAndroid,
                isSelected = currentThemeMode == AppThemeMode.SYSTEM,
                modifier = Modifier.weight(1f),
                onClick = { onThemeModeSelect(AppThemeMode.SYSTEM) }
            )
            ModernSelectionCard(
                title = if (isBangla) "লাইট" else "Light",
                subtitle = if (isBangla) "উজ্জ্বল" else "Light Mode",
                icon = Icons.Filled.LightMode,
                isSelected = currentThemeMode == AppThemeMode.LIGHT,
                modifier = Modifier.weight(1f),
                onClick = { onThemeModeSelect(AppThemeMode.LIGHT) }
            )
            ModernSelectionCard(
                title = if (isBangla) "ডার্ক" else "Dark",
                subtitle = if (isBangla) "ডার্ক মোড" else "Dark Mode",
                icon = Icons.Filled.DarkMode,
                isSelected = currentThemeMode == AppThemeMode.DARK,
                modifier = Modifier.weight(1f),
                onClick = { onThemeModeSelect(AppThemeMode.DARK) }
            )
        }

        Spacer(modifier = Modifier.height(20.dp))

        Text(
            text = stringResource(R.string.lang_settings_hint),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.outline,
            textAlign = TextAlign.Center
        )
    }
}
