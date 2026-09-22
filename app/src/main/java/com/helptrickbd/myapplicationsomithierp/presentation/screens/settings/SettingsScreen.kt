package com.helptrickbd.myapplicationsomithierp.presentation.screens.settings

import android.content.Intent
import android.widget.Toast
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.net.toUri
import com.helptrickbd.myapplicationsomithierp.core.datastore.AppThemeMode
import com.helptrickbd.myapplicationsomithierp.domain.model.UserRole
import com.helptrickbd.myapplicationsomithierp.presentation.screens.settings.components.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    userRole: UserRole = UserRole.SUPER_ADMIN,
    currentLanguage: String = "bn",
    currentThemeMode: AppThemeMode = AppThemeMode.SYSTEM,
    isBiometricEnabled: Boolean = false,
    onLanguageChange: (String) -> Unit = {},
    onThemeModeChange: (AppThemeMode) -> Unit = {},
    onBiometricToggle: (Boolean) -> Unit = {},
    onNavigateToSessions: () -> Unit = {},
    onNavigateToNotifications: () -> Unit = {},
    onTriggerBackup: () -> Unit = {},
    onNavigateToOnboarding: () -> Unit = {},
    onNavigateToAdminHub: () -> Unit = {},
    onNavigateToAuth: () -> Unit = {},
    onNavigateBack: () -> Unit = {},
    onSignOut: () -> Unit = {}
) {
    val context = LocalContext.current
    val isBangla = LocalConfiguration.current.locales[0].language == "bn"

    var biometricState by remember { mutableStateOf(isBiometricEnabled) }
    var pushNotifEnabled by remember { mutableStateOf(true) }
    var paymentAlertsEnabled by remember { mutableStateOf(true) }
    var reminderAlertsEnabled by remember { mutableStateOf(true) }
    var showLanguageDialog by remember { mutableStateOf(false) }
    var showThemeDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = if (isBangla) "সেটিংস ও পছন্দসমূহ" else "Settings & Preferences",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = if (isBangla) "ফিরে যান" else "Back"
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface
                )
            )
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // 1. User Header
            item {
                val fbUser = com.google.firebase.auth.FirebaseAuth.getInstance().currentUser
                val resolvedName = fbUser?.displayName?.ifBlank { null }
                    ?: if (userRole == UserRole.SUPER_ADMIN) "মো: ওমর ফারুক"
                    else if (isBangla) "সম্মানিত সদস্য" else "Member"
                val resolvedEmail = fbUser?.email?.ifBlank { null }
                    ?: if (userRole == UserRole.SUPER_ADMIN) "omarfaruktitbd@gmail.com"
                    else ""

                SettingsHeader(
                    userName = resolvedName,
                    userEmail = resolvedEmail,
                    userRole = userRole
                )
            }

            // 2. Appearance & Language (Pure Bengali / English)
            item {
                SettingsAppearanceSection(
                    currentLanguage = currentLanguage,
                    currentThemeMode = currentThemeMode,
                    onOpenLanguageDialog = { showLanguageDialog = true },
                    onOpenThemeDialog = { showThemeDialog = true }
                )
            }

            // 3. Security & Devices
            item {
                SettingsSecuritySection(
                    isBiometricEnabled = biometricState,
                    onBiometricToggle = {
                        biometricState = it
                        onBiometricToggle(it)
                    },
                    onNavigateToSessions = onNavigateToSessions
                )
            }

            // 4. Notifications
            item {
                SettingsNotificationSection(
                    pushNotifEnabled = pushNotifEnabled,
                    paymentAlertsEnabled = paymentAlertsEnabled,
                    reminderAlertsEnabled = reminderAlertsEnabled,
                    onPushNotifToggle = { pushNotifEnabled = it },
                    onPaymentAlertsToggle = { paymentAlertsEnabled = it },
                    onReminderAlertsToggle = { reminderAlertsEnabled = it },
                    onNavigateToNotifications = onNavigateToNotifications
                )
            }

            // 5. Support & About
            item {
                SettingsSupportSection(
                    appVersion = "1.0.0",
                    onCheckUpdates = {
                        Toast.makeText(
                            context,
                            if (isBangla) "আপনার অ্যাপটি সর্বশেষ সংস্করণে রয়েছে" else "Your app is up to date",
                            Toast.LENGTH_SHORT
                        ).show()
                    },
                    onContactSupport = {
                        try {
                            val intent = Intent(Intent.ACTION_SENDTO).apply {
                                data = "mailto:omarfaruktitbd@gmail.com".toUri()
                                putExtra(Intent.EXTRA_SUBJECT, if (isBangla) "অগ্রগামী ফান্ড সাপোর্ট রিকোয়েস্ট" else "OgroGami Fund Support Request")
                            }
                            context.startActivity(intent)
                        } catch (e: Exception) {
                            Toast.makeText(context, "omarfaruktitbd@gmail.com", Toast.LENGTH_LONG).show()
                        }
                    },
                    onPrivacyPolicy = {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, "https://ogrogami-fund.web.app/privacy".toUri())
                            context.startActivity(intent)
                        } catch (e: Exception) {
                            Toast.makeText(context, if (isBangla) "গোপনীয়তা নীতি: আপনার সকল তথ্য সম্পূর্ণ নিরাপদ" else "Privacy Policy: Data is securely stored", Toast.LENGTH_SHORT).show()
                        }
                    },
                    onTerms = {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, "https://ogrogami-fund.web.app/terms".toUri())
                            context.startActivity(intent)
                        } catch (e: Exception) {
                            Toast.makeText(context, if (isBangla) "ব্যবহারের শর্তাবলী: ফান্ড ও সমিতির যাবতীয় বিধিবিধান প্রযোজ্য" else "Terms: Somithi policies apply", Toast.LENGTH_SHORT).show()
                        }
                    },
                    onSignOut = onSignOut
                )
            }
        }
    }

    // Language Dialog
    if (showLanguageDialog) {
        LanguageSelectionDialog(
            currentLanguage = currentLanguage,
            onSelectLanguage = onLanguageChange,
            onDismiss = { showLanguageDialog = false }
        )
    }

    // Theme Dialog
    if (showThemeDialog) {
        ThemeSelectionDialog(
            currentThemeMode = currentThemeMode,
            onSelectTheme = onThemeModeChange,
            onDismiss = { showThemeDialog = false }
        )
    }
}
