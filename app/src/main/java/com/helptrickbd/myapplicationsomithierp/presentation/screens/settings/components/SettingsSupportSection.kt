package com.helptrickbd.myapplicationsomithierp.presentation.screens.settings.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.HelpOutline
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.PrivacyTip
import androidx.compose.material.icons.filled.SystemUpdate
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun SettingsSupportSection(
    appVersion: String = "1.0.0",
    onCheckUpdates: () -> Unit,
    onContactSupport: () -> Unit,
    onPrivacyPolicy: () -> Unit,
    onTerms: () -> Unit,
    onSignOut: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = if (isBangla) "সহায়তা ও তথ্য" else "Support & About",
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(horizontal = 4.dp)
        )

        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
            elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
        ) {
            Column {
                SettingsClickableRow(
                    icon = Icons.Default.SystemUpdate,
                    title = if (isBangla) "অ্যাপের আপডেট চেক" else "Check for Updates",
                    subtitle = if (isBangla) "বর্তমান সংস্করণ $appVersion" else "Version $appVersion",
                    onClick = onCheckUpdates
                )

                HorizontalDivider(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    thickness = 0.5.dp,
                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                )

                SettingsClickableRow(
                    icon = Icons.AutoMirrored.Filled.HelpOutline,
                    title = if (isBangla) "সহায়তা ও যোগাযোগ" else "Help & Support",
                    subtitle = if (isBangla) "সমস্যা বা ফান্ডের পরামর্শের জন্য যোগাযোগ" else "Contact fund administrators for support",
                    onClick = onContactSupport
                )

                HorizontalDivider(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    thickness = 0.5.dp,
                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                )

                SettingsClickableRow(
                    icon = Icons.Default.PrivacyTip,
                    title = if (isBangla) "গোপনীয়তা নীতি" else "Privacy Policy",
                    subtitle = if (isBangla) "তথ্য নিরাপত্তা ও সুরক্ষা নীতিমালা" else "How your personal and financial data is protected",
                    onClick = onPrivacyPolicy
                )

                HorizontalDivider(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    thickness = 0.5.dp,
                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                )

                SettingsClickableRow(
                    icon = Icons.Default.Info,
                    title = if (isBangla) "ব্যবহারের শর্তাবলী" else "Terms of Service",
                    subtitle = if (isBangla) "সমিতি ও ফান্ডের বিধিবিধান" else "Fund policies and membership terms",
                    onClick = onTerms
                )
            }
        }

        Spacer(modifier = Modifier.height(6.dp))

        // Sign Out Button
        Button(
            onClick = onSignOut,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(14.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.errorContainer,
                contentColor = MaterialTheme.colorScheme.onErrorContainer
            )
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.Logout,
                contentDescription = null,
                modifier = Modifier.size(18.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = if (isBangla) "লগআউট করুন" else "Sign Out",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Bold
            )
        }
    }
}
